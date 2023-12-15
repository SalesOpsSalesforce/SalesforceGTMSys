//[RGaokar 06/27/2023 SFDC-2895 Failed Real time sync transactions retry batch job]
//The Real time sync send the failed transactions (failed & never retried or retries exhausted)
//This job syncs the transaction information to Opportunity
public class TransactionSyncBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'Select id,Transaction_Id__c,Opportunity_Name__c,Account__c,Amount__c,Plan_Limit__c,Product__c,Transaction_Date__c,'; 
        query += ' Customer_Cancellation_Reason__c,Cancellation_Sub_Reason__c,Cancelled_Notes__c,Cancellation_Zendesk_Ticket_URL__c';
        query += ' from Transaction__c where Opportunity__c = null AND Failed_Transaction__c = false';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        List<Opportunity> oppList = new List<Opportunity>();
        List<Transaction__c>trList = (List<Transaction__c>)scope;
        List<Transaction__c>trUpdateList = new List<Transaction__c>();
        for(Transaction__c tr: trList){
            Opportunity o = new Opportunity(Name = tr.Opportunity_Name__c, PRODUCT_Klaviyo_Transaction_Id__c = tr.Transaction_Id__c,
                                            AccountId = tr.Account__c, PRODUCT_Opportunity_Product__c = tr.Product__c,
                                            Integration_Usage_Limit__c = tr.Plan_Limit__c, Amount = tr.Amount__c,
                                            CloseDate = tr.Transaction_Date__c, SALES_Reported_Cancellation_Reason__c = tr.Customer_Cancellation_Reason__c,
                                            Cancellation_Sub_Reason__c = tr.Cancellation_Sub_Reason__c, SALES_Cancelled_Notes__c = tr.Cancelled_Notes__c,
                                            Cancellation_Zendesk_URL__c = tr.Cancellation_Zendesk_Ticket_URL__c, StageName = 'Closed Won - Needs Review');
            oppList.add(o);
        }
        
        if(!oppList.isEmpty()){
            string errorString = '';
            List<Database.UpsertResult> upsrList = Database.upsert(oppList, Opportunity.PRODUCT_Klaviyo_Transaction_Id__c, false);
            
            //Populate the opportunity id on transcations for success & handle failures
            for(Database.UpsertResult sr:upsrList){
                Id trancId = trList[upsrList.indexOf(sr)].id;
                if(sr.isSuccess()){
                    trUpdateList.add(new Transaction__c(Id = trancId, Opportunity__c = sr.getId()));  
                }else{
                    string trancError = '';
                    trancError += 'Transaction Id: '+trancId+' , Opportunity Id: '+sr.getId()+'\n';
                    for(Database.Error err: sr.getErrors()){
                        trancError += ' Error Message: ' +err.getMessage()+'\n';
                    }
                    trUpdateList.add(new Transaction__c(Id = trancId, Error_Message__c = trancError, Failed_Transaction__c = true));
                    errorString += trancError;//Error notification through email, keeping it off for now to avoid error emails as errors are available on Transaction record itself.
                }
            }
            
            //Update the successfully synced & failed transactions
            if(!trUpdateList.isEmpty()){
                List<Database.SaveResult> srList = Database.update(trUpdateList, false);
                for(Database.SaveResult sr: srList){
                    if(!sr.isSuccess()){
                        errorString += 'Transaction Id: '+sr.getId()+'\n';
                        for(Database.Error err: sr.getErrors()){
                            errorString += ' Error Message: ' +err.getMessage()+'\n';
                        }  
                    } 
                }
            }
            
            if(String.isNotBlank(errorString) || Test.isRunningTest()){
                List<string>errorList = new List<string>();
                errorList.add('Errors occured during Transaction Update: ');
                errorList.add(errorString);
                //ExceptionHandling.performExceptionHandling(null, 'TransactionSyncBatch', errorList);//Commenting this to avoid too many emails
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
}
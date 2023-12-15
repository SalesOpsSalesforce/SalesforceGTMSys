//[RGaokar 04/28/2023 SFDC-2516 This batch roll ups the child Partner Payouts to Parther Aggregate Payouts]
//[RGaokar 09/05/2023 SFDC-3349 Email notification after completion]
public class PartnerAggregateAmountCalculationBatch implements Database.Batchable<sObject>{
    private set<id>aggregatePayoutIds = new set<id>();
    public PartnerAggregateAmountCalculationBatch(set<id>aggregatePayoutIds){
        this.aggregatePayoutIds = aggregatePayoutIds;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'Select id from Partner_Aggregate_Payout__c where id in :aggregatePayoutIds'; 
        return database.getQueryLocator(query);  
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        set<id>aggregatePayouts = new set<id>();
        list<Partner_Aggregate_Payout__c> updateAggPayouts = new list<Partner_Aggregate_Payout__c>();
        for(Partner_Aggregate_Payout__c aggPayout : (List<Partner_Aggregate_Payout__c>)scope){
            aggregatePayouts.add(aggPayout.id);
        }
        
        List<AggregateResult> payoutRollups = [Select Partner_Aggregate_Payout__c aggPayout, sum(Payout_Amount__c)totalPayout from Partner_Payout__c 
                                               where Partner_Aggregate_Payout__c in :aggregatePayouts Group By Partner_Aggregate_Payout__c];
        
        for(AggregateResult ar: payoutRollups){
            updateAggPayouts.add(new Partner_Aggregate_Payout__c(Id = (id)ar.get('aggPayout'), Aggregate_Payout_Amount__c = (decimal)ar.get('totalPayout')));
        }
        
        if(!updateAggPayouts.isEmpty()){
            String errorString = '';
            List<Database.SaveResult> srList = Database.update(updateAggPayouts, false);
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    errorString += 'Following error occured during Partner Aggregate Payout Roll Up Calculation';
                    for(Database.Error err :result.getErrors()){
                        errorString += '\n' + 'Partner Aggregate Payout: ' +result.getId() + ' Error Message: '+err.getMessage();
                    }
                }
            }
            
            if(String.isNotBlank(errorString) || Test.isRunningTest()){
                List<string>errorList = new List<string>();
                errorList.add(errorString);
                ExceptionHandling.performExceptionHandling(null, 'PartnerAggregateAmountCalculationBatch', errorList);
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        //Send Emails to partnership ops once calculation is completed
        Messaging.SingleEmailMessage sEmail = new Messaging.SingleEmailMessage();
        List<String> toAddresses = System.Label.Partner_Aggregate_Payout_Calculation_Notification_Emails.split(',');
        sEmail.setToAddresses(toAddresses);
        sEmail.setSubject('Partner Aggregate Payout Caculation Notification');
        string msg = 'Hello Partner Ops Team!' + '\n'+ '\n' + 'Partner aggregate payout calculation has been completed. Please check the partner aggregate payout report for details.' + '\n'+ '\n';
        msg += 'Thanks'+'\n'+'GTM Systems';
        sEmail.setPlainTextBody(msg);
        
        if(!Test.isRunningTest())Messaging.sendEmail(new Messaging.SingleEmailMessage[]{sEmail});  
    } 
}
//[RGaokar 06/05/2022 SFDC-2809 Payout creation for a partner split created during End of Month process]
public class PartnerAggregatePayoutEOMBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start (Database.BatchableContext bc){
        //Get last month EOM partner splits
        String query = 'Select id,Customer_Account__c,Partner_Account__c,Product_Family__c,Eligible_for_Managed_Payout__c,Eligible_for_Platform_Payout__c,';
        query += 'Payout__c,Payout_Start_date__c,Payout_End_Date__c,EOM_Partner_Split__c from Partner_Split__c';
        query += ' where EOM_Partner_Split__c = true AND Payout__c = true AND Opportunity__r.closedate = Last_Month';
        return database.getQueryLocator(query); 
    }
    
    public void execute(database.BatchableContext bc, List<sObject>scope){
        map<id, List<Partner_Split__c>> customerPSMap = new map<id, List<Partner_Split__c>>();
        Map<id,Partner_Split__c>idPSMap = new Map<id,Partner_Split__c>();
        Map<id,List<Partner_Payout__c>>psPayMap = new Map<id,List<Partner_Payout__c>>();
        map<id, List<Klaviyo_Payment__c>> customerPaymentMap = new map<id, List<Klaviyo_Payment__c>>();
        List<Partner_Payout__c> payoutList = new List<Partner_Payout__c>();//New payouts to create
        string errorString = '';
        
        //Get customer ids & partner split ids
        for(Partner_Split__c ps:(List<Partner_Split__c>)scope){        
            if(!customerPSMap.containsKey(ps.Customer_Account__c)){
                customerPSMap.put(ps.Customer_Account__c, new List<Partner_Split__c>());
            }
            customerPSMap.get(ps.Customer_Account__c).add(ps);
            idPSMap.put(ps.Id, ps);
        }
        
        //Get last month's successful payments associated with customer
        Map<id, Klaviyo_Payment__c> paymentMap = new Map<id, Klaviyo_Payment__c>([Select id, Account__c, Product_Category__c,Payment_Date__c from Klaviyo_Payment__c
                                                                                  where Account__c in :customerPSMap.keyset()
                                                                                  AND Payment_Date__c = Last_Month 
                                                                                  AND Product_Category__c != null AND Status__c = 'Succeeded']);
        
        //Get last month's existing payout related to retrieved payment & partner split
        List<Partner_Payout__c> payoutRelatedtoPayments = [Select id,Payment_Date__c,Klaviyo_Payment__c,Partner_Split__c from Partner_Payout__c 
                                                           where Klaviyo_Payment__c in : paymentMap.keySet() AND Partner_Split__c in :idPSMap.keyset()
                                                           AND Payment_Date__c = Last_Month];
        
        
        for(Partner_Payout__c pay: payoutRelatedtoPayments){
            if(!psPayMap.containsKey(pay.Partner_Split__c)){
                psPayMap.put(pay.Partner_Split__c, new List<Partner_Payout__c>());
            }
            psPayMap.get(pay.Partner_Split__c).add(pay);  
        }
        
        //Remove the partner splits from EOM re-calculation if the the payout already exists for some payments
        //Remove ps if there is an payout associated with ps, 
        //assuming that there is no multiple stripe payments comes for same product for same account
        //and Manual payment comes only once on 1BD
        //so either there will be payouts associated with PS or no payout at all for that PS for last month
        if(!psPayMap.isEmpty()){//If payout are retrieved for PS 
            for(id customer:customerPSMap.keyset()){
                for(Partner_Split__c ps:customerPSMap.get(customer)){//Iterate through each ps related to customer
                    if(psPayMap.containsKey(ps.id)){//if payout exsists
                        idPSMap.remove(ps.id);
                    }
                } 
            }
        }
        
        if(!paymentMap.isEmpty()){
            for(id paymentId: paymentMap.keyset()){
                Klaviyo_Payment__c payment = paymentMap.get(paymentId);
                if(!customerPaymentMap.containsKey(payment.Account__c)){
                    customerPaymentMap.put(payment.Account__c,new List<Klaviyo_Payment__c>());
                }
                customerPaymentMap.get(payment.Account__c).add(payment);
            }
        }
        
        //If payment exists create a payout for eligible PS
        for(id psId:idPSMap.keyset()){
            Partner_Split__c ps = idPSMap.get(psId);
            if(!customerPaymentMap.isEmpty() && customerPaymentMap.containsKey(ps.Customer_Account__c)){
                for(Klaviyo_Payment__c payment: customerPaymentMap.get(ps.Customer_Account__c)){
                    Boolean eligibleforPayout = ps.Eligible_for_Managed_Payout__c || ps.Eligible_for_Platform_Payout__c || (ps.Payout__c && ps.Payout_Start_date__c <= payment.Payment_Date__c && ps.Payout_End_Date__c >= payment.Payment_Date__c);
                    if(ps.Product_Family__c == payment.Product_Category__c && eligibleforPayout){
                        Partner_Payout__c pay = new Partner_Payout__c(Klaviyo_Payment__c = payment.Id, Customer_Account__c = ps.Customer_Account__c,
                                                                      Partner_Split__c = ps.id, Partner_Account__c = ps.Partner_Account__c);
                        payoutList.add(pay);
                    }
                }
            }
        }
        
        //system.debug('payoutList--'+payoutList.size());
        
        //Create payouts
        if(!payoutList.isEmpty()){
            List<Database.SaveResult> srList = Database.insert(payoutList, false);
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    errorString += '\n' + 'The following error occurred during EOM Partner Payout record creation';
                    for(Database.Error err: result.getErrors()){
                        errorString += ' Error Message: ' +err.getMessage()+'\n';
                    }
                } 
            } 
        }
        
        if(String.isNotBlank(errorString) || Test.isRunningTest()){
            List<string>errorList = new List<string>();
            errorList.add('Errors occured during EOM Partner Payouts Creation: ');
            errorList.add(errorString);
            ExceptionHandling.performExceptionHandling(null, 'PartnerAggregatePayoutEOMBatch', errorList);  
        }
    }
    
    public void finish(database.BatchableContext bc){
        PartnerAggregatePayoutBatch aggPayoutBatch = new PartnerAggregatePayoutBatch();
        Database.executeBatch(aggPayoutBatch);
    }   
}
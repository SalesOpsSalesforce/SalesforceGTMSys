public class KPUAggregatedEcommPlatformUpdateBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String Query = 'Select id, Klaviyo_Product_Usage__r.bi_Aggregated_Ecommerce_Platform__c from Account'; 
        Query += ' where Klaviyo_Product_Usage__c != null AND KPU_Aggregated_Ecommerce_Platform__c = null AND Klaviyo_Product_Usage__r.bi_Aggregated_Ecommerce_Platform__c != null';
        return Database.getQueryLocator(Query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        List<Account> updateAccList = new List<Account>();
        for (Account a:(List<Account>)scope){
            a.KPU_Aggregated_Ecommerce_Platform__c = a.Klaviyo_Product_Usage__r.bi_Aggregated_Ecommerce_Platform__c;
            updateAccList.add(a);
        }
        
        try{
            if(updateAccList.size()>0){
                update updateAccList;
            }     
        }catch(Exception ex){
            List <String> executionFlow = new List <String> ();
            executionFlow.add('Error occured for KPUAggregatedEcommPlatformUpdateBatch Update');
            ExceptionHandling.performExceptionHandling(ex, 'KPUAggregatedEcommPlatformUpdateBatch', executionFlow);  
        }
   
    }
    
    public void finish(Database.BatchableContext bc){
        
    }

}
//[RGaokar 11/10/2023 SFDC-3629 Error recovery of BI Enrichment failures]
public class BIEnrichmentErrorRecoveryScheduler implements system.schedulable{
    public void execute(system.SchedulableContext sc){
        manualRun();
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    // Failed Account Retry
    public static void manualRun(){
        //Get processing types
        string biFailedProcessingType = '';
        List<string> biFailedProcessingTypeList = new List<string>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get('BI_Enrichment_Sync__mdt') ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get('BI_Processing_Type__c').getDescribe();
        List<Schema.PicklistEntry> processingTypeList = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry processingType : processingTypeList){
            biFailedProcessingTypeList.add('Failed - ' + processingType.getValue());
        } 
        biFailedProcessingType = String.join(biFailedProcessingTypeList,',');
        
        //Call account error recovery
        BIEnrichmentAccountErrorRecoveryBatch BIEnrichmentBatch = new BIEnrichmentAccountErrorRecoveryBatch(null,biFailedProcessingType);
        Database.executeBatch(BIEnrichmentBatch, 100);
    }   
}
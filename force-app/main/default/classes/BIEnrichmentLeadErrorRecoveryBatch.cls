//[RGaokar 11/10/2023 SFDC-3629 Error recovery of BI Enrichment failures - Lead]
////Sync BI enrichment failed record or record for which one of the enrichment failed so never sync for BI enrichment, 
//such records needs to be retry on same day of creation
//[RGaokar 11/27/2023 SFDC-4217 Extend createddate filter to consider all missing leads for segmentation]
//Batch can be called from anonymous window as follows:
//string query = 'Select name,id, BI_Enrichment_Sync_Status__c,Segmentation_Sync_Ready__c,Customer_Group__c from Lead where CreatedDate >= 2023-11-17T00:00:00Z AND CreatedDate < Today AND (BI_Enrichment_Sync_Status__c includes (\'Failed - segment\') OR (Segmentation_Sync_Ready__c = true AND Customer_Group__c = null))';
//BIEnrichmentLeadErrorRecoveryBatch BIEnrichmentBatch = new BIEnrichmentLeadErrorRecoveryBatch(query, 'Failed - segment');
//Database.executeBatch(BIEnrichmentBatch, 50);
public class BIEnrichmentLeadErrorRecoveryBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    string query;
    string biProcessingType;
    
    public BIEnrichmentLeadErrorRecoveryBatch(string query,string biProcessingType){
        this.query = query;
        this.biProcessingType = biProcessingType;
    }
    
    public Database.QueryLocator start (Database.BatchableContext bc){
        if(query == null){
            query = 'Select name,id, BI_Enrichment_Sync_Status__c,Segmentation_Sync_Ready__c,Customer_Group__c from Lead where CreatedDate >= 2023-11-17T00:00:00Z AND';
            if(biProcessingType.containsIgnorecase('segment')){
                query += ' (BI_Enrichment_Sync_Status__c includes (:biProcessingType) OR (Segmentation_Sync_Ready__c = true AND Customer_Group__c = null))';
            }else{
                query += ' BI_Enrichment_Sync_Status__c includes (:biProcessingType)';
            }
        }
        return Database.getQueryLocator(query); 
        
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        map<string,List<BIEnrichmentProcessor.recordWrapper>> processingTypeLeadMap = new map<string,List<BIEnrichmentProcessor.recordWrapper>>();
        
        for(Lead l:(List<Lead>)scope){
            //Records failed BI enrichment or records never send for BI Segmentation due to one of the enrichment faliure
            if(l.BI_Enrichment_Sync_Status__c != null){
                List<string> leadProcessingTypes = l.BI_Enrichment_Sync_Status__c.split(';');
                if(!leadProcessingTypes.contains('Failed - segment') && !leadProcessingTypes.contains('Success - segment') && 
                   l.Segmentation_Sync_Ready__c == true && l.Customer_Group__c == null){
                    leadProcessingTypes.add('Failed - segment');
                }

                for(string leadProcessingType:leadProcessingTypes){
                    string processingType = leadProcessingType.substringAfter('- ');
                    if(!processingTypeLeadMap.containsKey(processingType)){
                        processingTypeLeadMap.put(processingType,new List<BIEnrichmentProcessor.recordWrapper>());
                    }
                    BIEnrichmentProcessor.recordWrapper record = new BIEnrichmentProcessor.recordWrapper();
                    record.recordId = l.Id;
                    record.processingType = processingType;
                    processingTypeLeadMap.get(processingType).add(record);
                }
            }
            
            //Records never send for BI Segmentation due to one of the enrichment faliure, so no status for success/failed segment available on record
            else if(l.BI_Enrichment_Sync_Status__c == null && l.Segmentation_Sync_Ready__c == true && l.Customer_Group__c == null){
                   string processingType = 'segment';
                   if(!processingTypeLeadMap.containsKey(processingType)){
                       processingTypeLeadMap.put(processingType,new List<BIEnrichmentProcessor.recordWrapper>());
                   }
                   BIEnrichmentProcessor.recordWrapper record = new BIEnrichmentProcessor.recordWrapper();
                   record.recordId = l.Id;
                   record.processingType = processingType;
                   processingTypeLeadMap.get(processingType).add(record);
               }
        }
        
        //Send each failed type of leads to invocable apex method
        for(string processingType : processingTypeLeadMap.keyset()){
            BIEnrichmentProcessor.getRecords(processingTypeLeadMap.get(processingType)); 
        } 
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
}
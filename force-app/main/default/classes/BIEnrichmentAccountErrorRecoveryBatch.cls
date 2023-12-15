//[RGaokar 11/10/2023 SFDC-3629 Error recovery of BI Enrichment failures - Account]
//Sync BI enrichment failed record or record for which one of the enrichment failed so never sync for BI enrichment, 
//such records needs to be retry on same day of creation
//[RGaokar 11/27/2023 SFDC-4217 Extend createddate filter to consider all missing accounts for segmentation]
//Batch can be called from anonymous window as follows:
//string query = 'Select name,id, BI_Enrichment_Sync_Status__c,Segmentation_Sync_Ready__c,Customer_Group__c from Account where CreatedDate >= 2023-11-17T00:00:00Z AND CreatedDate < Today AND (BI_Enrichment_Sync_Status__c includes (\'Failed - segment\') OR (Segmentation_Sync_Ready__c = true AND Customer_Group__c = null))';
//BIEnrichmentAccountErrorRecoveryBatch BIEnrichmentBatch = new BIEnrichmentAccountErrorRecoveryBatch(query, 'Failed - segment');
//Database.executeBatch(BIEnrichmentBatch, 50);
public class BIEnrichmentAccountErrorRecoveryBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    string query;
    string biProcessingType;
    
    public BIEnrichmentAccountErrorRecoveryBatch(string query,string biProcessingType){
        this.query = query;
        this.biProcessingType = biProcessingType;
    }
    
    public Database.QueryLocator start (Database.BatchableContext bc){
        if(query == null){
            query = 'Select name,id, BI_Enrichment_Sync_Status__c, Segmentation_Sync_Ready__c,Customer_Group__c from Account where CreatedDate >= 2023-11-17T00:00:00Z AND';
            if(biProcessingType.containsIgnorecase('segment')){
                query += ' (BI_Enrichment_Sync_Status__c includes (:biProcessingType) OR (Segmentation_Sync_Ready__c = true AND Customer_Group__c = null))';
            }else{
                query += ' BI_Enrichment_Sync_Status__c includes (:biProcessingType)';
            }
        }
        return Database.getQueryLocator(query); 
        
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        map<string,List<BIEnrichmentProcessor.recordWrapper>> processingTypeAccountsMap = new map<string,List<BIEnrichmentProcessor.recordWrapper>>();
        
        for(Account a:(List<Account>)scope){
            //Records failed BI enrichment or records never send for BI Segmentation due to one of the enrichment faliure
            if(a.BI_Enrichment_Sync_Status__c != null){
                List<string> accountProcessingTypes = a.BI_Enrichment_Sync_Status__c.split(';');
                if(!accountProcessingTypes.contains('Failed - segment') && !accountProcessingTypes.contains('Success - segment')
                   && a.Segmentation_Sync_Ready__c == true && a.Customer_Group__c == null){
                    accountProcessingTypes.add('Failed - segment');
                }

                for(string accountProcessingType:accountProcessingTypes){
                    string processingType = accountProcessingType.substringAfter('- ');
                    if(!processingTypeAccountsMap.containsKey(processingType)){
                        processingTypeAccountsMap.put(processingType,new List<BIEnrichmentProcessor.recordWrapper>());
                    }
                    BIEnrichmentProcessor.recordWrapper record = new BIEnrichmentProcessor.recordWrapper();
                    record.recordId = a.Id;
                    record.processingType = processingType;
                    processingTypeAccountsMap.get(processingType).add(record);
                }
            } 
            
            //Records never send for BI Segmentation due to one of the enrichment faliure, so no status for success/failed segment available on record
            else if(a.BI_Enrichment_Sync_Status__c == null && a.Segmentation_Sync_Ready__c == true && a.Customer_Group__c == null){
                   string processingType = 'segment';
                    if(!processingTypeAccountsMap.containsKey(processingType)){
                        processingTypeAccountsMap.put(processingType,new List<BIEnrichmentProcessor.recordWrapper>());
                    }
                   BIEnrichmentProcessor.recordWrapper record = new BIEnrichmentProcessor.recordWrapper();
                   record.recordId = a.Id;
                   record.processingType = processingType;
                   processingTypeAccountsMap.get(processingType).add(record);
               }
        }
        
        //Send each failed type of accounts to invocable apex method
        for(string processingType : processingTypeAccountsMap.keyset()){
            BIEnrichmentProcessor.getRecords(processingTypeAccountsMap.get(processingType)); 
        } 
    }
    
    public void finish(Database.BatchableContext bc){
        BIEnrichmentLeadErrorRecoveryBatch BIEnrichmentBatch = new BIEnrichmentLeadErrorRecoveryBatch(null, biProcessingType);
        Database.executeBatch(BIEnrichmentBatch, 100);
    }
    
}
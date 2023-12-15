//[RGaokar 11/07/2023 SFDC-3627 Send Salesforce Account/Lead Info to BI Model - Invocable Apex]
public class BIEnrichmentProcessor implements system.Queueable, Database.AllowsCallouts{
    private List<Id>recordIds = new List<Id>();
    string processingType;
    
    //Constructor
    public BIEnrichmentProcessor(List<Id>recordIds, string processingType){
        this.recordIds = recordIds;
        this.processingType = processingType;
    }
    
    //Invocable Method
    @invocableMethod(label = 'Send data for BI Processing')
    public static void getRecords(List<recordWrapper>records){
        List<Id>recordIds = new List<Id>();
        for(recordWrapper record:records){
            recordIds.add(record.recordId);
        }
        system.enqueueJob(new BIEnrichmentProcessor(recordIds,records[0].processingType));
    }
    
    //Queueable Execute
    public void execute(system.QueueableContext ctx){
        processBIPayload(recordIds, processingType);
    }
    
    
    //Process records for BI Payload
    public static void processBIPayload(List<Id>recordIds, string processingType){
        List<BIEnrichmentRecordWrapper> biRecords = new List<BIEnrichmentRecordWrapper>();
        //Get object type
        String objectName = recordIds[0].getSObjectType().getDescribe().getName();
        
        //Get BI Sync fields
        List <BI_Enrichment_Sync__mdt> queryFields = [Select Field_API_Name__c, Field_Processing_Type__c From BI_Enrichment_Sync__mdt where Object__c  =:objectName AND BI_Processing_Type__c =:processingType];
        String fieldNames = '';
        for(BI_Enrichment_Sync__mdt queryField:queryFields){
            if(queryField.Field_Processing_Type__c == 'Other')fieldNames += queryField.Field_API_Name__c + ',';
        }
        
        //Query info for BI sync
        String query = 'Select ' + fieldNames + 'BI_Enrichment_Sync_Status__c,Id from '+ objectName + ' where id in :recordIds';
        Map<id, sObject> sObjectMap = new Map<id, sObject>(Database.query(query));
        
        //Create BI payload
        for(Id recordId:recordIds){
            map<string,object> record = new map<string,object>();
            record.put('Id',recordId);
            record.put('type',processingType);
            record.put('BI_Enrichment_Sync_Status__c',sObjectMap.get(recordId).get('BI_Enrichment_Sync_Status__c'));
            for(BI_Enrichment_Sync__mdt queryField:queryFields){
                record.put(queryField.Field_API_Name__c,sObjectMap.get(recordId).get(queryField.Field_API_Name__c));
            }
            biRecords.add(new BIEnrichmentRecordWrapper(record));
        }
        
        //Send to Workato
        if(!biRecords.isEmpty()){
            BIEnrichmentCalloutHelper.sendPayload(biRecords);
        }
    }
    
    //Invocable method wrapper
    public class recordWrapper {
        @InvocableVariable(required=true)
        public ID recordId;
        
        @InvocableVariable(required=true)
        public String processingType;
    }
    
    //BI Payload Processor Wrapper
    public class BIEnrichmentRecordWrapper {
        public map<string,object> Record {get;set;}
        
        //BI Payload includes record
        public BIEnrichmentRecordWrapper(map<string,object> Record){
            this.Record = Record;
        }
    }
    
}
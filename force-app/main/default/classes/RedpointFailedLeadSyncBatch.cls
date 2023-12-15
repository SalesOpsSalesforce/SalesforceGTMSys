//[RGaokar 11/25/2022 SFDC-1161 SF --> Redpoint: Batch job to handle Failed Redpoint Sync for Leads]
//[RGaokar 02/06/2023 SFDC-1774 Changes to pass KPU lookup fields, passing Redpoint property names instead of SF fields api names to Workato Recipe]
//[RGaokar 04/11/2023 SFDC-2350  SF -> Redpoint Workato task reduction: Remove Workato loops by sending individual Contact payload instead of account & related contacts in payload]
public class RedpointFailedLeadSyncBatch implements Database.Batchable<sObject>{
    // When scheduler runs the batch, then whereClause is set in start method of this batch
    // When the batch is called from Execute Anonymous Window, then where Clause is passed as parameter from Execute Anonymous Window, example: 'where id = \'00QDS000008W0kT2AS\' AND IsConverted = false AND (email != null OR Klaviyo_Profile_ID__c != null)'
    string whereClause = null;
    private static List <Redpoint_K4K_Sync__mdt> leadFields = [Select Field_API_Name__c, Field_Processing_Type__c, Query_Field__c,Redpoint_Property_Name__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Lead' AND Is_Active__c = true];
    
    public RedpointFailedLeadSyncBatch(string whereClause){
        this.whereClause = whereClause;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        string query = queryCreator();
        if(whereClause == null){//If scheduler started this batch
            whereClause = 'where Failed_Redpoint_Sync__c = true AND IsConverted = false';
            whereClause += ' AND (email != null OR Klaviyo_Profile_ID__c != null)';//Any of the key available for non-converted leads //OR phone != null 
        }
        if(string.isNotBlank(whereClause))query += whereClause;
        //system.debug('query--'+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead>scope){
        List<RedpointCalloutHandler.RedpointRecordWrapper> payload = new List<RedpointCalloutHandler.RedpointRecordWrapper>();
        List<Lead> updateLeadList = new List<Lead>();
        List <String> errorList = new List <String> ();
        
        //Iterate throught each lead to form redpoint payload
        for(Lead ld:scope){
            map <string,object> RecordInfo = new map <string,object> ();
            RecordInfo.put('SF_Id', ld.id);
            RecordInfo.put('Klaviyo_Profile_ID__c', ld.Klaviyo_Profile_ID__c);
            RedpointCalloutHandler.RedpointRecordWrapper leadWrapper = new RedpointCalloutHandler.RedpointRecordWrapper(payloadProcessor(RecordInfo,ld));
            payload.add(leadWrapper);
            //Clear redpoint failed flag on leads
            updateLeadList.add(new Lead(Id = ld.Id, Failed_Redpoint_Sync__c = false));
        }
        
        //Send payload to Workato webhook
        if(!payload.isEmpty()){
            system.enqueueJob(new RedpointCalloutHandler(payload)); 
        }
        
        //Clear the redpoint failed flaged on leads
        if(!updateLeadList.isEmpty()){
            errorList.addAll(updateRecords(updateLeadList));
        }
        
        //Error handling if lead redpoint failed flag update fails
        if(!errorList.isEmpty()){
            ExceptionHandling.performExceptionHandling(null, 'RedpointFailedLeadSyncBatch', errorList);  
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
    //Create query with monitored lead fields
    private static string queryCreator(){
        string query;
        query = 'Select id,';

        for(Redpoint_K4K_Sync__mdt leadField:leadFields){
            if(leadField.Field_Processing_Type__c == 'Lookup'){
                query += leadField.Query_Field__c + ',';
            }else if(leadField.Field_Processing_Type__c == 'Formula' && !query.containsIgnoreCase(leadField.Query_Field__c)){
                query += leadField.Query_Field__c + ',';
            }else if(leadField.Field_Processing_Type__c != 'Formula' && leadField.Field_Processing_Type__c != 'Lookup'){
                query += leadField.Field_API_Name__c + ',';
            } 
        }
        
        query += 'Klaviyo_Profile_ID__c, Klaviyo_Product_Usage__c from Lead ';
        return query;  
    }
    
    //Perform Lead Info Processing
    private static map <string,object> payloadProcessor(map <string,object> Record, Lead ld){
        for(Redpoint_K4K_Sync__mdt leadField :leadFields){
            Boolean nullLookupField = false;
            if(leadField.Field_Processing_Type__c == 'Lookup' && leadField.Field_API_Name__c == 'Redpoint_Formula_Sync_Widget__c'){
                nullLookupField = ld.getSObject(leadField.Query_Field__c.split('\\.')[0]) == null;//[RGaokar 09/15/2023 SFDC-3613]
            }else if(leadField.Field_Processing_Type__c == 'Lookup' && leadField.Field_API_Name__c != 'Redpoint_Formula_Sync_Widget__c'){
                nullLookupField = ld.get(leadField.Field_API_Name__c) == null;
            }
            
            if(leadField.Field_Processing_Type__c != 'Lookup' && leadField.Field_Processing_Type__c != 'Formula'){
                Record.put(leadField.Redpoint_Property_Name__c, ld.get(leadField.Field_API_Name__c));
            }else if(leadField.Field_Processing_Type__c == 'Lookup' && !nullLookupField){//if lookup field is NOT null
                List<string> queryFieldSplitNames = leadField.Query_Field__c.split('\\.');
                Record.put(leadField.Redpoint_Property_Name__c, ld.getSObject(queryFieldSplitNames[0]).get(queryFieldSplitNames[1]));
            }else if (leadField.Field_Processing_Type__c == 'Lookup' && nullLookupField){//if lookup field is null
                Record.put(leadField.Redpoint_Property_Name__c, null);
            }else if(leadField.Field_Processing_Type__c == 'Formula'){
                Record.put(leadField.Redpoint_Property_Name__c, ld.get(leadField.Query_Field__c));
            }
        }
        return Record; 
    }
    
    //Update the records to clear the redpoint flag
    public static List <String> updateRecords(List<sObject> sObjectUpdateList){
        List <String> errorList = new List <String> ();
        List<Database.SaveResult> srList = Database.update(sObjectUpdateList, false);
        String updateErrors = '';
        for(Database.SaveResult result:srList){
            if(!result.isSuccess()){
                updateErrors += '\n'+'Record Id: '+ result.getId();
                for(Database.Error err : result.getErrors()) {
                    updateErrors += ' Error Message: ' +err.getMessage()+'\n';
                }  
            }
        }
        
        if (String.isNotBlank(updateErrors)){
            errorList.add('Errors occured when clearing Failed Redpoint Sync flag for following records:');
            errorList.add(updateErrors);
        }
        
        return errorList; 
    }
}
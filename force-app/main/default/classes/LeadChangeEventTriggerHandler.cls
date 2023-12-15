//[RGaokar 11/03/2022 SFDC - 1157 SF to Redpoint Lead Changes Helper Class]
//[RGaokar 02/06/2023 SFDC-1774 Changes to pass KPU lookup fields, passing Redpoint property names instead of SF fields api names to Workato Recipe]
//[RGaokar 04/11/2023 SFDC-2350  SF -> Redpoint Workato task reduction: Remove Workato loops by sending individual Contact payload instead of account & related contacts in payload]
public class LeadChangeEventTriggerHandler {
    private static List <Redpoint_K4K_Sync__mdt> leadFields = [Select Field_API_Name__c, Field_Processing_Type__c, Query_Field__c, Redpoint_Property_Name__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Lead' AND Is_Active__c = true];
    private static List <Redpoint_K4K_Sync__mdt> leadQueryFields = [Select Field_API_Name__c, Field_Processing_Type__c , Query_Field__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Lead' AND Is_Active__c = true 
                                                                    AND (Field_Processing_Type__c = 'Lookup' OR Field_Processing_Type__c  = 'Formula')];
    
    public static void redpointLeadSync(List<LeadChangeEvent>newLeadChanges){
        
        List <LeadChangeEvent> redpointMonitorChanges = new List <LeadChangeEvent>();
        List <LeadChangeEvent> gapEventChanges = new List <LeadChangeEvent>();
        Set <string> changedRecordIds = new Set <string>();
        List <String> overflowErrorList = new List <String> ();
        Boolean keyChanged = false;
        
        //Get redpoint monitor records 
        for(LeadChangeEvent change:newLeadChanges){
            if(change.ChangeEventHeader.getchangeType() == 'Create' && change.get('Email') != null && change.get('MergeLead__c') == null){//|| change.get('Phone') != null //If email available & lead is not merging then consider the change for further processing
                redpointMonitorChanges.add(change);
                changedRecordIds.addAll(new Set <string>(change.ChangeEventHeader.getrecordIds()));
            }else if(change.ChangeEventHeader.getchangeType() == 'Update'){
                List<string> changedFields = change.ChangeEventHeader.getchangedFields();//Get all changed fields
                Boolean recordKeyChanged = changedFields.contains('Email');
                if(!keyChanged && recordKeyChanged)keyChanged = recordKeyChanged;//Usually key change will happen with one record at a time, but if its there for multiple then to avoid query complexity keychanged variable is set to true for entire batch of record. When workato payload is created, that time keychanged will be monitored record wise. 
                
                //If Failed Redpoint Sync flag is updated then skip this update, otherwise proceed to redpoint monitor changes processing
                if(changedFields.contains('Failed_Redpoint_Sync__c')){
                    continue;
                }
                
                for (Redpoint_K4K_Sync__mdt leadField:leadFields){
                    if(changedFields.contains(leadField.Field_API_Name__c)){//If Redpoint monitored field changes then consider the change for further processing
                        redpointMonitorChanges.add(change);
                        changedRecordIds.addAll(new Set <string>(change.ChangeEventHeader.getrecordIds()));
                        break;
                    }
                }
            }else if(change.ChangeEventHeader.getchangeType() == 'GAP_CREATE' || change.ChangeEventHeader.getchangeType() == 'GAP_UPDATE'){//Gap events contains only recordIds which can be used to retrieved current data for those records
                gapEventChanges.add(change);
                changedRecordIds.addAll(new Set <string>(change.ChangeEventHeader.getrecordIds()));
            }else if(change.ChangeEventHeader.getchangeType() == 'GAP_OVERFLOW'){
                overflowErrorList.add('\n'+'Commit Time Stamp:'+change.ChangeEventHeader.getcommitTimestamp() + ' Transaction Key: '+change.ChangeEventHeader.gettransactionKey());  
            }
        }
        
        //Wrap record information together for payload processing
        map<string, map <string,object>> processedRecords = new map<string, map <string,object>>();
        if(!redpointMonitorChanges.isEmpty()){
            processedRecords = changeEventProcessor(redpointMonitorChanges, false, changedRecordIds, keyChanged);
        }
        
        if(!gapEventChanges.isEmpty()){
            processedRecords = changeEventProcessor(gapEventChanges, true, changedRecordIds, keyChanged);
        }
        
        
        //Send payload to Workato webhook
        if(!processedRecords.isEmpty()){
            List<RedpointCalloutHandler.RedpointRecordWrapper> payload = new List<RedpointCalloutHandler.RedpointRecordWrapper>();
            //Prepare Paylod
            for(string ldId: processedRecords.keyset()){
                RedpointCalloutHandler.RedpointRecordWrapper leadWrapper = new RedpointCalloutHandler.RedpointRecordWrapper(processedRecords.get(ldId));
                payload.add(leadWrapper);
            }
            
            system.enqueueJob(new RedpointCalloutHandler(payload));
        }
        
        //Log error for overflow events
        if(!overflowErrorList.isEmpty()){
            List <String> errorList = new List <String> ();
            errorList.add('Errors occured due to overflow event:');
            errorList.addAll(overflowErrorList);
            ExceptionHandling.performExceptionHandling(null, 'LeadChangeEventTriggerHandler', errorList);
        }
    }
    
    //Process record monitored information
    private static map<string, map <string,object>> changeEventProcessor(List <LeadChangeEvent> redpointMonitorChanges, Boolean gapEvents, Set <string> changedRecordIds, Boolean keyChanged){
        map<string, map <string,object>> processedRecords = new map<string, map <string,object>>();//Lead Id & Lead Data Map
        Map<id, Lead> leadMap = new Map<id, Lead>();
        String fieldNames = '';
        List <Redpoint_K4K_Sync__mdt> redpointK4KFields = new List <Redpoint_K4K_Sync__mdt>();
        
        //For create/update change type only consider the Formula & Lookup fields to avoid looping through entire fieldset
        if(!gapEvents && !keyChanged){
            redpointK4KFields.addAll(leadQueryFields);
        }else{
            redpointK4KFields.addAll(leadFields);
        }
        
        //Retrive the lookup & formula query field info (and all other fields info for gap events)
        for (Redpoint_K4K_Sync__mdt queryField:redpointK4KFields){
            if(queryField.Field_Processing_Type__c == 'Lookup'){
                fieldNames += queryField.Query_Field__c + ',';
            }else if(queryField.Field_Processing_Type__c == 'Formula' && !fieldNames.containsIgnoreCase(queryField.Query_Field__c)){
                fieldNames += queryField.Query_Field__c + ',';
            }else if((gapEvents || keyChanged) && queryField.Field_Processing_Type__c == 'Other'){//Dont include Key fields as those already included in query
                fieldNames += queryField.Field_API_Name__c + ',';
            }
        }
        
        //Only retrieved the info for non-converted leads with either Klaviyo_Profile_ID__c or email available & process such leads further
        String query = 'Select ' + fieldNames + 'Klaviyo_Product_Usage__c,id,Email,Klaviyo_Profile_ID__c from lead';//Phone
        query += ' where id in :changedRecordIds AND IsConverted = false AND (Email != null OR Klaviyo_Profile_ID__c != null)';//OR Phone != null 
        leadMap = new Map<id, Lead>((List<Lead>)Database.query(query));
        
        //Capture changes in processedRecords map
        for(LeadChangeEvent changeEvent :redpointMonitorChanges){
            //system.debug('changeEvent--'+changeEvent);
            //Process each record
            for(String recordId:changeEvent.ChangeEventHeader.getrecordIds()){
                if(!leadMap.containsKey(recordId)){//If retrived lead map DO NOT contain the lead then proceed to the next lead without processing further logic for Redpoint.
                    continue;
                }
                
                Lead queriedLead = leadMap.get(recordId);
                if(!processedRecords.containsKey(recordId)){
                    map <string,object> RecordInfo = new map <string,object> ();
                    RecordInfo.put('SF_Id', recordId);
                    RecordInfo.put('Klaviyo_Profile_ID__c', queriedLead.Klaviyo_Profile_ID__c);
                    if(queriedLead.Klaviyo_Profile_ID__c == null){//If Klaviyo_Profile_ID__c is not available then send other keys
                        RecordInfo.put('email', queriedLead.Email);
                    	//RecordInfo.put('Phone', queriedLead.Phone);
                    }
                    processedRecords.put(recordId, RecordInfo);
                }
                processedRecords.put(recordId, payloadProcessor(processedRecords.get(recordId),changeEvent,queriedLead,gapEvents));
            }   
        }
        return processedRecords;
    }
    
    //Get values for changed Redpoint monitored fields
    private static map <string,object> payloadProcessor (map <string,object> Record, LeadChangeEvent changeEvent,Lead queriedLead, Boolean gapEvents){
        List<string> changedFields = new List<string> ();
        Boolean keyChanged = false;
        if(changeEvent.ChangeEventHeader.getchangeType() == 'Update'){
            changedFields = changeEvent.ChangeEventHeader.getchangedFields();
            keyChanged = changedFields.contains('Email');
        }
        
        for(Redpoint_K4K_Sync__mdt leadField:leadFields){
            Boolean eligibleCreateField = changeEvent.ChangeEventHeader.getchangeType() == 'Create' && changeEvent.get(leadField.Field_API_Name__c) != null;
            Boolean eligibleUpdateField = changeEvent.ChangeEventHeader.getchangeType() == 'Update' && changedFields.contains(leadField.Field_API_Name__c);
            Boolean keyMonitoredChange = keyChanged && queriedLead.Klaviyo_Profile_ID__c == null;//If key is changed for lead which do not have Klaviyo_Profile_ID__c populated, so this key change will create new Klaviyo profile which will need all existing lead information
            
            Boolean monitoredFieldChanged = eligibleCreateField || eligibleUpdateField;
            Boolean monitoredFieldOrGapChange = gapEvents || monitoredFieldChanged || keyMonitoredChange;
            
            Boolean nullLookupField = false;
            if(leadField.Field_Processing_Type__c == 'Lookup' && leadField.Field_API_Name__c == 'Redpoint_Formula_Sync_Widget__c'){
                nullLookupField = queriedLead.getSObject(leadField.Query_Field__c.split('\\.')[0]) == null;//[RGaokar 09/15/2023 SFDC-3613]
            }else if(leadField.Field_Processing_Type__c == 'Lookup' && leadField.Field_API_Name__c != 'Redpoint_Formula_Sync_Widget__c'){
                nullLookupField = queriedLead.get(leadField.Field_API_Name__c) == null;
            }
            
            if(monitoredFieldChanged && leadField.Field_Processing_Type__c != 'Lookup' && leadField.Field_Processing_Type__c != 'Formula'){
                Record.put(leadField.Redpoint_Property_Name__c, changeEvent.get(leadField.Field_API_Name__c));
            }else if((gapEvents || keyMonitoredChange) && leadField.Field_Processing_Type__c != 'Lookup' && leadField.Field_Processing_Type__c != 'Formula'){
                Record.put(leadField.Redpoint_Property_Name__c, queriedLead.get(leadField.Field_API_Name__c));
            }else if(monitoredFieldOrGapChange && leadField.Field_Processing_Type__c == 'Lookup' && !nullLookupField){//if lookup field is NOT null
                List<string> queryFieldSplitNames = leadField.Query_Field__c.split('\\.');
                Record.put(leadField.Redpoint_Property_Name__c, queriedLead.getSObject(queryFieldSplitNames[0]).get(queryFieldSplitNames[1]));
            }else if (monitoredFieldOrGapChange && leadField.Field_Processing_Type__c == 'Lookup' && nullLookupField){//if lookup field is null
                Record.put(leadField.Redpoint_Property_Name__c, null);
            }else if(monitoredFieldOrGapChange && leadField.Field_Processing_Type__c == 'Formula'){
                Record.put(leadField.Redpoint_Property_Name__c, queriedLead.get(leadField.Query_Field__c));
            }            
        }
        return Record;
    }
}
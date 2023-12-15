//[RGaokar 11/03/2022 SFDC - 1157 SF to Redpoint Account Changes Helper Class]
//[RGaokar 02/06/2023 SFDC-1774 Changes to pass KPU lookup fields, passing Redpoint property names instead of SF fields api names to Workato Recipe]
//[RGaokar 04/11/2023 SFDC-2350  SF -> Redpoint Workato task reduction: Remove Workato loops by sending individual Contact payload instead of account & related contacts in payload]
public class AccountChangeEventTriggerHandler {
    //Get Redpoint monitored fields
    private static List <Redpoint_K4K_Sync__mdt> accountFields = [Select Field_API_Name__c, Field_Processing_Type__c, Query_Field__c, Redpoint_Property_Name__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Account' AND Is_Active__c = true];
    private static List <Redpoint_K4K_Sync__mdt> accountQueryFields = [Select Field_API_Name__c, Field_Processing_Type__c, Query_Field__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Account' AND Is_Active__c = true 
                                                                       AND (Field_Processing_Type__c = 'Lookup' OR Field_Processing_Type__c  = 'Formula')];
    
    public static void redpointAccountSync(List<AccountChangeEvent>newAccountChanges){
        
        List <AccountChangeEvent> redpointMonitorChanges = new List <AccountChangeEvent>();
        List <AccountChangeEvent> gapEventChanges = new List <AccountChangeEvent>();
        Set <string> changedRecordIds = new Set <string>();
        List <String> overflowErrorList = new List <String> ();
        
        //Get redpoint monitored records 
        for(AccountChangeEvent change:newAccountChanges){
            if(change.ChangeEventHeader.getchangeType() == 'Update'){
                List<string> changedFields = change.ChangeEventHeader.getchangedFields();//Get all changed fields
                
                //If Failed Redpoint Sync flag is updated then skip this update, otherwise proceed to redpoint monitor changes processing
                if(changedFields.contains('Failed_Redpoint_Sync__c')){
                    continue;
                }
                
                for (Redpoint_K4K_Sync__mdt accountField:accountFields){
                    if(changedFields.contains(accountField.Field_API_Name__c)){//If Redpoint monitored field changes then consider the change for further processing
                        redpointMonitorChanges.add(change);
                        changedRecordIds.addAll(new Set <string>(change.ChangeEventHeader.getrecordIds()));
                        break;
                    }
                }
            }else if(change.ChangeEventHeader.getchangeType() == 'GAP_UPDATE'){//Gap events contains only recordIds which can be used to retrieved current data for those records
                gapEventChanges.add(change);
                changedRecordIds.addAll(new Set <string>(change.ChangeEventHeader.getrecordIds()));
            }else if(change.ChangeEventHeader.getchangeType() == 'GAP_OVERFLOW'){
                overflowErrorList.add('\n'+'Commit Time Stamp:'+change.ChangeEventHeader.getcommitTimestamp() + ' Transaction Key: '+change.ChangeEventHeader.gettransactionKey());  
            }
        }
        
        
        //Wrap record information together for payload processing
        map<string, map <string,object>> processedRecords = new map<string, map <string,object>>();
        if(!redpointMonitorChanges.isEmpty()){
            processedRecords = changeEventProcessor(redpointMonitorChanges, false, changedRecordIds);
        }
        
        if(!gapEventChanges.isEmpty()){
            processedRecords = changeEventProcessor(gapEventChanges, true, changedRecordIds);
        }
        
        //Send payload to Workato webhook
        if(!processedRecords.isEmpty() && !changedRecordIds.isEmpty()){
            //Get Contact information for redpoint monitored/gap records
            //Only get contacts with non empty Klaviyo_Profile_ID__c, email fields
            List <Contact> conList = [Select Id, email, Klaviyo_Profile_ID__c, accountId from contact where accountId in :changedRecordIds AND 
                                      (email != null OR Klaviyo_Profile_ID__c != null)];//phone,//OR phone != null 
            
            List<RedpointCalloutHandler.RedpointRecordWrapper> payload = new List<RedpointCalloutHandler.RedpointRecordWrapper>();
            
            //Prepare Paylod
            for(Contact c:conList){
                map<string,object> contactRecord = new map<string,object> ();
                contactRecord.putAll(processedRecords.get(c.accountId));
                contactRecord.put('SF_Id', c.Id);
                contactRecord.put('Klaviyo_Profile_ID__c', c.Klaviyo_Profile_ID__c);
                if(c.Klaviyo_Profile_ID__c == null){//If Klaviyo_Profile_ID__c is not available then send other keys
                    contactRecord.put('email', c.Email);
                }
                RedpointCalloutHandler.RedpointRecordWrapper contactWrapper = new RedpointCalloutHandler.RedpointRecordWrapper(contactRecord);
                payload.add(contactWrapper);
            }
            
            if(!payload.isEmpty()){
                system.enqueueJob(new RedpointCalloutHandler(payload));
            }
        }
        
        //Log error for overflow events
        if(!overflowErrorList.isEmpty()){
            List <String> errorList = new List <String> ();
            errorList.add('Errors occured due to overflow event:');
            errorList.addAll(overflowErrorList);
            ExceptionHandling.performExceptionHandling(null, 'AccountChangeEventTriggerHandler', errorList);
        }
    }
    
    //Process record monitored information
    private static map<string, map <string,object>> changeEventProcessor(List <AccountChangeEvent> redpointMonitorChanges, Boolean gapEvents, Set <string> changedRecordIds){
        map<string, map <string,object>> processedRecords = new map<string, map <string,object>>();//Account Id & Account Data Map
        String fieldNames = '';
        List <Redpoint_K4K_Sync__mdt> redpointK4KFields = new List <Redpoint_K4K_Sync__mdt>();
        
        //For update change type only consider the Formula & Lookup fields to avoid looping through entire fieldset
        if(!gapEvents){
            redpointK4KFields.addAll(accountQueryFields);
        }else{
            redpointK4KFields.addAll(accountFields);
        }
        
        //Retrive the lookup & formula query field info (and all other fields info for gap events)
        for (Redpoint_K4K_Sync__mdt queryField:redpointK4KFields){
            if(queryField.Field_Processing_Type__c == 'Lookup'){
                fieldNames += queryField.Query_Field__c + ',';
            }else if(queryField.Field_Processing_Type__c == 'Formula' && !fieldNames.containsIgnoreCase(queryField.Query_Field__c)){
                fieldNames += queryField.Query_Field__c + ',';
            }else if(gapEvents && queryField.Field_Processing_Type__c != 'Formula' && queryField.Field_Processing_Type__c != 'Lookup'){
                fieldNames += queryField.Field_API_Name__c + ',';
            }
        }
        
        String query = 'Select ' + fieldNames + 'Klaviyo_Product_Usage__c,id from account where id in :changedRecordIds';
        Map<id, account> accountMap = new Map<id, account>((List<Account>)Database.query(query));
        
        //Capture changes in processedRecords map
        for(AccountChangeEvent changeEvent :redpointMonitorChanges){
            //system.debug('changeEvent--'+changeEvent);
            //Process each record
            for(String recordId:changeEvent.ChangeEventHeader.getrecordIds()){
                if(!processedRecords.containsKey(recordId)){
                    map <string,object> RecordInfo = new map <string,object> ();
                    RecordInfo.put('AccountId', recordId);
                    processedRecords.put(recordId, RecordInfo);
                }
                processedRecords.put(recordId, payloadProcessor(processedRecords.get(recordId),changeEvent,accountMap.get(recordId),gapEvents));
            }   
        }
        return processedRecords;
    }
    
    
    //Get values for changed Redpoint monitored fields
    private static map <string,object> payloadProcessor(map <string,object> Record, AccountChangeEvent changeEvent, Account queriedAcc, Boolean gapEvents){
        List<string> changedFields = new List<string> ();
        if(changeEvent.ChangeEventHeader.getchangeType() == 'Update')changedFields = changeEvent.ChangeEventHeader.getchangedFields();
        
        for(Redpoint_K4K_Sync__mdt accountField:accountFields){
            Boolean monitoredFieldChanged = changeEvent.ChangeEventHeader.getchangeType() == 'Update' && changedFields.contains(accountField.Field_API_Name__c);
            Boolean monitoredFieldOrGapChange = gapEvents || monitoredFieldChanged;
            
            Boolean nullLookupField = false;
            if(accountField.Field_Processing_Type__c == 'Lookup' && accountField.Field_API_Name__c == 'Redpoint_Formula_Sync_Widget__c'){
                nullLookupField = queriedAcc.getSObject(accountField.Query_Field__c.split('\\.')[0]) == null;//[RGaokar 09/15/2023 SFDC-3613]
            }else if(accountField.Field_Processing_Type__c == 'Lookup' && accountField.Field_API_Name__c != 'Redpoint_Formula_Sync_Widget__c'){
                nullLookupField = queriedAcc.get(accountField.Field_API_Name__c) == null;
            }
            
            if(monitoredFieldChanged && accountField.Field_Processing_Type__c != 'Lookup' && accountField.Field_Processing_Type__c != 'Formula'){
                Record.put(accountField.Redpoint_Property_Name__c, changeEvent.get(accountField.Field_API_Name__c));
            }else if(gapEvents && accountField.Field_Processing_Type__c != 'Lookup' && accountField.Field_Processing_Type__c != 'Formula'){
                Record.put(accountField.Redpoint_Property_Name__c, queriedAcc.get(accountField.Field_API_Name__c));
            }else if(monitoredFieldOrGapChange && accountField.Field_Processing_Type__c == 'Lookup' && !nullLookupField){//if lookup field is NOT null
                List<string> queryFieldSplitNames = accountField.Query_Field__c.split('\\.');
                Record.put(accountField.Redpoint_Property_Name__c, queriedAcc.getSObject(queryFieldSplitNames[0]).get(queryFieldSplitNames[1]));
            }else if (monitoredFieldOrGapChange && accountField.Field_Processing_Type__c == 'Lookup' && nullLookupField){//if lookup field is null
                Record.put(accountField.Redpoint_Property_Name__c, null);
            }else if(monitoredFieldOrGapChange && accountField.Field_Processing_Type__c == 'Formula'){
                Record.put(accountField.Redpoint_Property_Name__c, queriedAcc.get(accountField.Query_Field__c));
            } 
        }
        return Record;
    }
}
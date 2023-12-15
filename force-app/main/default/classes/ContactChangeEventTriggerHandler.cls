//[RGaokar 11/03/2022 SFDC - 1157 SF to Redpoint Contact Changes Helper Class]
//[RGaokar 02/06/2023 SFDC-1774 Changes to pass KPU lookup fields, passing Redpoint property names instead of SF fields api names to Workato Recipe]
//[RGaokar 04/11/2023 SFDC-2350  SF -> Redpoint Workato task reduction: Remove Workato loops by sending individual Contact payload instead of account & related contacts in payload]
public class ContactChangeEventTriggerHandler {
    private static List <Redpoint_K4K_Sync__mdt> accountFields = [Select Field_API_Name__c, Field_Processing_Type__c, Query_Field__c, Redpoint_Property_Name__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Account' AND Is_Active__c = true];
    private static List <Redpoint_K4K_Sync__mdt> contactFields = [Select Field_API_Name__c, Field_Processing_Type__c, Query_Field__c, Redpoint_Property_Name__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Contact' AND Is_Active__c = true];
    private static List <Redpoint_K4K_Sync__mdt> contactQueryFields = [Select Field_API_Name__c, Field_Processing_Type__c, Query_Field__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Contact' AND Is_Active__c = true 
                                                                       AND (Field_Processing_Type__c = 'Lookup' OR Field_Processing_Type__c  = 'Formula')];
    
    public static void redpointContactSync(List<ContactChangeEvent>newContactChanges){
        
        List <ContactChangeEvent> redpointMonitorChanges = new List <ContactChangeEvent>();
        List <ContactChangeEvent> gapEventChanges = new List <ContactChangeEvent>();
        Set <string> changedRecordIds = new Set <string>();
        List <String> overflowErrorList = new List <String> ();
        
        //Get redpoint monitor records 
        for(ContactChangeEvent change:newContactChanges){
            if(change.ChangeEventHeader.getchangeType() == 'Create' && change.get('Email') != null){//|| change.get('Phone') != null
                redpointMonitorChanges.add(change);
                //changedRecordIds.addAll(new Set <string>(change.ChangeEventHeader.getrecordIds()));//Uncomment this if contact lookup or formula field consider in future
            }else if(change.ChangeEventHeader.getchangeType() == 'Update'){
                List<string> changedFields = change.ChangeEventHeader.getchangedFields();//Get all changed fields
                
                //If Failed Redpoint Sync flag is updated then skip this update, otherwise proceed to redpoint monitor changes processing
                if(changedFields.contains('Failed_Redpoint_Sync__c')){
                    continue;
                }
                
                for (Redpoint_K4K_Sync__mdt contactField:contactFields){
                    if(changedFields.contains(contactField.Field_API_Name__c)){//If Redpoint monitored field changes then consider the change for further processing
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
        
        //Send change information for payload processing
        if(!redpointMonitorChanges.isEmpty()){
            changeEventProcessor(redpointMonitorChanges, false, changedRecordIds);
        }
        
        if(!gapEventChanges.isEmpty()){
            changeEventProcessor(gapEventChanges, true, changedRecordIds);
        }
        
        //Log error for overflow events
        if(!overflowErrorList.isEmpty()){
            List <String> errorList = new List <String> ();
            errorList.add('Errors occured due to overflow event:');
            errorList.addAll(overflowErrorList);
            ExceptionHandling.performExceptionHandling(null, 'ContactChangeEventTriggerHandler', errorList);
        }
    }
    
    //Process contact and related account record information
    private static void changeEventProcessor(List <ContactChangeEvent> redpointMonitorChanges, Boolean gapEvents, Set <string> recordIds){
        map<string, map <string,object>> processedRecords = new map<string, map <string,object>>();//Account Id & Account Data Map
        String confieldNames = '';
        String accfieldNames = '';
        Set <string> accountIds = new Set <string>();
        Map<Id, map <string,object>> processedContacts = new Map<Id, map <string,object>>();//Contact Id & Contact Record Map
        Map<id, contact> contactMap = new Map<id, contact>();//Queried Map
        
        if(!recordIds.isEmpty()){//For create change recordIds is empty, if future requirement is to sync lookup, formula field on contact then send recordids to get the details  
            List <Redpoint_K4K_Sync__mdt> redpointK4KFields = new List <Redpoint_K4K_Sync__mdt>();
            
            //For create/update change type only consider the Formula & Lookup fields to avoid looping through entire fieldset
            if(!gapEvents){
                redpointK4KFields.addAll(contactQueryFields);
            }else{
                redpointK4KFields.addAll(contactFields);
            }
            
            //Retrive the lookup & formula query field name (and all other fields for gap events)
            for (Redpoint_K4K_Sync__mdt queryField:redpointK4KFields){
                if(queryField.Field_Processing_Type__c == 'Lookup'){
                    confieldNames += queryField.Query_Field__c + ',';
                }else if(queryField.Field_Processing_Type__c == 'Formula' && !confieldNames.containsIgnoreCase(queryField.Query_Field__c)){
                    confieldNames += queryField.Query_Field__c + ',';
                }else if(gapEvents && queryField.Field_Processing_Type__c == 'Other'){//Dont include Key fields as those already included in query
                    confieldNames += queryField.Field_API_Name__c + ',';
                }
            }
            String contactQuery = 'Select ' + confieldNames + 'id, email, accountId, Klaviyo_Profile_ID__c from Contact';//phone
            contactQuery += ' where id in :recordIds AND (Email != null OR Klaviyo_Profile_ID__c != null)';//OR Phone != null 
            contactMap = new Map<id, contact>((List<Contact>)Database.query(contactQuery));
        }
        
        //For all change event types process each event for contact info
        for(ContactChangeEvent changeEvent :redpointMonitorChanges){
            //system.debug('changeEvent--'+changeEvent);
            if(changeEvent.get('AccountId') != null){//this can be removed when contactMap will be retrieved for create change
                accountIds.add((string)changeEvent.get('AccountId'));
            }
            
            //Process each record
            for(String recordId:changeEvent.ChangeEventHeader.getrecordIds()){
                if(changeEvent.ChangeEventHeader.getchangeType() == 'Update' && !contactMap.containsKey(recordId)){//If retrived contact map DO NOT contain the contact then proceed to the next contact without processing further update logic for Redpoint.
                    continue;
                }
                
                Contact queriedCon = new Contact();
                map <string,object>changedCon = new map <string,object>();
                changedCon.put('SF_Id',recordId);
                if(contactMap.containsKey(recordId)){//For create change contactMap is not retrieved
                    queriedCon = contactMap.get(recordId);
                    changedCon.put('Klaviyo_Profile_ID__c',queriedCon.Klaviyo_Profile_ID__c);
                    changedCon.put('AccountId',queriedCon.AccountId);
                    if(queriedCon.Klaviyo_Profile_ID__c == null){//If Klaviyo_Profile_ID__c is not available then send other keys
                        changedCon.put('email',queriedCon.Email);
                    }
                    accountIds.add(queriedCon.AccountId);
                }
                
                if(!processedContacts.containsKey(recordId)){
                    processedContacts.put(recordId, changedCon);
                }
                processedContacts.put(recordId, contactProcessor(processedContacts.get(recordId),changeEvent,queriedCon,gapEvents));
            }
        }
        
        //Process Account Info & Send payload to Workato webhook
        if(!processedContacts.isEmpty()){
            //Retrive account fields for query
            for (Redpoint_K4K_Sync__mdt queryField:accountFields){
                if(queryField.Field_Processing_Type__c == 'Lookup'){
                    accfieldNames += queryField.Query_Field__c + ',';
                }else if(queryField.Field_Processing_Type__c == 'Formula' && !accfieldNames.containsIgnoreCase(queryField.Query_Field__c)){
                    accfieldNames += queryField.Query_Field__c + ',';
                }else if(queryField.Field_Processing_Type__c == 'Other'){
                    accfieldNames += queryField.Field_API_Name__c + ',';
                }
            }
            
            string query = 'Select ' + accfieldNames + 'Klaviyo_Product_Usage__c,id from account where id in :accountIds';
            Map<id, account> accountMap = new Map<id, account>((List<Account>)Database.query(query));
            
            //Get account data
            for(id accId :accountMap.keyset()){
                if(!processedRecords.containsKey(accId)){
                    map <string,object> RecordInfo = new map <string,object> ();
                    processedRecords.put(accId, RecordInfo);
                }
                processedRecords.put(accId, payloadProcessor(processedRecords.get(accId), accountMap.get(accId))); 
            }
            
            //Send payload to Workato webhook
            List<RedpointCalloutHandler.RedpointRecordWrapper> payload = new List<RedpointCalloutHandler.RedpointRecordWrapper>();
            
			for(Id cId :processedContacts.keyset()){
                map<string,object> contactRecord = new map<string,object> ();
                contactRecord.putAll(processedContacts.get(cId));
                contactRecord.putAll(processedRecords.get((string)contactRecord.get('AccountId')));
                RedpointCalloutHandler.RedpointRecordWrapper contactWrapper = new RedpointCalloutHandler.RedpointRecordWrapper(contactRecord);
                payload.add(contactWrapper);
            }            

            system.enqueueJob(new RedpointCalloutHandler(payload));
        }
    }
    
    //Perform Contact Info Processing
    private static map <string,object> contactProcessor(map <string,object> con, ContactChangeEvent changeEvent, Contact queriedCon, Boolean gapEvents){
        List<string> changedFields = new List<string> ();
        if(changeEvent.ChangeEventHeader.getchangeType() == 'Update')changedFields = changeEvent.ChangeEventHeader.getchangedFields();
        
        for(Redpoint_K4K_Sync__mdt contactField:contactFields){
            Boolean eligibleCreateField = changeEvent.ChangeEventHeader.getchangeType() == 'Create' && changeEvent.get(contactField.Field_API_Name__c) != null;
            Boolean eligibleUpdateField = changeEvent.ChangeEventHeader.getchangeType() == 'Update' && changedFields.contains(contactField.Field_API_Name__c);
            
            Boolean monitoredFieldChanged = eligibleCreateField || eligibleUpdateField;
            Boolean monitoredFieldOrGapChange = gapEvents || monitoredFieldChanged;
            
            if(monitoredFieldChanged && contactField.Field_Processing_Type__c != 'Lookup' && contactField.Field_Processing_Type__c != 'Formula'){
                con.put(contactField.Redpoint_Property_Name__c, changeEvent.get(contactField.Field_API_Name__c));
            }else if(gapEvents && contactField.Field_Processing_Type__c != 'Lookup' && contactField.Field_Processing_Type__c != 'Formula'){
                con.put(contactField.Redpoint_Property_Name__c, queriedCon.get(contactField.Field_API_Name__c));
            }
            
            //Uncomment & add additional logic for formula field update on contact if in future requirement changes to Retrieve contact lookup or formula field
            /*else if(monitoredFieldOrGapChange && contactField.Field_Processing_Type__c == 'Lookup' && queriedCon.get(contactField.Field_API_Name__c) != null){//if lookup field is NOT null
                List<string> queryFieldSplitNames = contactField.Query_Field__c.split('\\.');
                con.put(contactField.Redpoint_Property_Name__c, queriedCon.getSObject(queryFieldSplitNames[0]).get(queryFieldSplitNames[1]));
            }else if(monitoredFieldOrGapChange && contactField.Field_Processing_Type__c == 'Lookup' && queriedCon.get(contactField.Field_API_Name__c) == null){//if lookup field is null
                con.put(contactField.Redpoint_Property_Name__c, null);
            }else if(monitoredFieldOrGapChange && contactField.Field_Processing_Type__c == 'Formula'){
                con.put(contactField.Redpoint_Property_Name__c, queriedCon.get(contactField.Query_Field__c));
            }*/           
        }
        return con;
    }
    
    //Perform Account Info Processing
    private static map <string,object> payloadProcessor(map <string,object> Record, Account a){
        for(Redpoint_K4K_Sync__mdt accountField :accountFields){
            Boolean nullLookupField = false;
            if(accountField.Field_Processing_Type__c == 'Lookup' && accountField.Field_API_Name__c == 'Redpoint_Formula_Sync_Widget__c'){
                nullLookupField = a.getSObject(accountField.Query_Field__c.split('\\.')[0]) == null;//[RGaokar 09/15/2023 SFDC-3613]
            }else if(accountField.Field_Processing_Type__c == 'Lookup' && accountField.Field_API_Name__c != 'Redpoint_Formula_Sync_Widget__c'){
                nullLookupField = a.get(accountField.Field_API_Name__c) == null;
            }
            
            if(accountField.Field_Processing_Type__c != 'Lookup' && accountField.Field_Processing_Type__c != 'Formula'){
                Record.put(accountField.Redpoint_Property_Name__c, a.get(accountField.Field_API_Name__c));
            }else if(accountField.Field_Processing_Type__c == 'Lookup' && !nullLookupField){
                List<string> queryFieldSplitNames = accountField.Query_Field__c.split('\\.');
                Record.put(accountField.Redpoint_Property_Name__c, a.getSObject(queryFieldSplitNames[0]).get(queryFieldSplitNames[1]));
            }else if(accountField.Field_Processing_Type__c == 'Formula'){
                Record.put(accountField.Redpoint_Property_Name__c, a.get(accountField.Query_Field__c));
            }
        }
        return Record; 
    }
}
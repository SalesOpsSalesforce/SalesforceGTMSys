//[RGaokar 11/25/2022 SFDC-1161 SF --> Redpoint: Batch job to handle Failed Redpoint Sync for SF Contacts & accounts]
//[RGaokar 02/06/2023 SFDC-1774 Changes to pass KPU lookup fields, passing Redpoint property names instead of SF fields api names to Workato Recipe]
//[RGaokar 04/11/2023 SFDC-2350  SF -> Redpoint Workato task reduction: Remove Workato loops by sending individual Contact payload instead of account & related contacts in payload]
public class RedpointFailedContactAccountSyncBatch implements database.Batchable<sObject>{
    // When scheduler runs the batch, then whereClause is set in start method of this batch
    // When the batch is called from Execute Anonymous Window, then where Clause is passed as parameter from Execute Anonymous Window, example: 'where id = \'003DS00000tU9I4YAK\' AND (email != null OR Klaviyo_Profile_ID__c != null)'
    string whereClause = null;
    // When scheduler runs pass runCasacadedBatch = true from scheduler, to call batches one after the other as follows: account & contact batch, lead batch 
    // When the batch is called from Execute Anonymous Window then set runCasacadedBatch = false
    Boolean runCasacadedBatch = false;
    private static List <Redpoint_K4K_Sync__mdt> accountFields = [Select Field_API_Name__c, Field_Processing_Type__c, Query_Field__c,Redpoint_Property_Name__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Account' AND Is_Active__c = true];
    private static List <Redpoint_K4K_Sync__mdt> contactFields = [Select Field_API_Name__c, Field_Processing_Type__c, Query_Field__c,Redpoint_Property_Name__c From Redpoint_K4K_Sync__mdt where Object__c  = 'Contact' AND Is_Active__c = true];
    
    public RedpointFailedContactAccountSyncBatch(string whereClause, Boolean runCasacadedBatch){// When the batch is called from Execute Anonymous Window then set runCasacadedBatch = false
        this.whereClause = whereClause;
        this.runCasacadedBatch = runCasacadedBatch;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        string query = queryCreator();
        if(whereClause == null){//If scheduler started this batch
            whereClause = 'where (Failed_Redpoint_Sync__c = true OR account.Failed_Redpoint_Sync__c = true)';
            whereClause += ' AND (email != null OR Klaviyo_Profile_ID__c != null)';//Any of the key available //OR phone != null 
        }
        if(string.isNotBlank(whereClause))query += whereClause;
        //system.debug('query--'+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<contact>scope){
        List<RedpointCalloutHandler.RedpointRecordWrapper> payload = new List<RedpointCalloutHandler.RedpointRecordWrapper>();
        List<Contact> updateContactList = new List<Contact>();
        List <String> errorList = new List <String> ();
        set<id>failedAccIds = new set<id>();
        
        //Iterate throught each contact to form redpoint payload
        for(Contact c:scope){
            map <string,object> contactRecord = new map <string,object> ();
            contactRecord.put('AccountId', c.AccountId);
            contactRecord.putAll(payloadProcessor(contactRecord, (Account)c.getSObject('Account')));
            contactRecord.put('SF_Id', c.Id);
            contactRecord.put('Klaviyo_Profile_ID__c', c.Klaviyo_Profile_ID__c);
            contactRecord.put('email', c.Email);
            
            RedpointCalloutHandler.RedpointRecordWrapper contactWrapper = new RedpointCalloutHandler.RedpointRecordWrapper(contactRecord);
            payload.add(contactWrapper);
            
            //Clear redpoint failed flag on account
            if(c.account.Failed_Redpoint_Sync__c == true)failedAccIds.add(c.AccountId);
            //Clear redpoint failed flag on contact
            if(c.Failed_Redpoint_Sync__c == true)updateContactList.add(new Contact(Id = c.Id, Failed_Redpoint_Sync__c = false));
        }
        
        //Send payload to Workato webhook
        system.enqueueJob(new RedpointCalloutHandler(payload));
        
        //Clear the redpoint failed flaged on account
        if(!failedAccIds.isEmpty()){
            List<Account> updateAccountList = new List<Account>();
            for(Id accId: failedAccIds){
                updateAccountList.add(new Account(Id = accId, Failed_Redpoint_Sync__c = false));
            }
            errorList.addAll(updateRecords(updateAccountList));
        }
        
        //Clear the redpoint failed flaged on contact
        if(!updateContactList.isEmpty()){
            errorList.addAll(updateRecords(updateContactList));
        }
        
        //Error handling if account or contact redpoint failed flag update fails
        if(!errorList.isEmpty()){
            ExceptionHandling.performExceptionHandling(null, 'RedpointFailedContactAccountSyncBatch', errorList);  
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        //Call RedpointFailedLeadSyncBatch if scheduler called this batch class
        if (runCasacadedBatch == true){
            RedpointFailedLeadSyncBatch redpointFailedldBatch = new RedpointFailedLeadSyncBatch(null);
            Database.executeBatch(redpointFailedldBatch,100);
        }
        
    }
    
    //Create query with contact & acount fields
    private static string queryCreator(){
        string query;
        query = 'Select id,';
        
        //Add Contact query fields to query
        for(Redpoint_K4K_Sync__mdt contactField:contactFields){
            if(contactField.Field_Processing_Type__c == 'Lookup'){
                query += contactField.Query_Field__c + ',';
            }else if(contactField.Field_Processing_Type__c == 'Formula' && !query.containsIgnoreCase(contactField.Query_Field__c)){
                query += contactField.Query_Field__c + ',';
            }else if(contactField.Field_Processing_Type__c != 'Formula' && contactField.Field_Processing_Type__c != 'Lookup'){
                query += contactField.Field_API_Name__c + ',';
            } 
        }
        
        //Add Account query fields to query
        for(Redpoint_K4K_Sync__mdt accountField:accountFields){
            if(accountField.Field_Processing_Type__c == 'Lookup'){
                query += 'account.' + accountField.Query_Field__c + ',';
            }else if(accountField.Field_Processing_Type__c == 'Formula' && !query.containsIgnoreCase('account.' + accountField.Query_Field__c)){
                query += 'account.' + accountField.Query_Field__c + ',';
            }else if(accountField.Field_Processing_Type__c != 'Formula' && accountField.Field_Processing_Type__c != 'Lookup'){
                query += 'account.' + accountField.Field_API_Name__c + ',';
            } 
        }
        
        query += 'Klaviyo_Profile_ID__c, account.Klaviyo_Product_Usage__c,account.Failed_Redpoint_Sync__c,Failed_Redpoint_Sync__c from Contact ';
        return query;  
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
            }else if(accountField.Field_Processing_Type__c == 'Lookup' && !nullLookupField){//if lookup field is NOT null
                List<string> queryFieldSplitNames = accountField.Query_Field__c.split('\\.');
                Record.put(accountField.Redpoint_Property_Name__c, a.getSObject(queryFieldSplitNames[0]).get(queryFieldSplitNames[1]));
            }else if(accountField.Field_Processing_Type__c == 'Lookup' && nullLookupField){//if lookup field is null
                Record.put(accountField.Redpoint_Property_Name__c, null);
            }else if(accountField.Field_Processing_Type__c == 'Formula'){
                Record.put(accountField.Redpoint_Property_Name__c, a.get(accountField.Query_Field__c));
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
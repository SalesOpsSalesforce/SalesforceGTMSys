public class KlaviyoAccountSync implements Queueable,Database.AllowsCallouts {
    /**
    * Sync CSM to Klaviyo Company Object in the main Klaviyo application
    * so it appears on the staff-side overview page
    */
    static String ENDPOINT = 'https://a.klaviyo.com/api/internal/company_salesforce_data';
    public static Boolean alreadyProcessed = false;
    private Set<Account> accountObjects = new Set<Account>();
    private String apiKey;
    private Map <String, String> userFields = new Map <String, String>();
    public static boolean isRunFromTAPBatch = false; // [06/30/2021 vr Created a static variable to avoid execution during Target Account Batch]
    
    private class SingleRequestMock implements HttpCalloutMock {
        /** Create a mock for HTTP responses from callouts. */
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody('{}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Initialize processor object
    public KlaviyoAccountSync(Set<Account> accountObjects) {
        this.accountObjects = accountObjects;
        this.apiKey = getKlaviyoApiKey();
        this.userFields.put('account_manager','SUPPORT_Account_Manager__c');
        this.userFields.put('onboarding_specialist','Onboarding_Specialist__c');
        this.userFields.put('sales_representative','OwnerId');
        this.userFields.put('channel_account_manager','RP_Referral_Partner_Account__c');
    }
    
    /*
    Utility Functions
    */
    
    // Retrieve all values and labels from an MDT object as a Map
    public static Map <String, String> getMetadataTypeCustomFieldMap(String mdtName) {
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(mdtName).getDescribe().fields.getMap();
        Map <String, String> fields = new Map <String, String>();
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            schema.describefieldresult dfield = sfield.getDescribe();
            if(dfield.getname().indexOf('__c') != -1){
                fields.put(dfield.getname(), dfield.getLabel());
            }
        }
        return fields;
    }
    
    // Retrieve all values and labels from given MDT record as a Map
    public static Map <String, String> getMetadataTypeValuesByLabel(String mdtName, String mdtLabel) {
        Map <String, String> fields = KlaviyoAccountSync.getMetadataTypeCustomFieldMap(mdtName);
        String queryFields = String.join(new List<String>(fields.keySet()), ',');
        //String queryFields = String.join(fields.keySet(),',');
        String soqlQuery = 'SELECT '+queryFields+' FROM '+mdtName+' WHERE Label=\''+mdtLabel+'\' LIMIT 1';
        // Retrieve custom fields from MDT
        Map<String,Object> fieldMap = new Map<String,Object>();
        fieldMap = Database.query(soqlQuery).get(0).getPopulatedFieldsAsMap();
        // Id is automatically retrieved so remove it
        Set<String> keys = fieldMap.keySet();
        keys.remove('Id');
        fieldMap.keySet().retainAll(keys);
        // Make different Map where the object labels are the keys (instead of the API names)
        Map<String,String> fieldMapToReturn = new Map<String,String>();
        for (String fieldName: fields.keySet()) {
            fieldMapToReturn.put(fields.get(fieldName),
                                 fieldMap.keySet().contains(fieldName) ? fieldMap.get(fieldName).toString() : '');
        }
        // Return map of field label keys to their set values
        return fieldMapToReturn;
    }
    
    public void processUpdatedAccounts(){
        /**
        * Provided User Ids, get all User Emails
        */
        
        // Get all account Ids and User Ids
        Set<String> objectFields = Schema.SObjectType.Account.fields.getMap().keySet();
        
        // Get all referral partner accounts
        Set<String> referralAccountIds = new Set<String>();
        for(Account updatedAccount : this.accountObjects)
        {
            for (String userKey: this.userFields.keySet()) { // Check each watched field
                if (objectFields.contains(this.userFields.get(userKey).toLowerCase()) &&
                    this.userFields.get(userKey) == 'RP_Referral_Partner_Account__c' &&
                    updatedAccount.get(this.userFields.get(userKey)) != null){ // value exists, add to list
                        referralAccountIds.add(updatedAccount.get('RP_Referral_Partner_Account__c').toString());
                    }
            }
        }
        // Query for all Accounts with Ids matching the referral partner account Id on the processed accounts
        Map<String,Account> referralAccounts = new Map<String,Account>(
            [SELECT Id,Channel_Manager__c FROM Account WHERE Id In :referralAccountIds]);
        
        // Get all user IDs from accounts and referral partner lookup
        Set<String> userIds = new Set<String>();
        for(Account updatedAccount : this.accountObjects)
        {
            for (String userKey: this.userFields.keySet()) { // Check each watched field
                if (objectFields.contains(this.userFields.get(userKey).toLowerCase()) && updatedAccount.get(this.userFields.get(userKey)) != null){
                    // special processing for CAM since it's a field on a related account
                    if (this.userFields.get(userKey) == 'RP_Referral_Partner_Account__c'){
                        // [12/08/2021 VRajapatruni] TP #97642 Fixing null pointer when channel manager is null
                        if(updatedAccount.get('RP_Referral_Partner_Account__c') <> null && referralAccounts.get(updatedAccount.get('RP_Referral_Partner_Account__c').toString()).get('Channel_Manager__c') <> null)
                            userIds.add(referralAccounts.get(updatedAccount.get('RP_Referral_Partner_Account__c').toString()).get('Channel_Manager__c').toString());
                    }
                    else{ 
                        userIds.add(updatedAccount.get(this.userFields.get(userKey)).toString()); // value exists, add to list
                    }
                }
            }
        }
        // Query for all Users with Ids matching user fields on the processed Accounts
        Map<String,User> accountUsers = new Map<String,User>(
            [SELECT Id,Email FROM User WHERE Id In :userIds]);
        
        //Send request for each updated account with User emails
        Map<String,String> updatedFields = new Map<String,String>();
        for(Account updatedAccount : this.accountObjects)
        {
            updatedFields.clear();
            for (String userKey: this.userFields.keySet()) { // Check each watched field
                if (objectFields.contains(this.userFields.get(userKey).toLowerCase()) && updatedAccount.get(this.userFields.get(userKey)) != null){
                    // special processing for CAM since it's a field on a related account
                    if (this.userFields.get(userKey) == 'RP_Referral_Partner_Account__c'){
                        // [12/08/2021 VRajapatruni] TP #97642 Fixing null pointer when channel manager is null
                        if(updatedAccount.get('RP_Referral_Partner_Account__c') <> null && referralAccounts.get(updatedAccount.get('RP_Referral_Partner_Account__c').toString()).get('Channel_Manager__c') <> null)
                            updatedFields.put(userKey, accountUsers.get(referralAccounts.get(updatedAccount.get('RP_Referral_Partner_Account__c').toString()).get('Channel_Manager__c').toString()).Email); // value exists, add to list
                    }
                    else{
                        updatedFields.put(userKey, accountUsers.get(updatedAccount.get(this.userFields.get(userKey)).toString()).Email); // value exists, add to list
                    }
                }
            }
            
            if(updatedAccount.get('Product_Klaviyo_Account_ID__c') <> null){
                syncAccountManager(updatedAccount.get('Product_Klaviyo_Account_ID__c').toString(), updatedFields);
            }
        }
    }
    
    public void syncAccountManager(String klaviyoAccountId, Map<String,String> updatedFields) {
        /**
        * Provided a Klaviyo Account Id and Account Manager's Email, synchronize the data in Klaviyo to match.
        */
        if (Test.isRunningTest()) { // ensure on tests we do not do any callouts
            Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        }
        
        HttpRequest request = new HttpRequest();
        request.setMethod('PUT');
        request.setEndpoint(KlaviyoAccountSync.ENDPOINT);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setTimeout(5000);
        
        if (String.isNotEmpty(this.apiKey)) {
            String payload = 'api_key=' + this.apiKey + '&company_id=' + klaviyoAccountId;
            for (String userKey: this.userFields.keySet()) { // Check each watched field
                if (updatedFields.keySet().contains(userKey)){
                    payload += '&'+ EncodingUtil.urlEncode(userKey, 'UTF-8') + 
                            '=' + EncodingUtil.urlEncode(updatedFields.get(userKey), 'UTF-8'); // value changed, add request params
                }
            }
            request.setBody(payload);
            
            HTTP http = new HTTP();
            HTTPResponse res;
            try {
                res = http.send(request);
                System.debug('Method: "' + request.getMethod() + '\n' + '"' +
                             'Endpoint: "' + request.getEndpoint() + '\n' + '"' +
                             'Content-Type Header: "' + request.getHeader('Content-Type') + '\n' + '"' +
                             'Body: "' + request.getBody() + '"');
                System.debug(res.toString());
            } catch (System.CalloutException e) {
                System.debug('Method: "' + request.getMethod() + '\n' + '"' +
                             'Endpoint: "' + request.getEndpoint() + '\n' + '"' +
                             'Content-Type Header: "' + request.getHeader('Content-Type') + '\n' + '"' +
                             'Body: "' + request.getBody() + '"');
                System.debug('ERROR:' + e);
            }
        }
    }
    
    private String getKlaviyoApiKey() {
        /**
        * Get the API key for connecting to Klaviyo's API.
        */
        //List<User> users = [SELECT Name, Email, Klaviyo_API_Key__c FROM User WHERE Profile.Name = 'Salesforce Admin - No Customize App' AND IsActive = true AND Klaviyo_API_Key__c != NULL LIMIT 1];
        List<User> users = [SELECT Name, Email, Klaviyo_API_Key__c FROM User WHERE Profile.Name = 'Operations' AND IsActive = true AND Klaviyo_API_Key__c != NULL LIMIT 1];
        // [VRajapatruni 12/30/2021 TP #99731] Return API Key only for Production transactions
        // if (users.isEmpty()) { // no users with an API key could be found
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox; // TP #99731
        if (users.isEmpty() || runningInASandbox){ // no users with an API key could be found or (TP #99731) running in a non-production/sandbox instance. 
            return null;
        } else{ 
            return users.get(0).Klaviyo_API_Key__c;
        }
    }
    
    // Send SObject off for processing
    public void execute(QueueableContext context) {
        try {
            processUpdatedAccounts();
        } catch (Exception ex) {
            System.debug('Exception: "' + ex.getMessage() +
                         '" of type "' + ex.getTypeName() +
                         '" caused by "' + ex.getCause() +
                         '" on line number ' + ex.getLineNumber() + '\n' +
                         'Stack Trace: ' + ex.getStackTraceString());
        }
    }
    
    @InvocableMethod(label='KlaviyoAccountSync' description='Sync CSM to Klaviyo Company Object in the main Klaviyo application so it appears on the staff-side overview page' category='Account')
    public static void invocableKlaviyoAccountSync(List<Account> acctList) {
        /*
        *   Args:
        *       accountKID: account.Product_Klaviyo_Account_ID__c
        *       newCSM: account.SUPPORT_Account_Manager__c
        */
        Account acct = acctList.get(0);
        
        Set<Account> accountsToSync = new Set<Account>();
        if ((acct.SUPPORT_Account_Manager__c != null || acct.Onboarding_Specialist__c != null ||
            acct.RP_Referral_Partner_Account__r != null || acct.OwnerId != null) && 
            acct.Product_Klaviyo_Account_ID__c != null) {
            try {
                accountsToSync.add(acct);
                KlaviyoAccountSync klAccountSync = new KlaviyoAccountSync(accountsToSync);
                //[06/30/2021 vr] Added the if filter while 228 and 229 are already existing lines of code
                if(KlaviyoAccountSync.isRunFromTAPBatch == false){
                    ID jobID = System.enqueueJob(klAccountSync);
                    System.debug('Queued new job with jobID' + jobID);
                }
            } catch (Exception ex) {
                System.debug('Exception: "' + ex.getMessage() +
                             '" of type "' + ex.getTypeName() +
                             '" caused by "' + ex.getCause() +
                             '" on line number ' + ex.getLineNumber() + '\n' +
                             'Stack Trace: ' + ex.getStackTraceString());
            }
        }
    }
}
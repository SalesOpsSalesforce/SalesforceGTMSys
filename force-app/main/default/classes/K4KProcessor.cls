public class K4KProcessor implements Queueable, Database.AllowsCallouts {
    // Process a list of accounts for K4K based on the fields in
    // Custom Metadata Type K4K_Account_Field__mdt

    public static Boolean alreadyProcessed = false;
    private Set<SObject> SObjects = new Set<SObject>();
    private String objectType = '';
    private ApexKlaviyoAPI klaviyoClient;
    private String awsApiKey;
    private K4KAwsApi awsClient;
    private String zendeskApiToken;
    private String targetProcessAPIKey;

    // Initialize processor object
    public K4KProcessor(Set<SObject> SObjects) {
        this.SObjects = SObjects;
        initializeAPI();
    }

    public void initializeAPI(){
        // Get API creds and initialize client
        // Get current K4K API key set
        Map <String, String> k4kSettings = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Code_Setting__mdt','K4K Settings Config');
        String k4kApiKeySet = k4kSettings.get('API Key Set Toggle');
        // Retrieve keys for current key set
        Map <String, String> apiKeys = GeneralUtils.getMetadataTypeValuesByLabel('KlaviyoAPIAccount__mdt',k4kApiKeySet);
        this.awsApiKey = apiKeys.get('K4KAwsSyncApiKey');
        this.klaviyoClient = new ApexKlaviyoAPI(apiKeys);
        this.awsClient = new K4KAwsApi(apiKeys);
        this.zendeskApiToken = apiKeys.get('ZendeskAPIKey');
        this.targetProcessAPIKey = apiKeys.get('TargetProcessAPIKey');
    }

    // ==========  K4K-specific processing logic for SObjects

    // Perform processing if SObject is a Lead
    public void processLead(){
        try {
            // Retrieve preset fields on MDT from Lead Object
            // Get K4K Lead Fields we're watching for from entry on the K4L Lead Field custom Metadata Type
            Map <String, String> k4kLeadFields = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Lead_Field__mdt','K4K_M_v1');
            // Clean missing/incorrect keys and Id from field map
            k4kLeadFields = GeneralUtils.cleanMetadataMap(k4kLeadFields, this.objectType);
            // Get watched fields from list of Leads
            List<Map<String,Object>> updatedLeads = new List<Map<String,Object>>();
            // Convert SObject Set to correct Set type
            Set<Lead> updatedLeadRecords = new Set<Lead>();
            for(SObject item : this.SObjects){
                updatedLeadRecords.add((Lead)item);
            }
            // Get all account Ids and csm/obs User Ids
            Set<String> partnerAccountIds = new Set<String>();
            for(Lead updatedLead : updatedLeadRecords){
                partnerAccountIds.add(updatedLead.Referral_Partner_Account__c);
            }
            // Query for all Accounts with Ids matching partner fields on the processed Leads
            Map<ID,Account> leadPartnerAccounts = new Map<ID,Account>(
                [SELECT Id,Name FROM Account WHERE Id In :partnerAccountIds]);

            // Loop through Leads and assemble properties
            Object fieldValue;
            for(Lead updatedLead : updatedLeadRecords)
            {
                Map<String,Object> properties = new Map<String,Object>();
                properties.put('$email',updatedLead.get('Email'));
                for(String key : k4kLeadFields.keySet())
                {
                    fieldValue = updatedLead.get(k4kLeadFields.get(key));
                    // Handling for if the field is null
                    if (fieldValue == null) {continue;}
                    else if (key == 'K4KReferralAgencyPartner') {
                        // If trying to get referall partner account, get the name of that account
                        // Handling for if that account doesn't exist in the account list
                        if (leadPartnerAccounts.get(fieldValue.toString()) != null){
                            properties.put(key,leadPartnerAccounts.get(fieldValue.toString())?.get('Name'));
                        }
                    }
                    else if (key == 'K4KPreviousEmailPlatforms' ){
                        // If the property is a list of email platforms, do some special processing
                        List<String> previousEmailPlatforms = ((String)fieldValue).split(' ; ');
                        // If the source exists, grab it source
                        if (((String)fieldValue).split('- ').size() > 1){
                            properties.put('K4KPreviousEmailPlatformsSource',((String)fieldValue).split('- ')[1]);
                            // Remove the last item (the source) from the list of platforms
                            previousEmailPlatforms.remove(previousEmailPlatforms.size() - 1);
                        }
                        // Strip the semicolon from the last value
                        previousEmailPlatforms[previousEmailPlatforms.size()-1] = previousEmailPlatforms[previousEmailPlatforms.size()-1].split(' ;')[0];
                        properties.put(key,previousEmailPlatforms);
                    }
                    else {
                        properties.put(key,fieldValue);
                    }
                }
                updatedLeads.add(properties);
            }
            // Build Identify request for each Lead in list
            List<Map<String,Object>> leadPayloads = new List<Map<String,Object>>();
            for(Map<String,Object> updatedLead : updatedLeads)
            {
                leadPayloads.add(this.klaviyoClient.buildIdentifyPayload(updatedLead));
            }
            //System.debug(leadPayloads);
            this.awsClient.setLeadPayloads(leadPayloads);
            this.awsClient.sync();
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
    }

    // Perform processing if SObject is an Account
    public void processAccount(){
        try {
            // Retrieve preset fields on MDT from Account Object
            // Get K4K Account Fields we're watching for from entry on the K4L Account Field custom Metadata Type
            Map <String, String> k4kAccountFields = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Account_Field__mdt','K4K_CS_v1');
            // Clean missing/incorrect keys and Id from field map
            k4kAccountFields = GeneralUtils.cleanMetadataMap(k4kAccountFields, this.objectType);

            // Convert SObject Set to correct Set type
            Set<Account> updatedAccounts = new Set<Account>();
            for(SObject item : this.SObjects){
                updatedAccounts.add((Account)item);
            }
            // Get all account Ids and csm/obs User Ids
            Set<String> userIds = new Set<String>();
            Set<String> accountIds = new Set<String>();
            Set<String> partnerAccountIds = new Set<String>();
            for(Account updatedAccount : updatedAccounts){
                userIds.add(updatedAccount.SUPPORT_Account_Manager__c);
                userIds.add(updatedAccount.Onboarding_Specialist__c);
                userIds.add(updatedAccount.Channel_Manager__c);
                accountIds.add(updatedAccount.Id);
                partnerAccountIds.add(updatedAccount.Platform_Partner_Account__c);
                partnerAccountIds.add(updatedAccount.Tech_Partner_Account__c);
                partnerAccountIds.add(updatedAccount.Experts_Partner_Account__c);
            }
            userIds = GeneralUtils.removeBlanksFromSet(userIds);
            accountIds = GeneralUtils.removeBlanksFromSet(accountIds);
            partnerAccountIds = GeneralUtils.removeBlanksFromSet(partnerAccountIds);

            // Query for all Users with Ids matching csm/obs/cam fields on the processed Accounts
            Map<ID,User> accountUsers = new Map<ID,User>(
                [SELECT Id,Email FROM User WHERE Id In :userIds]);

            // Query for all Accounts with Ids matching partner fields on the processed Accounts
            Map<ID,Account> accountPartnerAccounts = new Map<ID,Account>(
                [SELECT Id,Name FROM Account WHERE Id In :partnerAccountIds]);

            // Query for all Contacts with Ids matching csm/obs fields on the processed Accounts
            List<Contact> accountContacts = new List<Contact>(
                [SELECT Account.Id,Email FROM Contact WHERE Account.Id In :accountIds]);

            // Get watched fields from list of Accounts
            // Loop through Contacts related to Accounts
            List<Map<String,Object>> updatedAccountsByContact  = new List<Map<String,Object>>();
            Object fieldValue;
            for(Contact accountContact : accountContacts)
            {
                Map<String,Object> properties = new Map<String,Object>();
                // Get Contact email address
                properties.put('$email',accountContact.get('Email'));
                // Get Account fields for contact
                for(Account updatedAccount : updatedAccounts)
                {
                    if (updatedAccount.get('Id') == accountContact.get('AccountId')) {
                        for(String key : k4kAccountFields.keySet())
                        {
                            fieldValue = updatedAccount.get(k4kAccountFields.get(key));
                            // Handling for if the field is null
                            if (fieldValue == null) {continue;}
                            if (key == 'K4KOBS' || key == 'K4KManagedBy' || key == 'K4KChannelAccountManager') {
                                // If trying to get CSM/OBS/CAM, get CSM/OBS/CAM email for Account for Contact
                                // Handling for if that person doesn't exist in the user list
                                if (accountUsers.get(fieldValue.toString()) != null){
                                    properties.put(key,accountUsers.get(fieldValue.toString())?.get('Email'));
                                }
                            }
                            else if (key == 'K4KReferralTechPartner' || key == 'K4KReferralPlatformPartner' || key == 'K4KPartnerManager') {
                                // If trying to get referall partner account, get the name of that account
                                // Handling for if that account doesn't exist in the account list
                                if (accountPartnerAccounts.get(fieldValue.toString()) != null){
                                    properties.put(key,accountPartnerAccounts.get(fieldValue.toString())?.get('Name'));
                                }
                            }
                            else {
                                properties.put(key,fieldValue);
                            }
                        }
                        break;
                    }
                }
                updatedAccountsByContact.add(properties);
            }
            // Build Identify request for each Account in list
            List<Map<String,Object>> accountPayloads = new List<Map<String,Object>>();
            for(Map<String,Object> updatedAccountByContact : updatedAccountsByContact)
            {
                accountPayloads.add(this.klaviyoClient.buildIdentifyPayload(updatedAccountByContact));
            }
            //System.debug(accountPayloads);
            this.awsClient.setAccountPayloads(accountPayloads);
            this.awsClient.sync();
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
    }

    // Perform processing if SObject is a Customer Onboarding
    public void processCustomerOnboarding(){
        try {
            // Retrieve preset fields on MDT from CustomerOnboarding Object
            // Get K4K CustomerOnboarding Fields we're watching for from entry on the K4L CustomerOnboarding Field custom Metadata Type
            Map <String, String> k4kCustomerOnboardingFields = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Customer_Onboarding_Field__mdt','K4K_OB_v1');
            // Clean missing/incorrect keys and Id from field map
            k4kCustomerOnboardingFields = GeneralUtils.cleanMetadataMap(k4kCustomerOnboardingFields, this.objectType);
            // Convert SObject Set to correct Set type
            Set<Customer_Onboarding__c> customerOnboardingRecords = new Set<Customer_Onboarding__c>();
            Set<String> contactIds = new Set<String>();
            for(SObject item : this.SObjects){
                customerOnboardingRecords.add((Customer_Onboarding__c)item);
                contactIds.add(((Customer_Onboarding__c)item).Main_User__c);
                contactIds.add(((Customer_Onboarding__c)item).Economic_Buyer__c);
            }

            // Query for all Contacts with Ids matching main user and buyer fields on the processed Customer Onboardings
            Map<ID, Contact> onboardingContacts = new Map<ID, Contact>(
                [SELECT Id,Email FROM Contact WHERE Id In :contactIds]);

            // Get watched fields from list of CustomerOnboardings
            List<Map<String,Object>> customerOnboardingPayloads = new List<Map<String,Object>>();

            // Get current unix time in case timestamp isn't set yet
            Datetime dt = Datetime.now();
            Long currentTime = dt.getTime()/1000;

            for(Customer_Onboarding__c customerOnboardingRecord : customerOnboardingRecords)
            {
                Map<String,Object> eventInfo = new Map<String,Object>();
                // One set each of properties and customer properties for the primary user and one for the decision maker
                Map<String,Object> customerProperties = new Map<String,Object>();
                Map<String,Object> customerProperties2 = new Map<String,Object>();
                Map<String,Object> properties = new Map<String,Object>();
                Map<String,Object> properties2 = new Map<String,Object>();

                Map<String,Map<String,Object>> dataSet = new Map<String,Map<String,Object>>();
                Map<String,Map<String,Object>> dataSet2 = new Map<String,Map<String,Object>>();
                // Set email and role on both contacts
                if (onboardingContacts.get((String)customerOnboardingRecord.get('Main_User__c')) != null) {
                    customerProperties.put('$email',onboardingContacts.get((String)customerOnboardingRecord.get('Main_User__c')).get('Email'));
                } else {
                    // if no Main_User__c is set, use a blank email so nothing's tracked
                    customerProperties.put('$email', null);
                }
                if (onboardingContacts.get((String)customerOnboardingRecord.get('Economic_Buyer__c')) != null) {
                    customerProperties2.put('$email',onboardingContacts.get((String)customerOnboardingRecord.get('Economic_Buyer__c')).get('Email'));
                } else {
                    // if no Economic_Buyer__c is set, use a blank email so nothing's tracked
                    customerProperties2.put('$email', null);
                }
                properties.put('OnboardingRecordRole','Main_User__c');
                properties2.put('OnboardingRecordRole','Economic_Buyer__c');

                for(String key : k4kCustomerOnboardingFields.keySet()){
                    customerProperties.put(key,customerOnboardingRecord.get(k4kCustomerOnboardingFields.get(key)));
                    customerProperties2.put(key,customerOnboardingRecord.get(k4kCustomerOnboardingFields.get(key)));
                }

                Long eventTime = currentTime;
                // Process as Completed Onboarding or Cancelled Onboarding based on current status
                if (customerOnboardingRecord.get('Status__c') == 'Onboarding Completed') {
                    // If the completed onboarding timestamp exists, use it
                    if (customerOnboardingRecord.get('Onboarding_Completed_Start_Date_Time__c') != null) {
                        eventTime = GeneralUtils.datetimeToUnix((Datetime)customerOnboardingRecord.get('Onboarding_Completed_Start_Date_Time__c'));
                    }
                    eventInfo.put('event','Completed Onboarding');
                    customerProperties.put('K4KCompletedOnboardingDate',eventTime);
                    customerProperties2.put('K4KCompletedOnboardingDate',eventTime);
                } else if (customerOnboardingRecord.get('Status__c') == 'Onboarding Canceled') {
                    // If the canceled onboarding timestamp exists, use it
                    if (customerOnboardingRecord.get('Onboarding_Canceled_Start_Date_Time__c') != null) {
                        eventTime = GeneralUtils.datetimeToUnix((Datetime)customerOnboardingRecord.get('Onboarding_Canceled_Start_Date_Time__c'));
                    }
                    eventInfo.put('event','Canceled Onboarding');
                    customerProperties.put('K4KCanceledOnboardingDate',eventTime);
                    customerProperties2.put('K4KCanceledOnboardingDate',eventTime);
                }

                eventInfo.put('time',eventTime);
                dataSet.put('eventInfo',eventInfo);
                dataSet2.put('eventInfo',eventInfo);
                dataSet.put('customerProperties',customerProperties);
                dataSet2.put('customerProperties',customerProperties2);
                dataSet.put('properties',properties);
                dataSet2.put('properties',properties2);
                customerOnboardingPayloads.add(dataSet);
                customerOnboardingPayloads.add(dataSet2);
            }
            // Build Track request for each Customer Onboarding in list
            List<Map<String,Object>> customerOnboardingTrackPayloads = new List<Map<String,Object>>();
            for(Map<String,Object> customerOnboardingPayload : customerOnboardingPayloads)
            {
                // Collect properties and customer_properties for the event payload
                Map<String,Object> eventInfo = (Map<String,Object>)customerOnboardingPayload.get('eventInfo');
                Map<String,Object> customerProperties = (Map<String,Object>)customerOnboardingPayload.get('customerProperties');
                Map<String,Object> properties = (Map<String,Object>)customerOnboardingPayload.get('properties');
                customerOnboardingTrackPayloads.add(
                    klaviyoClient.buildTrackPayload((String)eventInfo.get('event'), customerProperties, properties, (Long)eventInfo.get('time'))
                );
            }
            this.awsClient.setCustomerOnboardingPayloads(customerOnboardingTrackPayloads);
            this.awsClient.sync();
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
    }

    // Perform processing if SObject is a Case
    //[RGaokar 01/10/2022 TP #95106]Commented processCase method as the K4KCaseTrigger (zendesk callout for 'Manual_Review_Alert' case) is no longer needed.
   /* public void processCase(){
        // Initialize Case field strings
        String klaviyoAccountId;
        String zendeskTicketId;
        // Initialize query strings
        String questionnaireLinkField = 'Deliverability_Questionnaire_Link__c';
        String queryFields = 'Id,'+questionnaireLinkField;
        String sObjType = 'Opportunity';
        String whereFilterKey = 'ACCOUNT_Klaviyo_Account_ID__c';
        String whereFilterValue;
        String soqlQuery;
        // Initialize request strings
        String requestUrl;
        String requestBody;
        String questionnaireLinks;
        // Convert SObject Set to correct Set type
        Set<Case> caseObjects = new Set<Case>();
        for(SObject item : this.SObjects){
            caseObjects.add((Case)item);
        }
        // For each created/updated Case, gather/package deliverability questionnaire links and add ZD ticket comment
        for(Case updatedCase : caseObjects)
        {
            // Nullify request params to avoid accidentlal cross-contamination
            requestUrl = null;
            requestBody = null;
            try {
                // (Re)initialize strings for current Case
                klaviyoAccountId = updatedCase.get('Klaviyo_Account_ID__c').toString();
                zendeskTicketId = updatedCase.get('Zendesk_Support_Ticket_ID__c').toString();
                // Build query for security questionnare google doc by getting all related Opps with deliverability questionnaire links
                // TODO: make this more generic and remove to own function
                whereFilterValue = klaviyoAccountId;
                soqlQuery = 'SELECT '+queryFields+' FROM '+sObjType+' WHERE '+whereFilterKey+'=\''+whereFilterValue+'\' AND '+questionnaireLinkField+' <> NULL';
                Map<String,Object> fieldMap = new Map<String,Object>();
                List<SObject> queryResults = Database.query(soqlQuery);
                questionnaireLinks = '';

                for(SObject result : queryResults)
                {
                    fieldMap = result.getPopulatedFieldsAsMap();
                    questionnaireLinks += 'Deliverability Questionnaire: '+fieldMap.get(questionnaireLinkField)+' | ';
                }

                requestUrl = 'https://klaviyo.zendesk.com/api/v2/tickets/'+zendeskTicketId+'.json';
                requestBody = '{"ticket": {"comment": { "body": "'+questionnaireLinks+'", "public": false }}}';
            } catch (Exception ex) {
                GeneralUtils.logException(ex);
            }
            // Add comment to Zendesk Ticket if google doc link exists
            if (requestBody!=null) {
                // Build request
                HttpRequest request = new HttpRequest();
                request.setTimeout(5000);
                request.setMethod('PUT');
                request.setEndpoint(requestUrl);
                request.setHeader('Content-Type', 'application/json');
                // Zendesk API token is Authorization: Basic base64({email_address}/token:{api_token})
                //  we just store the already b64 encoded version for simplicity.
                request.setHeader('Authorization', 'Basic '+this.zendeskApiToken);
                request.setBody(requestBody);
                // Send request
                HTTP http = new HTTP();
                HTTPResponse res;
                try {
                    res = http.send(request);
                    GeneralUtils.logRequest(request, res);
                } catch (System.CalloutException ex) {
                    GeneralUtils.logRequestException(request, ex);
                }
            }
        }
    }*/

    // Perform processing if SObject is a SA Request
    public void processSaRequest(){
        // Get Id from each SA Request SObject
        List<String> requestBodies = new List<String>();
        try {
            for(SObject saRequestRecord : this.SObjects){
                Solution_Architect_Request__c saRequest = (Solution_Architect_Request__c)saRequestRecord;
                Map<String,Object> fieldMap = saRequest.getPopulatedFieldsAsMap();
                requestBodies.add('{' +
                    '"sa_request_ids": ["' + (String)fieldMap.get('Id') + '"]' +
                '}');
            }
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
        System.debug(requestBodies);
        // Send SA Request ID to AWS for further processing
        String requestUrl = 'https://xr388iddo0.execute-api.us-east-2.amazonaws.com/production/sa-request';
        for(String requestBody : requestBodies){
            // Build request
            HttpRequest request = new HttpRequest();
            request.setTimeout(5000);
            request.setMethod('POST');
            request.setEndpoint(requestUrl);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('x-api-key', this.awsApiKey);
            request.setBody(requestBody);
            // Send request
            HTTP http = new HTTP();
            HTTPResponse res;
            try {
                res = http.send(request);
                GeneralUtils.logRequest(request, res);
            } catch (System.CalloutException ex) {
                GeneralUtils.logRequestException(request, ex);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Execution functions

    // ========== Queueable functions
    // Send SObject off for processing depending on type
    public void execute(QueueableContext context) {
        // Check if the type is one we can process or null
        try{ // Get the SObject type of the set
            this.objectType = GeneralUtils.getSobjectTypeFromSet(this.SObjects);
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
        // Use SObject type to determine processor method
        if (this.objectType == 'Account') {
            processAccount();
        } else if (this.objectType == 'Case') {
            //processCase();//[RGaokar 01/10/2022 TP #95106]Commented processCase method as the K4KCaseTrigger (zendesk callout for 'Manual_Review_Alert' case) is no longer needed.
        } else if (this.objectType == 'Lead') {
            processLead();
        } else if (this.objectType == 'Customer_Onboarding__c') {
            processCustomerOnboarding();
        } else if (this.objectType == 'Solution_Architect_Request__c') {
            processSaRequest();
        }
    }

    // ========== Invocable functions
    @InvocableMethod(label='K4KProcessor' description='Run K4K processing code on a specific record' category='K4K')
    public static void invocableK4KProcessor(List<SObject> sObjectList) {
        //  Args:
        //    sObjectList: list of arbitrary type sobjects for processing
        try {
            K4KProcessor k4kClient = new K4KProcessor(new Set<SObject>(sObjectList));
            ID jobID = System.enqueueJob(k4kClient);
            System.debug('Queued new job with jobID' + jobID);
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
    }
}
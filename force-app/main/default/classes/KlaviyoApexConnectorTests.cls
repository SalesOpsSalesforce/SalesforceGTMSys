@isTest
private class KlaviyoApexConnectorTests {

    // #########################################################################
    // Apex-based Klaviyo API wrapper.

    // Tests the ApexKlaviyoAPI APEX class.
    static testMethod void testApexKlaviyoAPI() {
        // Runs a series of mock Apex-Klaviyo Track/Identify requests

        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Add a Salesforce Account record ID (that has associated Contact records)
        // that you'd like to use for this test
        Integer timestamp = Datetime.now().getTime().intValue() / 1000;
        String event = 'Apex Klaviyo API Wrapper Test Event';
        Map < String, Object > customerProperties = new Map < String, Object > ();
        Map < String, Object > properties = new Map < String, Object > ();
        Map <String, String> apiKeys = GeneralUtils.getMetadataTypeValuesByLabel('KlaviyoAPIAccount__mdt','TestAccount'); // Test Account
        ApexKlaviyoAPI klaviyoClient = new ApexKlaviyoAPI(apiKeys);
        // Test that the ApexKlaviyoAPI class's identify method works.
        klaviyoClient.identify(klaviyoClient.buildIdentifyPayload(customerProperties));
        // Test that the ApexKlaviyoAPI class's track method works with all params.
        klaviyoClient.track(klaviyoClient.buildTrackPayload(event, customerProperties, properties, timestamp));
        // Test that the ApexKlaviyoAPI class's track method works with just api key, event name, customer properties, and event properties.
        klaviyoClient.track(klaviyoClient.buildTrackPayload(event, customerProperties, properties));
        // Test that the ApexKlaviyoAPI class's track method works with just api key, event name, customer properties, and timestamp.
        klaviyoClient.track(klaviyoClient.buildTrackPayload(event, customerProperties, timestamp));
        // Test that the ApexKlaviyoAPI class's track method works with just api key, event name, and customer properties.
        klaviyoClient.track(klaviyoClient.buildTrackPayload(event, customerProperties));
        Test.stopTest();
    }

    // #########################################################################
    // Test KAC GeneralUtils.

    static testMethod void testDateStringToUnix(){
        // Start test
        Test.startTest();
        Long testTime = GeneralUtils.dateStringToUnix('2021-03-26T00:00:00.000');
        Test.stopTest();
    }

    static testMethod void testDatetimeToUnix(){
        // Start test
        Test.startTest();
        Long testTime = GeneralUtils.datetimeToUnix(DateTime.newInstance(2021, 3, 26, 0, 0, 0));
        Test.stopTest();
    }

    static testMethod void testCreateNewTpRequester(){
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new generalUserIdTpResponseMock());
        Map <String, String> apiKeys = GeneralUtils.getMetadataTypeValuesByLabel('KlaviyoAPIAccount__mdt','TestAccount'); // Test Account
        ApexKlaviyoAPI klaviyoClient = new ApexKlaviyoAPI(apiKeys);
        GeneralUtils.createNewTpRequester(klaviyoClient, 'testKey', 'Test', 'Person', 'test@test.com');
        Test.stopTest();
    }

    // #########################################################################
    // Test KAC interfaces.

    // ####################
    // Test Triggers
    // Tests the K4KCaseTrigger APEX trigger.
    // [RGaokar 01/10/2022 TP #95106]Commented testmethod related to processCase method 
    // as the K4KCaseTrigger (zendesk callout for 'Manual_Review_Alert' case) is no longer needed.
    /*static testMethod void testK4KCaseTrigger() {
        // Test the trigger on a Case for insert & update runs successfully.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());

        // Create new account to tie to case
        Account acct = new Account(
            Name='### Test Account ###',
            Product_Klaviyo_Account_ID__c = 'test'
        );
        // Create new supportCase
        Case supportCase = new Case();
        supportCase.AccountId = acct.Id;
        // Required Fields
        supportCase.Status = 'New';
        supportCase.Origin = 'Phone';
        // Record type needed for K4K trigger
        Id manualReviewTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Manual_Review_Alert').getRecordTypeId();
        supportCase.RecordTypeId = manualReviewTypeId;
        supportCase.Klaviyo_Account_ID__c = 'test';
        supportCase.Zendesk_Support_Ticket_ID__c = 'test';
        // Test inserting the supportCase
        insert supportCase;
        System.assert(K4KProcessor.alreadyProcessed == true);
        K4KProcessor.alreadyProcessed = false;
        // Test updating supportCase
        update supportCase;
        System.assert(K4KProcessor.alreadyProcessed == true);

        Test.stopTest();

    }*/

    // ####################
    // Test Scheduleables

    // Tests the schedulableable part of GeneralUtils.
    static testmethod void testGeneralUtilsSchedule() {
        // Test scheduling code
        Test.startTest();
        GeneralUtils.setup();
        String cronJobName =  'KAC Monitor Job test';
        List<CronTrigger> cts = [
            SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :cronJobName
        ];
        System.assertEquals(cts.size(), 1);
        GeneralUtils.clearPreviousJobs();

        // Test syncing event
        GeneralUtils.syncRecentlyModifiedRecords();
        Test.stopTest();
    }

    // ####################
    // Test Interfaces

    // Tests the K4KInterface invocableK4KProcessor invocable method.
    static testMethod void testInvocableK4KProcessor() {
        //
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());

        // Create a test user to attach to required fields
        User testUser = createTestUser();
        // Create new account to tie to opportunity
        Account testAccount = createTestAccount();
        // Create opportunity for onboarding object
        Opportunity testOpportunity = createTestOpportunity(testAccount);
        // Create new customerOnboarding
        Customer_Onboarding__c testCustomerOnboarding = createTestCustomerOnboarding(testOpportunity);
        // Create new SA request
        Solution_Architect_Request__c testSaRequest = createTestSaRequest(testCustomerOnboarding, testUser);

        K4KInterface.invocableK4KProcessor(new List<SObject>{testSaRequest});

        // Remove this after deprecating the one in K4KProcessor
        K4KProcessor.invocableK4KProcessor(new List<SObject>{testSaRequest});

        //System.assert(K4KProcessor.processSaRequest.called_once);

        Test.stopTest();
    }

    // Tests the K4KInterface manualRun method.
    static testMethod void testManualRun() {
        //
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());

        String fromClause = '';
        String whereClause = '(Id = NULL)';
        for (String sobjectType : new List<String>{
            'Account',
            //'Case', [RGaokar 01/10/2022 TP #95106]Commented testmethod related to processCase method as the K4KCaseTrigger (zendesk callout for 'Manual_Review_Alert' case) is no longer needed.
            'Lead',
            'Solution_Architect_Request__c',
            'Customer_Onboarding__c'
        }) {
            fromClause = sobjectType;
            K4KInterface.manualRun(fromClause, whereClause);
        }

        Test.stopTest();
    }

    // Tests the K4KInterface setup and clearPreviousJobs methods.
    static testMethod void testSetupAndPreviousJobClearing() {
        //
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());

        String fromClause = 'Customer_Onboarding__c';
        String whereClause = '(Onboarding_Completed_Start_Date_Time__c = YESTERDAY OR Onboarding_Canceled_Start_Date_Time__c = YESTERDAY)';
        //K4KInterface.setup(fromClause, whereClause);
        K4KInterface.setup('Account');
        K4KInterface.clearAllPreviousK4KJobs();

        Test.stopTest();
    }

    // #########################################################################
    // Test KAC Processor Methods.

    // Tests the K4KProcessor Lead processor.
    static testMethod void testK4KLeadProcessor() {
        // Test K4K processor for Lead SObjects.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Create new lead
        Lead lead = new Lead();
        lead.LastName = 'Test Last';
        lead.Company = 'Test Co';
        // Set new Lead Status
        lead.Status = 'Disqualified';
        lead.SALES_Disqualification_Reason__c = 'testing';
        // Queue lead set for processing
        K4KProcessor k4kClient = new K4KProcessor(new Set<SObject>{lead});
        ID jobID = System.enqueueJob(k4kClient);
        System.debug('Queued new job with jobID' + jobID);

        // Attempt to process null sobject
        K4KProcessor k4kClientError = new K4KProcessor(new Set<SObject>{null});
        k4kClientError.processLead();
        Test.stopTest();
    }

    // Tests the K4KProcessor Account processor.
    static testMethod void testK4KAccountProcessor() {
        // Test K4K processor for Account SObjects.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());

        // Craete test accunt
        Account testAccount = createTestAccount();

        // Create a contact to tie to the account
        Contact testContact = createTestContact();
        testContact.AccountId = testAccount.id;
        insert testContact;

        // Set new Account Manager
        User testUser = createTestUser();
        testAccount.SUPPORT_Account_Manager__c = testUser.Id;

        // Queue account set for processing
        K4KProcessor k4kClient = new K4KProcessor(new Set<SObject>{testAccount});
        ID jobID = System.enqueueJob(k4kClient);
        System.debug('Queued new job with jobID' + jobID);

        // Attempt to process null sobject
        K4KProcessor k4kClientError = new K4KProcessor(new Set<SObject>{null});
        k4kClientError.processAccount();
        Test.stopTest();
    }

    // Tests the K4KCustomerOnboardingTrigger Account processor.
    static testMethod void testK4KCustomerOnboardingProcessor() {
        // Test the trigger on an CustomerOnboarding for insert & update runs successfully.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Create account for opportunity
        Account testAccount = new Account(
            Name='### Test Account ###'//
        );
        insert testAccount;
        // Create opportunity for onboarding object
        Opportunity testOpportunity = new Opportunity(
            StageName = 'test',
            CloseDate = Date.parse('12/27/2009'),
            Name = 'Test Opportunity Triggers',
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        // Create opportunity for onboarding object
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Test',
            Email = 'person@email.com',
            AccountId = testAccount.id
        );
        insert testContact;

        // Create new customerOnboarding
        Customer_Onboarding__c customerOnboarding = new Customer_Onboarding__c(
            Opportunity__c = testOpportunity.Id,
            Economic_Buyer__c = testContact.Id,
            Main_User__c = testContact.Id
        );

        // Test processing
        K4KProcessor k4kClient;
        // Set new onboarding completed status
        customerOnboarding.Status__c = 'Onboarding Completed';
        // Queue completed onboarding set for processing
        k4kClient = new K4KProcessor(new Set<SObject>{customerOnboarding});
        ID jobIDcompleted = System.enqueueJob(k4kClient);
        System.debug('Queued new job with jobID' + jobIDcompleted);

        // Set new onboarding canceled status
        customerOnboarding.Status__c = 'Onboarding Canceled';
        // Queue canceled onboarding set for processing
        k4kClient = new K4KProcessor(new Set<SObject>{customerOnboarding});
        ID jobIDcanceled = System.enqueueJob(k4kClient);
        System.debug('Queued new job with jobID' + jobIDcanceled);

        // Attempt to process null sobject
        K4KProcessor k4kClientError = new K4KProcessor(new Set<SObject>{null});
        k4kClientError.processCustomerOnboarding();
        Test.stopTest();
    }

    // Tests the K4KProcessor Case processor.
    // [RGaokar 01/10/2022 TP #95106]Commented testmethod related to processCase method 
    // as the K4KCaseTrigger (zendesk callout for 'Manual_Review_Alert' case) is no longer needed.
   /* static testMethod void testK4KCaseProcessor() {
        // Test K4K processor for Case SObjects.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());

        // Attempt to process null sobject
        K4KProcessor k4kClientError = new K4KProcessor(new Set<SObject>{null});
        k4kClientError.processCase();
        Test.stopTest();
    }*/

    // Tests the K4KProcessor SA Request processor.
    static testMethod void testK4KSaRequestProcessor() {
        // Test K4K processor for SA Request SObjects.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new generalUserIdTpResponseMock());

        // Create a test user to attach to required fields
        User testUser = createTestUser();
        insert testUser;
        // Create new account to tie to opportunity
        Account testAccount = createTestAccount();
        // Create opportunity for onboarding object
        Opportunity testOpportunity = createTestOpportunity(testAccount);
        // Create new customerOnboarding
        Customer_Onboarding__c testCustomerOnboarding = createTestCustomerOnboarding(testOpportunity);
        // Create new SA request
        Solution_Architect_Request__c testSaRequest = createTestSaRequest(testCustomerOnboarding, testUser);


        // Queue SA request set for processing
        K4KProcessor k4kClient = new K4KProcessor(new Set<SObject>{testSaRequest});
        ID jobID = System.enqueueJob(k4kClient);
        System.debug('Queued new job with jobID' + jobID);

        // Attempt to process null sobject
        K4KProcessor k4kClientError = new K4KProcessor(new Set<SObject>{null});
        k4kClientError.processSaRequest();
        Test.stopTest();
    }

    // #########################################################################
    // Some utility methods and classes.

    // Class for mocking HTTP callouts
    private class SingleRequestMock implements HttpCalloutMock {
        // Create a mock for HTTP responses from callouts.
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{}');
            System.debug('=== Making Mock HTTP Callout ===');
            return res;
        }
    }
    // Class for mocking HTTP callouts (tp general user id response)
    private class generalUserIdTpResponseMock implements HttpCalloutMock {
        // Create a mock for HTTP responses from callouts.
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('<GeneralUsers>' +
                '<GeneralUser ResourceType="GeneralUser" Id="625">' +
                '<Email>walid.bendris+123@klaviyo.com</Email>' +
                '<FullName>walid bendris</FullName>' +
                '<Kind>Requester</Kind>' +
                '</GeneralUser>' +
                '<GeneralUser ResourceType="GeneralUser" Id="43">' +
                '<Email>walid.bendris@klaviyo.com</Email>' +
                '<FullName>Walid Bendris</FullName>' +
                '<Kind>User</Kind>' +
                '</GeneralUser>' +
                '<GeneralUser ResourceType="GeneralUser" Id="608">' +
                '<Email>walid.bendris@klaviyo.com</Email>' +
                '<FullName>Walid Bendris</FullName>' +
                '<Kind>Requester</Kind>' +
                '</GeneralUser>' +
                '</GeneralUsers>');
            System.debug('=== Making Mock HTTP Callout ===');
            return res;
        }
    }

    // Method for manually setting formula fields
    //  Converts the object to JSON then a map and directly edits the key-value, then converts it back.
    private static SObject setFormulafield(SObject sObj, String fieldName, Object value){
        String jsonString = JSON.serialize(sObj);
        Map<String,Object> dataMap = (Map<String,Object>)JSON.deserializeUntyped(jsonString);
        dataMap.put(fieldName, value);
        jsonString = JSON.serialize(dataMap);
        //system.debug(jsonString);
        return (SObject)JSON.deserialize(jsonString, SObject.class);
    }

    // ####################
    // Mock Records

    // Generate test User record
    private static Contact createTestContact(){
        return new Contact(
            LastName = 'Contact',
            FirstName = 'Test',
            Email = 'test.contact@email.com'
        );
    }
    // Generate test User record
    private static User createTestUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        return new User(
            LastName = 'User',
            FirstName='Test',
            Alias = 'tperson',
            Email = 'test.user@email.com',
            Username = 'test.user_k4k@email.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US'
        );
    }
    // Generate test account record
    private static Account createTestAccount(){
        return new Account(
            Name = '### Test Account ###',
            Product_Klaviyo_Account_ID__c = 'abc123'
        );
    }
    // Generate test opportunity record
    private static Opportunity createTestOpportunity(Account testAccount){
        return new Opportunity(
            StageName = 'test',
            CloseDate = Date.parse('12/27/2009'),
            Name = 'Test Opportunity Triggers',
            AccountId = testAccount.Id
        );

    }
    // Generate test customer onboarding record
    private static Customer_Onboarding__c createTestCustomerOnboarding(Opportunity testOpportunity){
        return new Customer_Onboarding__c(
            Opportunity__c = testOpportunity.Id
        );
    }
    // Generate test SA request record
    private static Solution_Architect_Request__c createTestSaRequest(Customer_Onboarding__c testCustomerOnboarding, User testUser){
        Solution_Architect_Request__c testSaRequest = new Solution_Architect_Request__c(
            Customer_Onboarding__c = testCustomerOnboarding.Id,
            CreatedById = testUser.Id,
            SA_Request_Type__c = 'Advanced Use Cases',
            SA_Request_Type_Detail__c = 'Lists, Segments, and Subscription Management;Mobile (SMS, Push)',
            SA_Assignment_Context__c = 'a great description with all the info we actually need to look into this'
        );
        // Repair any formula fields that weren't set from not inserting the above records
        // Set klaviyo account link
        testSaRequest = (Solution_Architect_Request__c)setFormulafield(
            (SObject)testSaRequest,
            'Link_to_Klaviyo_Account__c',
            'https://www.klaviyo.com/staff/account/abc123/overview'
        );
        // Set onboarder id (request creator)
        testSaRequest = (Solution_Architect_Request__c)setFormulafield(
            (SObject)testSaRequest,
            'CreatedById',
            testUser.Id
        );
        testSaRequest = (Solution_Architect_Request__c)setFormulafield(
            (SObject)testSaRequest,
            'SA_Name__c',
            testUser.FirstName + ' ' + testUser.LastName
        );
        testSaRequest = (Solution_Architect_Request__c)setFormulafield(
            (SObject)testSaRequest,
            'Customer_Onboarding_Name__c',
            'Test Onboarding'
        );
        testSaRequest = (Solution_Architect_Request__c)setFormulafield(
            (SObject)testSaRequest,
            'CreatedDate',
            '1970-01-01'
        );
        system.debug(testSaRequest);
        return testSaRequest;
    }

}
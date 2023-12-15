@isTest
private class K4KProcessorTest {
  /* DEPRECATED
  
    private class SingleRequestMock implements HttpCalloutMock {
       // Create a mock for HTTP responses from callouts.
       public HTTPResponse respond(HTTPRequest req) {
           HTTPResponse res = new HTTPResponse();
           res.setBody('{}');
           res.setStatusCode(200);
           return res;
       }
    }
    // Tests the K4KProcessor Lead process.
    static testMethod void testK4KLeadProcessor() {
        // Test the trigger on an Account for insert & update runs successfully.
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
        // Queue lead list for processing
        K4KProcessor k4kClient = new K4KProcessor(new Set<Lead>{lead},'Lead');
        ID jobID = System.enqueueJob(k4kClient);
        System.debug('Queued new job with jobID' + jobID);

        K4KProcessor k4kClientError = new K4KProcessor(new Set<Lead>{null},'Lead');
        ID jobIDError = System.enqueueJob(k4kClientError);
        System.debug('Queued new job with jobID' + jobIDError);

        Test.stopTest();
    }
    // Tests the K4KProcessor Account process.
    static testMethod void testK4KAccountProcessor() {
        // Test the trigger on an Account for insert & update runs successfully.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        Account account = new Account(Name='### Test Account ###');
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User user = new User(LastName = 'person',
                             FirstName='Test',
                             Alias = 'tperson',
                             Email = 'test.person@email.com',
                             Username = 'test.person@email.com',
                             ProfileId = p.Id,
                             TimeZoneSidKey = 'GMT',
                             LanguageLocaleKey = 'en_US',
                             EmailEncodingKey = 'UTF-8',
                             LocaleSidKey = 'en_US'
                           );
        // Set new Account Manager
        account.SUPPORT_Account_Manager__c = user.Id;
        // Queue lead list for processing
        K4KProcessor k4kClient = new K4KProcessor(new Set<Account>{account},'Account');
        ID jobID = System.enqueueJob(k4kClient);
        System.debug('Queued new job with jobID' + jobID);

        K4KProcessor k4kClientError = new K4KProcessor(new Set<Account>{null},'Account');
        ID jobIDError = System.enqueueJob(k4kClientError);
        System.debug('Queued new job with jobID' + jobIDError);

        Test.stopTest();
    }
    */
}
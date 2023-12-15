@isTest
private class K4KAccountTriggerTest {
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
    // Tests the K4KAccountTrigger APEX trigger.
    static testMethod void testK4KAccountTrigger() {
        // Test the trigger on an Account for insert & update runs successfully.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Create new account
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
        // Test insterting the account
        insert account;
        System.assert(K4KProcessor.alreadyProcessed == true);
        K4KProcessor.alreadyProcessed = false;
        // Set new Account Manager
        account.SUPPORT_Account_Manager__c = user.Id;
        // Test updating account
        update account;
        System.assert(K4KProcessor.alreadyProcessed == true);
        Test.stopTest();
    }
    */
}
@isTest
private class K4KCaseTriggerTest {
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
    // Tests the K4KCaseTrigger APEX trigger.
    static testMethod void testK4KCaseTrigger() {
        // Test the trigger on an Case for insert & update runs successfully.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Create new account to tie to case
        Account acct = new Account(Name='### Test Account ###',
                                   Product_Klaviyo_Account_ID__c = 'abc123');
        // Create new supportCase
        Case supportCase = new Case();
        supportCase.AccountId = acct.Id;
        // Required Fields
        supportCase.Status = 'New';
        supportCase.Origin = 'Phone';
        // Record type needed for K4K trigger
        //supportCase.RecordTypeId = '0123o000001pPeXAAU'; // Record type is different in sandbox vs prod so need to use name
        Id manualReviewTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                         .get('Manual_Review_Alert').getRecordTypeId();
        supportCase.RecordTypeId = manualReviewTypeId;
        supportCase.Klaviyo_Account_ID__c = 'test';
        supportCase.Zendesk_Support_Ticket_ID__c = 'test';
        // Test insterting the supportCase
        insert supportCase;
        System.assert(K4KProcessor.alreadyProcessed == true);
        K4KProcessor.alreadyProcessed = false;
        // Test updating supportCase
        update supportCase;
        System.assert(K4KProcessor.alreadyProcessed == true);
        Test.stopTest();
    }
    */
}
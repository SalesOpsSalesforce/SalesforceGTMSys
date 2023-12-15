@isTest
private class K4KLeadTriggerTest {
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
    // Tests the K4KLeadTrigger APEX trigger.
    static testMethod void testK4KLeadTrigger() {
        // Test the trigger on an Lead for insert & update runs successfully.
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Create new lead
        Lead lead = new Lead();
        lead.LastName = 'Test Last';
        lead.Company = 'Test Co';
        // Test insterting the lead
        insert lead;
        System.assert(K4KProcessor.alreadyProcessed == true);
        K4KProcessor.alreadyProcessed = false;
        // Set new Lead Status
        lead.Status = 'Disqualified';
        lead.SALES_Disqualification_Reason__c = 'testing';
        // Test updating lead
        update lead;
        System.assert(K4KProcessor.alreadyProcessed == true);
        Test.stopTest();
    }
    */
}
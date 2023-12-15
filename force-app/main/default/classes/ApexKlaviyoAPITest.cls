@isTest
private class ApexKlaviyoAPITest {
  /* DEPRECATED
  
    // Runs a series of mock Apex-Klaviyo Track/Identify requests

    private class SingleRequestMock implements HttpCalloutMock {
        // Create a mock for HTTP responses from callouts.
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody('{}');
            res.setStatusCode(200);
            return res;
        }
    }
    // Tests the ApexKlaviyoAPI APEX class.
    static testMethod void testApexKlaviyoAPI() {
        // Start test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Add the Klaviyo public API key for your live or testing account
        String publicKey = 'JzeZKS';
        // Add a Salesforce Account record ID (that has associated Contact records)
        // that you'd like to use for this test
        Integer timestamp = Datetime.now().getTime().intValue() / 1000;
        String event = 'Apex Klaviyo API Wrapper Test Event';
        Map < String, Object > customerProperties = new Map < String, Object > ();
        Map < String, Object > properties = new Map < String, Object > ();
        Map <String, String> apiKeys = K4KProcessor.getMetadataTypeValuesByLabel('KlaviyoAPIAccount__mdt','TestAccount'); // Test Account
        ApexKlaviyoAPI klaviyoClient = new ApexKlaviyoAPI(apiKeys);
        // Test that the ApexKlaviyoAPI class's identify method works.
        klaviyoClient.identify(customerProperties);
        // Test that the ApexKlaviyoAPI class's track method works with all params. 
        klaviyoClient.track(event, customerProperties, properties, timestamp);
        // Test that the ApexKlaviyoAPI class's track method works with just api key, event name, customer properties, and event properties.
        klaviyoClient.track(event, customerProperties, properties);
        // Test that the ApexKlaviyoAPI class's track method works with just api key, event name, customer properties, and timestamp.
        klaviyoClient.track(event, customerProperties, timestamp);
        // Test that the ApexKlaviyoAPI class's track method works with just api key, event name, and customer properties.
        klaviyoClient.track(event, customerProperties);
        Test.stopTest();
    }
    */
}
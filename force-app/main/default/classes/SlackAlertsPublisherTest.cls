//[RGaokar 04/12/2022 TP #115270] Test class for SlackAlertsPublisher.
@isTest
private class SlackAlertsPublisherTest {
    @isTest
    private static void testSlackAlerts(){
        List<SlackAlertsPublisher.slackRequest> reqList = new List<SlackAlertsPublisher.slackRequest>();
        SlackAlertsPublisher.slackRequest req = new SlackAlertsPublisher.slackRequest();
        req.slackMessage = 'Test Alert';
        req.webhookURL = 'Big_Deal_Alerts';
        reqList.add(req);
        test.startTest();
        test.setMock(HttpCalloutMock.class, new MockCallout());
        SlackAlertsPublisher.postToSlack(reqList);
        test.stopTest();
    }
    
    public class MockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"text":"OK"}');
            res.setStatusCode(200);
            return res;
        } 
    }
    
}
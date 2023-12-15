@isTest
private class AlexaRankSchedulerTest
{
    @isTest
    static void testManualRunWithOverride(){
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Test with manual override query
        List<String> querySelect = new List<String>{'Id','Website'};
        String queryFrom = 'Account';
        String queryWhere = 'Website != \'\' AND MRRCalc__c = 0 AND RecordTypeId = \'012d0000001YZJK\' AND FINANCE_Payment_Method__c = \'Stripe\' LIMIT 1';
        AlexaRankScheduler alexaClientWithQuery = new AlexaRankScheduler(
            querySelect,
            queryFrom,
            queryWhere
        );
        alexaClientWithQuery.manualRun();
    }

    @isTest
    static void testManualRunWithoutOverride(){
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Test without manual override query
        AlexaRankScheduler alexaClientWithoutQuery = new AlexaRankScheduler();
        alexaClientWithoutQuery.manualRun();
        Test.StopTest();
    }

    @isTest
    static void testScheduledRunWithOverride(){
        String providedCronJobName =  'Periodic Bulk Alexa Rank Fetch test';

        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Test with manual override query
        String soqlQuery = 'SELECT Id,Website FROM Account WHERE Website != \'\' AND MRRCalc__c = 0 AND RecordTypeId = \'012d0000001YZJK\' AND FINANCE_Payment_Method__c = \'Stripe\' LIMIT 1';

        List<String> querySelect = new List<String>{'Id','Website'};
        String queryFrom = 'Account';
        String queryWhere = 'Website != \'\' AND MRRCalc__c = 0 AND RecordTypeId = \'012d0000001YZJK\' AND FINANCE_Payment_Method__c = \'Stripe\' LIMIT 1';
        System.schedule(providedCronJobName, '0 0 0 ? * SUN#2 *', new AlexaRankScheduler(
            querySelect,
            queryFrom,
            queryWhere
        ));

        GeneralUtils.clearPreviousJob(providedCronJobName);

    }

    @isTest
    static void testScheduledRunWithoutOverride(){
        String providedCronJobName =  'Periodic Bulk Alexa Rank Fetch test';
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
        // Test without manual override query
        System.schedule(providedCronJobName, '0 0 0 ? * SUN#2 *', new AlexaRankScheduler());
        GeneralUtils.clearPreviousJob(providedCronJobName);
        Test.StopTest();
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

}
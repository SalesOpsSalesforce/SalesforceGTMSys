global with sharing class heap_HeapService implements heap_IHeapService {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    global static void asyncCall(){}
    /*private String body;
    private String endpoint;
    private static Integer chunksCalled = 0;

    public heap_HeapService(String body, String endpoint){
        this.body = body;
        this.endpoint = endpoint;
    }
    public heap_HeapService(){}

    global static void call(List<String> identities, String endpoint) {
        if (heap_Configuration.SkipTriggers || Test.isRunningTest())  return;
        chunksCalled++;

        if (System.isFuture() || System.isBatch()) {
            syncCall(identities, endpoint);
        }
        else {
            if ( chunksCalled < heap_Configuration.MaxCallouts ) {
                asyncCall(identities, endpoint);
            }
            else {
                System.debug('Danger: Exceeded maximum futures.  Data not synced to heap');
            }
        }
    }

    global static void syncCall(List<String> identities, String endpoint) {
        for (String i: identities) {
            privateCall(endpoint, i);
        }
    }

    @future(callout=true)
    global static void asyncCall(List<String> identities, String endpoint) {
        for (String i: identities) {
            privateCall(endpoint, i);
        }
    }

    global static void privateCall(String endpoint, String body) {
        System.debug(LoggingLevel.Info, 'httpresponse');
        System.debug(LoggingLevel.Info, 'body: '+ body);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://heapanalytics.com/api/' + endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setCompressed(true);
        req.setBody(body);

        try {
            Http http = new Http();
            HttpResponse resp = http.send(req);
            String html = resp.getBody();
            System.debug(body);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }*/
}
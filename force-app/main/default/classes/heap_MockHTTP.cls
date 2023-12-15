@isTest
global class heap_MockHTTP  implements  HttpCalloutMock{
    global Integer numberCalls = 0;
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        numberCalls++;
        System.assertEquals('POST', req.getMethod());

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        return res;
    }
}
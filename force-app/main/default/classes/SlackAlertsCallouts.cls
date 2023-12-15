//[RGaokar 04/12/2022 TP #115270] Slack alrets callout
//Method called from SlackAlertsPublisher
public class SlackAlertsCallouts implements System.Queueable, Database.AllowsCallouts{
    List<SlackAlertsPublisher.slackRequestWrapper> requests;
    
    public SlackAlertsCallouts(List<SlackAlertsPublisher.slackRequestWrapper> calloutRequests){
        this.requests = calloutRequests;
    }
    
    public void execute(System.QueueableContext ctx){
        Boolean sandboxOrg = [SELECT IsSandbox FROM Organization].IsSandbox;
        //Loop throught different callout requests for different slack endpoints/channels
        for(SlackAlertsPublisher.slackRequestWrapper reqMessage: requests){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(reqMessage.requestEndPointURL);
            req.setMethod(reqMessage.requestMethod);
            req.setBody(reqMessage.requestBody);
            try{
                Http http = new Http();
                HttpResponse response = new HttpResponse();
                if(!Test.isRunningTest() && !sandboxOrg){
                    response = http.send(req);
                }else{
                    response.setHeader('Content-Type', 'application/json');
                    response.setBody('{"text":"OK"}');
                    response.setStatusCode(200);
                }
            }catch(System.CalloutException ex){
                system.debug('Error Message: '+ex.getMessage()+' Stack Trace: '+ex.getStackTraceString()); 
            }
        }  
    }
    
}
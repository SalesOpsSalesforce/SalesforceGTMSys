//[RGaokar 04/12/2022 TP #115270] Slack alrets send from Salesforce. Multiple alrets can be send to different slack channels.
//Method called from Opportunity after save flow for Big Deal Alerts
public class SlackAlertsPublisher{
    @InvocableMethod(label= 'Post to Slack')
    public static void postToSlack(List<slackRequest> requests){
        string endPointURL = 'callout:Slack_URL';
        string bigDealAlertMessage = '';
        List<slackRequestWrapper> slackRequests = new List<slackRequestWrapper>();
        Map <string, Slack_Webhook__mdt> slackWebhookMap = Slack_Webhook__mdt.getAll();
        string requestURL;
        for(slackRequest request:requests){
            //Big Deal Alrets
            if (slackWebhookMap.containsKey(request.webhookURL)){
                bigDealAlertMessage += request.slackMessage+'\n'+'\n';
                requestURL = request.webhookURL;
            } 
        }
        
        if(string.isNotBlank(bigDealAlertMessage)){
            string bigDealAlertendPoint = endPointURL + slackWebhookMap.get(requestURL).Incoming_Webhook_URL__c;
            string bigDealAlertBody = getRequestBody(bigDealAlertMessage);
            slackRequestWrapper requestWrapper = new slackRequestWrapper();
            requestWrapper.requestEndPointURL = bigDealAlertendPoint;
            requestWrapper.requestMethod = 'POST';
            requestWrapper.requestBody = bigDealAlertBody;
            slackRequests.add(requestWrapper);
        }
        
        //Send all callout requests to queueable method
        if(slackRequests.size()>0){
            system.enqueueJob(new SlackAlertsCallouts(slackRequests));
        }
    }
    
    private static string getRequestBody(string message){
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeStringField('text', message);
        jsonGen.writeBooleanField('link_names', true);
        jsonGen.writeEndObject();
        return jsonGen.getAsString();  
    }
    
    public class slackRequest{
        
        @InvocableVariable(required=true)
        public string webhookURL;
        
        @InvocableVariable(required=true)
        public string slackMessage;
    }
    
    public class slackRequestWrapper{
        public string requestEndPointURL{get;set;}
        public string requestMethod{get;set;}
        public string requestBody{get;set;}
    }
    
}
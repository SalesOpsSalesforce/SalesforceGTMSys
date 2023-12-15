global class SendMessageToSlackForQuoteApproval {    
    @future(callout=true)
    public static void SendMessage(Map<String, String> mapOfQuoteIds){
        List<QuoteWrapper> listOfQuoteWrapper = new List<QuoteWrapper>();
        List<ProcessInstanceWorkitem> listOfProcessInstanceWorkitem = [Select Id, ActorId, ProcessInstance.TargetObjectId From ProcessInstanceWorkitem Where ProcessInstance.TargetObjectId IN: mapOfQuoteIds.keySet() And ProcessInstance.Status = 'Pending'];
        if(!listOfProcessInstanceWorkitem.isEmpty()){
            for(ProcessInstanceWorkitem pRecord : listOfProcessInstanceWorkitem){
                listOfQuoteWrapper.add(new QuoteWrapper(pRecord.ActorId, pRecord.ProcessInstance.TargetObjectId, mapOfQuoteIds.get(pRecord.ProcessInstance.TargetObjectId)));
            }
        }
        if(!listOfQuoteWrapper.isEmpty()){
            for(QuoteWrapper qwRecord : listOfQuoteWrapper){
                sendSlackMessage(qwRecord.quoteId, qwRecord.quoteName, qwRecord.userId);
            }
        }else{
            System.debug('No Approval is pending.');
        }
    }
    
    public static void sendSlackMessage(String quoteId, String quoteName, String userId){
        Slack_User_Mapping__c slackSetting = Slack_User_Mapping__c.getInstance(userId);
        if(slackSetting.Send_Slack_Message__c && String.isNotBlank(slackSetting.Web_Hook_URL__c)){
            Quote quoteRecord = [SELECT Name, Total_Price__c, Account.Name, Account.MRRCalc__c, Owner.Name, Opportunity.Closedate, Discount_Reason__c, Discount_Reason_Additional_Details__c, Monthly_Price__c, Opportunity.Account.MRRCalc__c, Discount_Template_Quote_Account_MRR__c, (SELECT Product2.Name, Discount, TotalPrice, Discount_Length_of_Months__c, Usage_Limit__c, List_Price__c, UnitPrice FROM QuoteLineItems) FROM Quote WHERE Id =: quoteId];
            User userRecord = [Select Id, Name From User Where Id =: userId];
            String urlInstance = String.valueof(System.URL.getOrgDomainUrl()).replace('Url:[delegate=','').replace(']','');
            String quoteURL = urlInstance + '/lightning/r/Quote/' + quoteId + '/view';
            String approvalURL = urlInstance + '/lightning/r/Quote/' + quoteId + '/related/ProcessSteps/view';
            String jsonBody = '{"blocks":[{"type": "divider"},{"type": "section","text":{"type": "mrkdwn","text": "*Quote Approval Request* <' + quoteURL + '|*' + quoteName + '*>';
            jsonBody = jsonBody + '"}},{"type": "divider"},{"type": "section","text":{"type": "mrkdwn","text": "';
            jsonBody = jsonBody + '*Quote Name* : ' + quoteRecord.Name + '\n';
            jsonBody = jsonBody + '*Account Name* : ' + quoteRecord.Account.Name + '\n';
            jsonBody = jsonBody + '*Close Date* : ' + quoteRecord.Opportunity.Closedate + '\n';
            jsonBody = jsonBody + '*Sales Representative* : ' + quoteRecord.Owner.Name + '\n';
            jsonBody = jsonBody + '*Amount* : ' + quoteRecord.Total_Price__c + '\n';
            jsonBody = jsonBody + '*Change in MRR* : ' + quoteRecord.Monthly_Price__c + '\n';
            jsonBody = jsonBody + '*Current Account MRR* : ' + quoteRecord.Opportunity.Account.MRRCalc__c + '\n';
            jsonBody = jsonBody + '*New Account MRR* : ' + quoteRecord.Discount_Template_Quote_Account_MRR__c + '\n';
            jsonBody = jsonBody + '*Approver* : ' + userRecord.Name + '"}},';
            jsonBody = jsonBody + '{"type": "divider"},{"type": "section","text":{"type": "mrkdwn","text": "';
            for(QuoteLineItem qliRecord : quoteRecord.QuoteLineItems){
                jsonBody = jsonBody + '*Product Name* : ' + qliRecord.Product2.Name + '\n';
                jsonBody = jsonBody + '*Usage Limit* : ' + qliRecord.Usage_Limit__c + '\n';
                jsonBody = jsonBody + '*Discount Requested* : ' + qliRecord.Discount + '\n';
                jsonBody = jsonBody + '*Discount Length (# of Months)* : ' + qliRecord.Discount_Length_of_Months__c + '\n';
                jsonBody = jsonBody + '*List Price* : ' + qliRecord.List_Price__c + '\n';
                jsonBody = jsonBody + '*Unit Price* : ' + qliRecord.UnitPrice + '\n';
                jsonBody = jsonBody + '*Total Price* : ' + qliRecord.TotalPrice + '\n\n';
            }
            jsonBody = jsonBody + '"}},{"type": "divider"},{"type": "section","text":{"type": "mrkdwn","text": "';
            jsonBody = jsonBody + '*Discount Reason* : ' + quoteRecord.Discount_Reason__c + '\n';
            jsonBody = jsonBody + '*Discount Reason Additional Details* : ' + quoteRecord.Discount_Reason_Additional_Details__c + '\n';
            jsonBody = jsonBody + '<' + approvalURL + '|Approve or Reject Request Here>"}}]}';
             HttpRequest request = new HttpRequest();
            request.setEndpoint(slackSetting.Web_Hook_URL__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            System.debug('jsonBody : ' + jsonBody);
            request.setBody(jsonBody);
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() == 200) {
                System.debug('Message sent to Slack successfully!');
            } else {
                System.debug('Error sending message to Slack: ' + response.getBody());
            }
        }else{
            System.debug('Slack Web Hook URL is Not Available Or Slack Message permission is not available.');
        } 
    }
    
    public class QuoteWrapper{
        public String userId;
        public String quoteId;
        public String quoteName;
        
        public QuoteWrapper(String userId, String quoteId, String quoteName){
            this.userId = userId;
            this.quoteId = quoteId;
            this.quoteName = quoteName;
        }
    }
}
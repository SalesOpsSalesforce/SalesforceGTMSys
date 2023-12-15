global class SendMessageToSlack {    
    @future(callout=true)
    public static void SendMessage(Map<String, String> mapOfOpportunitiesIds){
        List<OpportunityWrapper> listOfOpportunityWrapper = new List<OpportunityWrapper>();
        List<ProcessInstanceWorkitem> listOfProcessInstanceWorkitem = [Select Id, ActorId, ProcessInstance.TargetObjectId From ProcessInstanceWorkitem Where ProcessInstance.TargetObjectId IN: mapOfOpportunitiesIds.keySet() And ProcessInstance.Status = 'Pending'];
        if(!listOfProcessInstanceWorkitem.isEmpty()){
            for(ProcessInstanceWorkitem pRecord : listOfProcessInstanceWorkitem){
                listOfOpportunityWrapper.add(new OpportunityWrapper(pRecord.ActorId, pRecord.ProcessInstance.TargetObjectId, mapOfOpportunitiesIds.get(pRecord.ProcessInstance.TargetObjectId)));
            }
        }
        if(!listOfOpportunityWrapper.isEmpty()){
            for(OpportunityWrapper owRecord : listOfOpportunityWrapper){
                sendSlackMessage(owRecord.opportunityId, owRecord.opportunityName, owRecord.userId);
            }
        }else{
            System.debug('No Approval is pending.');
        }
    }
    
    
    public static void sendSlackMessage(String opportunityId, String opportunityName, String userId){
        Slack_User_Mapping__c slackSetting = Slack_User_Mapping__c.getInstance(userId);
        if(slackSetting.Send_Slack_Message__c && String.isNotBlank(slackSetting.Web_Hook_URL__c)){
            Opportunity oppRecord = [SELECT Name, Amount, Account.Name, Opportunity_Owner_Name__c, Discount_Reason__c, Discount_Reason_Additional_Details__c, Account.MRRCalc__c, Discount_Template_Opp_Account_MRR__c, (SELECT Product2.Name, Discount__c, TotalPrice, Discount_Length_of_Months__c FROM OpportunityLineItems) FROM Opportunity WHERE Id = :opportunityId];
            User userRecord = [Select Id, Name From User Where Id =: userId];
            String urlInstance = String.valueof(System.URL.getOrgDomainUrl()).replace('Url:[delegate=','').replace(']','');
            String opportunityURL = urlInstance + '/lightning/r/Opportunity/' + opportunityId + '/view';
            String approvalURL = urlInstance + '/lightning/r/Opportunity/' + opportunityId + '/related/ProcessSteps/view';
            String jsonBody = '{"blocks":[{"type": "divider"},{"type": "section","text":{"type": "mrkdwn","text": "*Discount Approval request for Opportunity* <' + opportunityURL + '|*' + opportunityName + '*>';
            jsonBody = jsonBody + '"}},{"type": "divider"},{"type": "section","text":{"type": "mrkdwn","text": "';
            jsonBody = jsonBody + '*Opportunity Name* : ' + oppRecord.Name + '\n';
            // jsonBody = jsonBody + '*Opportunity Amount* : ' + oppRecord.Amount + '\n';
            jsonBody = jsonBody + '*Account Name* : ' + oppRecord.Account.Name + '\n';
            jsonBody = jsonBody + '*Change in MRR* : ' + oppRecord.Amount + '\n';
            jsonBody = jsonBody + '*Current Account MRR* : ' + oppRecord.Account.MRRCalc__c + '\n';
            jsonBody = jsonBody + '*New Account MRR* : ' + oppRecord.Discount_Template_Opp_Account_MRR__c + '\n';
            jsonBody = jsonBody + '*Opportunity Owner* : ' + oppRecord.Opportunity_Owner_Name__c + '\n';
            jsonBody = jsonBody + '*Discount Reason* : ' + oppRecord.Discount_Reason__c + '\n';
            jsonBody = jsonBody + '*Discount Reason Additional Details* : ' + oppRecord.Discount_Reason_Additional_Details__c + '\n';
            jsonBody = jsonBody + '*Approver* : ' + userRecord.Name + '"}},';
            jsonBody = jsonBody + '{"type": "divider"},{"type": "section","text":{"type": "mrkdwn","text": "';
            for(OpportunityLineItem oliRecord : oppRecord.OpportunityLineItems){
                jsonBody = jsonBody + '*Product Name* : ' + oliRecord.Product2.Name + '\n';
                jsonBody = jsonBody + '*Discount* : ' + oliRecord.Discount__c + '\n';
                jsonBody = jsonBody + '*Discount Length (# of Months)* : ' + oliRecord.Discount_Length_of_Months__c + '\n';
                jsonBody = jsonBody + '*Total Price* : ' + oliRecord.TotalPrice + '\n\n';
            }
            jsonBody = jsonBody + '"}},{"type": "divider"},{"type": "section","text":{"type": "mrkdwn","text": "';
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
    
    public class OpportunityWrapper{
        public String userId;
        public String opportunityId;
        public String opportunityName;
        
        public OpportunityWrapper(String userId, String opportunityId, String opportunityName){
            this.userId = userId;
            this.opportunityId = opportunityId;
            this.opportunityName = opportunityName;
        }
    }
    
}
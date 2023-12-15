@isTest(seeAllData=False)
private class SendMessageToSlackTest {    
    @isTest
    private static void testSendSlackMessage() {
        Slack_User_Mapping__c slackSetting = new Slack_User_Mapping__c(Send_Slack_Message__c = true, Web_Hook_URL__c = 'test.salesforce.com');
        insert slackSetting;
        Product2 prod = new Product2(Name = 'Klavio Email', Family = 'Email', IsActive = true, Pricing_Type__c = 'Unit Price', Public_Facing_Name__c = 'Klaviyo Professional');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = System.today(), Pricebook2Id = pricebookId, Sales_Method__c = 'In App');
        insert opp;
        OpportunityLineItem oli = new OpportunityLineItem(Discount_Length_of_Months__c = 1, OpportunityId = opp.Id, Quantity = 1, Usage_Limit__c = 10000, Discount = 25, Discount__c = 25, Product2Id = prod.Id, TotalPrice= 10000, PricebookEntryId = standardPrice.Id);
        insert oli;
    Approval.ProcessSubmitRequest testapproval = new Approval.ProcessSubmitRequest();
        testapproval.setComments('Submitting request for approval');
        testapproval.setObjectId(opp.Id);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SlackCallOutMock());
        Approval.ProcessResult result1 = Approval.process(testapproval);
        Test.stopTest();
        List<ProcessInstanceWorkitem> listOfProcessInstanceWorkitem = [Select Id, ActorId, ProcessInstance.TargetObjectId From ProcessInstanceWorkitem Where ProcessInstance.TargetObjectId =: opp.Id And ProcessInstance.Status = 'Pending'];
        Assert.areEqual(1, listOfProcessInstanceWorkitem.size(), 'Slack Message not send because Opportunity not gone in approval process');
    }
}
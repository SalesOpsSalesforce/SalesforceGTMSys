@isTest
private class AccountClaimProcessLeadsTest
{

    @isTest
    private static void testAccountClaimProcessLeads(){
    
        
        Account a = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1212', OwnerId = System.Label.Core_Placeholder_Id);
        a.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        a.FINANCE_Payment_Method__c = 'Stripe'; 
        
        insert a;
        
        // [01/11/2023 vrajapatuni SFDC #1514] Move Inbound leads to Inbound placeholder test cases update
        Lead l1 = new Lead(FirstName = 'Test1', LastName = 'Test Last name 1', Account__c = a.Id, Company = 'Test Company', MARKETING_Initial_Lead_Source__c = 'Inbound', MARKETING_Initial_Lead_Source_Detail__c = 'Direct');
        Lead l2 = new Lead(FirstName = 'Test2', LastName = 'Test Last name 2', Account__c = a.Id, Company = 'Test Company', HasOptedOutOfEmail = True);
        insert new List <Lead> {l1,l2};
        
        AccountClaimProcessLeads.UpdateAccountCliamProcessLeads(new List<ID> {a.Id});
           
    }

}
@isTest
private class AccountTransferToPlaceholderTest
{

    @isTest
    private static void testAccountTransferToPlaceholder(){
        
        
        Account a = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1212', Transfer_to_Spec_Ops_Placeholder__c  = True, Transfer_to_Core_Placeholder__c = true);
        a.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        a.FINANCE_Payment_Method__c = 'Stripe'; 
        
        Test.StartTest();
        
        insert a;   
        
        Test.StopTest();  
    }
    
}
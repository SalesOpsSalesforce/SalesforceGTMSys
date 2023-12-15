@isTest
private class AssociatedAccountsCalculationTest
{

     @isTest
    private static void testAssociatedAccounts(){
        
        Account a = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1212');
        a.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        a.FINANCE_Payment_Method__c = 'Stripe';        
        
        insert a;
        
    }

}
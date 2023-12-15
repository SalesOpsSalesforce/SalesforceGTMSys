@isTest
private class AccountRegionForCountryTest
{

     @isTest
    private static void testUpdateAccountRegionForCountry(){
        
        Account a1 = new Account(Name='TestAccountA1.com', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1212', Country__c = 'United States');
        a1.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        a1.FINANCE_Payment_Method__c = 'Stripe';
        a1.Target_Account_Status__c = 'Untouched';
        a1.Current_Email_Platform__c = 'Klaviyo';
        a1.Ecommerce_Platform__c = 'Shopify';
        a1.Medal__c = 'Tier 1'; 
        insert a1; 
        
        Account a2 = new Account(Name='TestAccountA2.com', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '12121', Country__c = 'Canada');
        a2.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        a2.FINANCE_Payment_Method__c = 'Stripe';
        a2.Target_Account_Status__c = 'Untouched';
        a2.Current_Email_Platform__c = 'Klaviyo';
        a2.Ecommerce_Platform__c = 'Shopify';
        a2.Medal__c = 'Tier 1'; 
        insert a2;
        
        a2.Country__c = 'United States';
        update a2;
        
        a2.SALES_Geographical_Location__c = null;
        update a2;
        
        Database.executeBatch(new AccountRegionForCountryBatch(),500);
        
        
    }

}
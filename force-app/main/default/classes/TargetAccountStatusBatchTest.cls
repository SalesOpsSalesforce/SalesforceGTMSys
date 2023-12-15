@isTest
private class TargetAccountStatusBatchTest
{

    @isTest
    private static void testTargetAccountStatusBatch(){
        
        Account a1 = new Account(Name='Test Account A', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1212');
        //a.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        a1.FINANCE_Payment_Method__c = 'Stripe';
        a1.RecordTypeId = '012d0000001YZJK';
        a1.Target_Account_Status__c = 'Untouched';
        a1.Current_Email_Platform__c = 'Klaviyo';
        // a1.Ecommerce_Platform__c = 'Shopify';
        a1.Medal__c = 'Tier 1';
        a1.Country__c = 'United States';
        a1.Last_Activity_Date_Custom__c = date.parse('6/30/2020');
        a1.Current_Contract_Expiration_Date__c = null;
        a1.ParentId = null;
        a1.Ecommerce_Platform__c = 'Shopify'; //[SFDC-1297 VR] Added the fields for a1 and a2 to improve code coverage
        
        Account a2 = new Account(Name='Test Account B', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1213');
        a2.FINANCE_Payment_Method__c = 'Stripe';
        a2.RecordTypeId = '012d0000001YZJK';
        a2.Target_Account_Status__c = 'Untouched';
        a2.Current_Email_Platform__c = 'Klaviyo';
        a2.Medal__c = 'Tier 1';
        a2.Country__c = 'United States';
        a2.Last_Activity_Date_Custom__c = date.parse('6/30/2020');
        a2.Last_Owner_Change_Date__c = date.parse('6/30/2020');
        a2.Current_Contract_Expiration_Date__c = null;
        a2.ParentId = null;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
        UserRole userobj=new UserRole(Name= 'testStampWorkingBDR'); 
        insert userobj; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg888.com', title = 'Product Specialist', UserRoleId = userobj.Id);

        System.runAs(u) {       
            insert new List <Account> {a1, a2}; //[SFDC-1297 VR] Updated a2 
        }
        
        Test.StartTest();
        TargetAccountStatusBatchScheduler obj = new TargetAccountStatusBatchScheduler();
        String schedule = '0 0 23 * * ?'; 
        system.schedule('Test TAP Attempting', schedule, obj); 
        Test.stopTest();  
                   
    }

}
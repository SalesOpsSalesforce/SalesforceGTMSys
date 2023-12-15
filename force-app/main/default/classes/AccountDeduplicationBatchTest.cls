@isTest
private class AccountDeduplicationBatchTest
{

    @testSetup static void buildData()
    {

        Account Special1 = new Account(Name='Test Account Special1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '11032021', website = 'www.klaviyo.com', FINANCE_Payment_Method__c = 'Wire Transfer / Manual Billing', ParentId = null, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
        Account NotSpecial1 = new Account(Name='Test Account NotSpecial1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = null, website = 'www.klaviyo.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = null, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
        
        Account NotSpecial2 = new Account(Name='Test Account NotSpecial2', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = null, website = 'www.test.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = null, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
        Account NotSpecial3 = new Account(Name='Test Account NotSpecial3', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = null, website = 'www.test.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = null, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
       
        insert new List <Account> {Special1, NotSpecial1, NotSpecial2, NotSpecial3};        
        
    }
    
    @isTest
    private static void testAccountDeduplicationBatch(){
        
        List <Account> lstAccounts = [select Id, Name, Clean_Website__c, Product_Klaviyo_Account_ID__c, ParentId, FINANCE_Payment_Method__c, RecordTypeId from Account order by Name];       
        
        
        Contact con1 = new Contact(FirstName = 'Test', LastName = 'Contact', Phone = '111.111.1111', AccountId = lstAccounts[0].Id);
        insert con1;
        
        con1.AccountId = lstAccounts[1].Id;
        update con1;
        
        Contact con2 = new Contact(FirstName = 'Test', LastName = 'Contact', Phone = '111.111.1111', AccountId = lstAccounts[3].Id);
        insert con2;
        
        con2.AccountId = lstAccounts[2].Id;
        update con2;
        
        Test.StartTest();
        AccountDeduplicationBatchScheduler obj = new AccountDeduplicationBatchScheduler();
        String schedule = '0 0 23 * * ?'; 
        system.schedule('Test Account Deduplication', schedule, obj); 
        
        AccountDeduplicationBatch obj2 = new AccountDeduplicationBatch();
        Database.QueryLocator ql = obj2.start(null);
        obj2.execute(null, lstAccounts);
        obj2.Finish(null);
        
        Test.stopTest();  
                   
    }

}
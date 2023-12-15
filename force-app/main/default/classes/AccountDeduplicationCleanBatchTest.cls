@isTest
private class AccountDeduplicationCleanBatchTest
{

    @testSetup static void buildData()
    {

        Account a1 = new Account(Name='Test Account Special1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Master_Account_Id__c = '12345',  Product_Klaviyo_Account_ID__c = '11032021', website = 'www.klaviyo.com', FINANCE_Payment_Method__c = 'Wire Transfer / Manual Billing', ParentId = null, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
        Account a2 = new Account(Name='Test Account NotSpecial1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Master_Account_Id__c = '12345', Product_Klaviyo_Account_ID__c = null, website = 'www.klaviyo.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = null, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
        insert new List <Account> {a1, a2};        
        
    }
   
    @isTest
    private static void testAccountDeduplicationCleanBatch(){
        
        List <Account> lstAccounts = [select Id, Name, Master_Account_Id__c from Account order by Name]; 
        
        Test.StartTest();
        AccountDeduplicationCleanBatch obj2 = new AccountDeduplicationCleanBatch();
        Database.QueryLocator ql = obj2.start(null);
        obj2.execute(null, lstAccounts);
        obj2.Finish(null);
        Test.stopTest();  
                   
    }

}
@isTest
private class AccountMRRRollUpBulkUpdateBatchTest
{

    @isTest
    private static void testAccountMRRRollUpBulkUpdateBatch(){
    
        List<Account> accList = new List<Account>();
        Account a1 = new Account(Name='Parent', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1212', Type = 'Parent Account');
        insert a1;
        
        Account a2 = new Account(Name='Child', SUPPORT_Account_Manager__c=UserInfo.getUserId(), ParentId = a1.id);
        insert a2;
        
        accList.add(a1);
        accList.add(a2);
        
        Test.StartTest();
        
        AccountMRRRollUpBulkUpdateBatch obj = new AccountMRRRollUpBulkUpdateBatch();
        Database.QueryLocator ql = obj.start(null);
        obj.execute(null, accList);
        obj.Finish(null);
        
        Test.stopTest();  
                   
    }

}
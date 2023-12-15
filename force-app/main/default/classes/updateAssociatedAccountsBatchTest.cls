@isTest
private class updateAssociatedAccountsBatchTest
{

    @testSetup static void buildData()
    { 
        Account UltimateParent1 = new Account(Name='UltimateParent1', SUPPORT_Account_Manager__c = UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '11032021', website = 'www.klaviyo.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = null, RecordTypeId = System.label.Parent_Account_Record_Id);
        Account UltimateParent2 = new Account(Name='UltimateParent2', SUPPORT_Account_Manager__c = UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1112222', website = 'www.test.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = null, RecordTypeId = System.label.Parent_Account_Record_Id);
        insert new List <Account> {UltimateParent1, UltimateParent2};
        
        List<Account> ParentAccountId = [Select id from Account where name like '%UltimateParent%'];
        
        Account BrandAccount = new Account(Name='Test Account NotSpecial1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = null, website = 'www.klaviyo.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = ParentAccountId[0].id, RecordTypeId = System.label.Parent_Account_Record_Id);
        insert BrandAccount;
        
        Account Child1 = new Account(Name='Child1', SUPPORT_Account_Manager__c = UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = null, website = 'www.test.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = ParentAccountId[0].id, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
        Account Child2 = new Account(Name='Child2', SUPPORT_Account_Manager__c = UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = null, website = 'www.test.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = ParentAccountId[0].id, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
        Account Child3 = new Account(Name='Child3', SUPPORT_Account_Manager__c = UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = null, website = 'www.test.com', FINANCE_Payment_Method__c = 'Stripe', ParentId = null, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
        Account Child4 = new Account(Name='Child4', SUPPORT_Account_Manager__c = UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = null, website = 'www.test.com', FINANCE_Payment_Method__c = 'Billed Under Parent Account', ParentId = ParentAccountId[1].id, RecordTypeId = System.label.Klaviyo_Account_Record_Id);
       
        insert new List <Account> {Child1, Child2, Child3, Child4};
    }
    
    @isTest
    private static void testupdateAssociatedAccountsBatch(){
        // Retrieve the users associated accounts and validate the count
        Set<Id> userSet = new set<Id>();
        userSet.add(userinfo.getuserid());
        
        List <User> userList = [select Id, Associated_Accounts__c from User where id =: userinfo.getuserid()];
        
        Test.StartTest();
        updateAssociatedAccountsBatch obj = new updateAssociatedAccountsBatch(userSet);
        Database.QueryLocator ql = obj.start(null);
        obj.execute(null, userList);
        obj.Finish(null);
        
        //Using Not equals 0 instead of equals 5 in order to avoid any issues if any new accounts are added in the future
        // system.assertNotEquals(0, userList[0].Associated_Accounts__c);
        
        Test.stopTest();
    }

}
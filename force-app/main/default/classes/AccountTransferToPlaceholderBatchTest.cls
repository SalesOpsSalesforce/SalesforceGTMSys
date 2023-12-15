@isTest
private class AccountTransferToPlaceholderBatchTest
{

    @testSetup static void buildData()
    {

        Account a = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1212', Transfer_to_Spec_Ops_Placeholder__c  = True, Transfer_to_Core_Placeholder__c = true);
        a.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        a.FINANCE_Payment_Method__c = 'Stripe'; 
        insert a;
        
        Lead l = new Lead(FirstName = 'Test', LastName = 'Test Last name', Account__c = a.Id, Company = 'Test Company');
        insert l;
        
    }

    @isTest
    private static void testAccountTransferToPlaceholder(){
        
        List <Account> lstAccounts = [select Id from Account order by Name]; 
        List <Lead> lstLeads = [select Id, isConverted from Lead order by Name]; 
        Set<Id> acctIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        
        for(Account a : lstAccounts){
            acctIds.add(a.Id);
        }
        
        for(Lead l : lstLeads){
            if(!l.isConverted)
                {
                    leadIds.add(l.Id);
                }
        }
        
        Test.StartTest();
        Database.executeBatch(new AccountTransferToPlaceholderBatch(leadIds, acctIds, acctIds), 10);
        Test.StopTest();  
    }

}
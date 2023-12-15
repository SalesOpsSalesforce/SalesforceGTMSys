@isTest
private class TargetAccountDQBatchTest
{
    
    @testSetup static void buildData()
    {

        Account a = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1212', Target_Account_Status__c = 'Untouched');
        a.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        a.FINANCE_Payment_Method__c = 'Stripe';
        a.Current_Email_Platform__c = 'Klaviyo';
        a.Ecommerce_Platform__c = 'Shopify';
        a.Medal__c = 'Tier 1';
        a.Country__c = 'United States'; 
        insert a;
        
        Lead l = new Lead(FirstName = 'Test', LastName = 'Test Last name', Account__c = a.Id, Company = 'Test Company');
        insert l;
        
    }
    
    
    @isTest
    private static void testTargetAccountDQtest(){
    
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
        
        lstAccounts[0].Target_Account_Status__c = 'DQ - Do not Contact';
        update lstAccounts;
        
        Database.executeBatch(new TargetAccountDQBatch(leadIds, acctIds), 20);
    
    }
    
}
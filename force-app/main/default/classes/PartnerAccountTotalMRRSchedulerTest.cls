@isTest
private class PartnerAccountTotalMRRSchedulerTest {
    @testSetup
    static void dataSetup(){
        //Create accounts
        List<Account> accList = new List<Account>();
        Map <String,Schema.RecordTypeInfo> accRecordTypeMap = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        //Customer Accounts
        for(Integer i=0;i<2;i++) {
            accList.add(new Account(Name = 'Test Account'+i, recordTypeId = accRecordTypeMap.get('Klaviyo Account').getRecordTypeId(),
                                    Product_Klaviyo_Account_ID__c  = 'abc'+i, Experts_Tier__c = 'Silver'));
        }
        //Partner Accounts
        //[vrajapatruni 02/07/2023 SFDC-603] Adding more partner accounts and creating a parent child hierarchy. Included partner type 
        for(Integer i=2;i<5;i++) {
            accList.add(new Account(Name = 'Test Account'+i, recordTypeId = accRecordTypeMap.get('Referral Partner Account').getRecordTypeId(), First_Partner_Split_Created__c = Date.Today(), RP_Referral_Partner_Type__c = 'Technology Partner')); //[jrodden 11/03/2022 SFDC-1140] Added First_Partner_Split_Created__c = Date.Today()for code coverage
        }
        accList[2].Services_Tier__c = 'Silver';
        accList[3].Experts_Tier__c = 'Silver';
        accList[4].Experts_Tier__c = 'Silver';
        insert accList;
        
        //Setup Parent Child Hierarchy
        accList[3].parentId = accList[2].id;
        accList[4].parentId = accList[2].id;
        update accList;
        
        //Create opportunities on Klaviyo account related to partner account
        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i=0;i<2;i++) {
            oppList.add(new Opportunity(Name='Test Opp '+i, AccountId=accList[i].Id, StageName='Closed Won', Amount=100.0, CloseDate= Date.today(),
                                        Opportunity_Product__c = 'Email Subscription', RP_Referral_Partner_Account__c = accList[i+2].id));
            oppList.add(new Opportunity(Name='Test SMS Opp '+i, AccountId=accList[i].Id, StageName='Closed Won', Amount=100.0, CloseDate= Date.today(),
                                        Opportunity_Product__c = 'SMS Subscription', RP_Referral_Partner_Account__c = accList[i+2].id));
            oppList.add(new Opportunity(Name='Test Klaviyo Reviews Opp '+i, AccountId=accList[i].Id, StageName='Closed Won', Amount=100.0, CloseDate= Date.today(),
                                        Opportunity_Product__c = 'Klaviyo Reviews', RP_Referral_Partner_Account__c = accList[i+2].id));
            oppList.add(new Opportunity(Name='CDP '+i, AccountId=accList[i].Id, StageName='Closed Won', Amount=100.0, CloseDate= Date.today(),
                                        Opportunity_Product__c = 'Klaviyo Customer Data Platform', RP_Referral_Partner_Account__c = accList[i+2].id));
        }
              
        insert oppList;
        
        List<Partner_Split__c> psList = new List<Partner_Split__c>();
        // Manually Created Partner Splits Eligible for Attribution Credit
        for(Integer i=0;i<2;i++) {
            psList.add(new Partner_Split__c(Partner_Account__c = accList[i+2].id, Customer_Account__c  = accList[i].id, Opportunity__c = oppList[i].id,
                                            Payout_Percent__c = 20, Manually_Created__c = true, RevShare_of_Months__c = 12, Partner_Type__c = 'Referral Partner'));
        }
        // Manually Created Partner Splits Eligible for Managed MRR Credit
        for(Integer i=2;i<4;i++) {
            psList.add(new Partner_Split__c(Partner_Account__c = accList[i].id, Customer_Account__c  = accList[i-2].id, Opportunity__c = oppList[i-2].id,
                                            Payout_Percent__c = 20, Manually_Created__c = true, RevShare_of_Months__c = 12, Partner_Type__c = 'Managed', Override_Start_Date__c = Date.today()));
        }
        insert psList;
    }
    
    @isTest
    private static void testPartnerAccountTotalMRR(){
        List<Partner_Split__c> psList = [Select id,Partner_Account__r.name, Actual_MRR__c,Credited_MRR__c,Managed_MRR__c, Eligible_for_Attribution_Credit__c, Eligible_for_Managed_MRR_Credit__c, Payout_Start_date__c  from Partner_Split__c];
        Test.StartTest();
        PartnerAccountTotalMRRScheduler testsch = new PartnerAccountTotalMRRScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Partner Total Scheduler', sch, testsch);
        Test.stopTest();  
    }
    
}
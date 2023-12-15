@isTest
private class MRRAttributedtoAgencyBatchTest
{

    @testSetup static void buildData()
    {

        Lead l1 = new Lead(FirstName='Suzie', LastName='Queue', Company='TestCo 1');
        insert new List <Lead> {l1};

        Account a1 = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c='01234555');
        Account a2 = new Account(Name='Test Account 2', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c='01234566');
        insert new List <Account> {a1, a2};

    }
    
    @isTest
    private static void testMRRAttributedtoAgencyBatch(){
        
        List <Account> lstAccounts = [select Id from Account order by Name];
        List <OpportunityStage> oppStage = [select ApiName, IsActive, IsClosed, IsWon, DefaultProbability from OpportunityStage where IsActive = true and DefaultProbability = 25 limit 1];

        OpportunityTriggerHandler.isFirstTimeInsert = true;
        // [vrajapatruni TP #117002 06/17/2022] Updated the LEAD_Partner_Lead_Registration_Status__c picklist to just Accepted/Rejected and created a dependent picklist for status reasons
        Opportunity o1 = new Opportunity(Name='Test Opp 1', AccountId=lstAccounts[0].Id, StageName='Closed Won', CloseDate=Date.today(), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Land: New Account', RP_Referral_Partner_Account__c=lstAccounts[1].Id, Amount=100.0, SALES_Ecommerce_Platform__c='Shopify',
                LEAD_Partner_Lead_Registration_Status__c='Accepted', LEAD_Partner_Registration_Status_Reason__c='Accepted - New', LEAD_SALES_DateTimeofPartnerLeadAcceptRe__c=Datetime.now(), Opportunity_Product__c = 'SMS Subscription');
        insert o1;

        o1 = new Opportunity(Id=o1.Id, StageName = 'Closed Won', Update_Widget__c=2);
        update new List <Opportunity> {o1};
        
        Test.StartTest();
        database.executeBatch(new MRRAttributedtoAgencyBatch(),1);
        Test.stopTest();  
                   
    }

}
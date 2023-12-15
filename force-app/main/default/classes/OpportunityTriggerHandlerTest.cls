/* Class:       OpportunityTriggerHandlerTest
** Created by:  OpFocus 
** Description: Methods for testing opportunity triggers
*/

@isTest
private class OpportunityTriggerHandlerTest
{

    @testSetup static void buildData()
    {

        Lead l1 = new Lead(FirstName='Suzie', LastName='Queue', Company='TestCo 1');
        insert new List <Lead> {l1};

        Account a1 = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c='01234555');
        Account a2 = new Account(Name='Test Account 2', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c='ab1234');
        insert new List <Account> {a1,a2};
    }

    @isTest
    private static void testOpportunityHandler()
    {
        
        List <Account> lstAccounts = [select Id from Account order by Name];
        List <OpportunityStage> oppStage = [select ApiName, IsActive, IsClosed, IsWon, DefaultProbability from OpportunityStage where IsActive = true and DefaultProbability = 25 limit 1];
        
        // [vrajapatruni TP #117002 06/17/2022] Updated the LEAD_Partner_Lead_Registration_Status__c picklist to just Accepted/Rejected and created a dependent picklist for status reasons
        Opportunity o1 = new Opportunity(Name='Test Opp 1', AccountId=lstAccounts[0].Id, StageName=oppStage[0].ApiName, CloseDate=Date.today(), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Cancellation', RP_Referral_Partner_Account__c=lstAccounts[0].Id, Amount=100.0, SALES_Ecommerce_Platform__c='Shopify', Opportunity_Product__c = 'Email Subscription');
        Opportunity o2 = new Opportunity(Name='Test Opp 2', AccountId=lstAccounts[0].Id, StageName='Closed Won', CloseDate=Date.today(), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Expand: Additional Product', RP_Referral_Partner_Account__c=lstAccounts[0].Id, Amount=100.0, SALES_Ecommerce_Platform__c='Shopify',
                LEAD_Partner_Lead_Registration_Status__c='Accepted', LEAD_Partner_Registration_Status_Reason__c='Accepted - New', LEAD_SALES_DateTimeofPartnerLeadAcceptRe__c=Datetime.now(), Opportunity_Product__c = 'Email Subscription');
        Opportunity o3 = new Opportunity(Name='Test Opp 3', AccountId=lstAccounts[0].Id, StageName='Closed Won', CloseDate=Date.today(), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Downgrade', RP_Referral_Partner_Account__c=lstAccounts[0].Id, Amount=100.0, SALES_Ecommerce_Platform__c='Shopify',
                LEAD_Partner_Lead_Registration_Status__c='Accepted', LEAD_Partner_Registration_Status_Reason__c='Accepted - New', LEAD_SALES_DateTimeofPartnerLeadAcceptRe__c=Datetime.now(), Opportunity_Product__c = 'Email Subscription');
        insert new List <Opportunity> {o1, o2, o3};
        Quote quoteRecord = new Quote(Name = 'Test Quote', OpportunityId = o1.Id, BillingCountry = 'United States');
        insert quoteRecord;
        Contract contactRecord = new Contract(Original_Opportunity__c = o1.Id, StartDate = System.today(), AccountId = lstAccounts[0].Id);
        insert contactRecord;
        
        
        test.startTest();
        
        OpportunityTriggerHandler.isFirstTimeInsert = true;
        Opportunity o4 = new Opportunity(Name='Test Opp 4', AccountId=lstAccounts[0].Id, StageName='Closed Won', CloseDate=Date.today(), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Land: New Account', RP_Referral_Partner_Account__c=lstAccounts[0].Id, Amount=100.0, SALES_Ecommerce_Platform__c='Shopify',
                LEAD_Partner_Lead_Registration_Status__c='Accepted', LEAD_Partner_Registration_Status_Reason__c='Accepted - New', LEAD_SALES_DateTimeofPartnerLeadAcceptRe__c=Datetime.now(), Opportunity_Product__c = 'Email Subscription');
        insert o4;
        

        o1 = new Opportunity(Id=o1.Id, StageName = 'Closed Won', Update_Widget__c=2, Primary_Quote__c = quoteRecord.Id, Contract__c = contactRecord.Id);
        update o1;
        
        test.stopTest();
    }
    
}
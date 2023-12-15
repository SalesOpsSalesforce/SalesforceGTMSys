/* *********
*  Date:            10/2019
*  Description:     Tests for the PartnerPayment Apex class
*  Developer:       OpFocus
* *********/

@isTest
private class PartnerPaymentTest
{

    public static List <String> lstFlowAmounts = new List <String> {
                                        'Yes - Influencers Silver - 5%',
                                        'Yes - Influencers Gold - 10%',
                                        'Yes - Influencers Platinum - 15%',
                                        'Attributed to Agency, No Payment'
                                    };

    public static Map <String, Decimal> mapFMManagedPayoutAmt = new Map <String, Decimal> {'Silver'=>0.02, 'Gold'=>0.03, 'Platinum'=>0.04};


    @testSetup static void buildData()
    {
        Date prevQDate = Date.newInstance(2019, 9, 1);
        Date thisQDate = Date.newInstance(2019, 11, 1);

        List <Payout_Calculator_Dates__mdt> lstPayoutDates = [select Advisors_Prev_Quarter_Date__c, Advisors_Quarterly_Date__c, Influencers_Monthly_Calc_Date__c, Masters_Annual_Date__c from Payout_Calculator_Dates__mdt];


        Lead l1 = new Lead(FirstName='Suzie', LastName='Queue', Company='TestCo 1');
        insert new List <Lead> {l1};

        // testPartnerPayment:
        //   account 1
        //   payments 1, 2, 3
        // 
        // testOneTimeBounty:
        //   accounts 2
        //   opportunity 1 and 2
        //   payments 4, 5, 6
        // 
        // testMastersPayment:
        //   account 3, Experts_Partner_Account__c = a5, a6
        //   opportunity 3 and 4
        // 
        Account a1 = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId());
        Account a2 = new Account(Name='Test Account 2', SUPPORT_Account_Manager__c=UserInfo.getUserId());
        Account a3 = new Account(Name='Test Account 3', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Experts_Tier__c='Silver');
        insert new List <Account> {a1, a2, a3};

        Account a4 = new Account(Name='Test Account 4', SUPPORT_Account_Manager__c=UserInfo.getUserId());
        Account a5 = new Account(Name='Test Account 5', SUPPORT_Account_Manager__c=UserInfo.getUserId(), RP_Agency_Experts_Accounts_Status__c='Active', Experts_Partner_Account__c=a3.Id);
        Account a6 = new Account(Name='Test Account 6', SUPPORT_Account_Manager__c=UserInfo.getUserId(), RP_Agency_Experts_Accounts_Status__c='Active', Experts_Partner_Account__c=a3.Id);
        insert new List <Account> {a4, a5, a6};

        List <OpportunityStage> oppStage = [select ApiName,IsActive, IsClosed, IsWon, DefaultProbability from OpportunityStage where IsActive = true and DefaultProbability = 25 limit 1];

        Opportunity o1 = new Opportunity(Name='Test Opp 1', AccountId=a2.Id, StageName='Closed/Won',        Amount=100.0, CloseDate=lstPayoutDates[0].Masters_Annual_Date__c.date().addDays(-1), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Cancellation');
        Opportunity o2 = new Opportunity(Name='Test Opp 2', AccountId=a2.Id, StageName='Closed/Won',        Amount=100.0, CloseDate=lstPayoutDates[0].Masters_Annual_Date__c.date().addDays(-1), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Cancellation');
        Opportunity o3 = new Opportunity(Name='Test Opp 1', AccountId=a5.Id, StageName=oppStage[0].ApiName, Amount=100.0, CloseDate=lstPayoutDates[0].Masters_Annual_Date__c.date().addDays(-1), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Cancellation');
        Opportunity o4 = new Opportunity(Name='Test Opp 2', AccountId=a6.Id, StageName='Closed/Won',        Amount=100.0, CloseDate=lstPayoutDates[0].Masters_Annual_Date__c.date().addDays(-1), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Cancellation');
        insert new List <Opportunity> {o1, o2, o3, o4};

        o1 = new Opportunity(Id=o3.Id, StageName = 'Closed/Won');
        update o3;

        Payment__c pay1 = new Payment__c(FLOW_Payout_Amount_to_Referral_Partner__c='Yes - Silver - 10%', Payment_Date__c=prevQDate, Status__c='paid', Referral_Partner_Account__c=a1.Id, Account__c=a2.Id);
        Payment__c pay2 = new Payment__c(FLOW_Payout_Amount_to_Referral_Partner__c='Yes - Silver - 10%', Payment_Date__c=thisQDate, Status__c='paid', Referral_Partner_Account__c=a1.Id, Account__c=a2.Id);
        Payment__c pay3 = new Payment__c(FLOW_Payout_Amount_to_Referral_Partner__c='Yes - Influencers Silver - 5%', Payment_Date__c=thisQDate, Status__c='paid', Referral_Partner_Account__c=a1.Id, Account__c=a2.Id);

        Date paymentDate2 = lstPayoutDates[0].Influencers_Monthly_Calc_Date__c.date().addDays(-1);

        Payment__c pay4 = new Payment__c(FLOW_Payout_Amount_to_Referral_Partner__c=lstFlowAmounts[0], Payment_Date__c=paymentDate2, Status__c='paid', Referral_Partner_Account__c=a2.Id, Account__c=a2.Id, FLOW_Close_Date_of_New_Account_Opp__c=paymentDate2.addDays(-120));
        Payment__c pay5 = new Payment__c(FLOW_Payout_Amount_to_Referral_Partner__c=lstFlowAmounts[0], Payment_Date__c=paymentDate2, Status__c='paid', Referral_Partner_Account__c=a2.Id, Account__c=a2.Id, FLOW_Close_Date_of_New_Account_Opp__c=paymentDate2.addDays(-120));
        Payment__c pay6 = new Payment__c(FLOW_Payout_Amount_to_Referral_Partner__c=lstFlowAmounts[0], Payment_Date__c=paymentDate2, Status__c='paid', Referral_Partner_Account__c=a2.Id, Account__c=a2.Id, FLOW_Close_Date_of_New_Account_Opp__c=paymentDate2.addDays(-120));
        
        insert new List <Payment__c> {pay1, pay2, pay3, pay4, pay5, pay6};
    }

    @isTest
    private static void testPartnerPayment()
    {
        List <Account> lstAccounts = [select Id, Name from Account order by Name];

        test.startTest();

        String paymnt = PartnerPayment.getPaymentNameFormula(lstAccounts[0].Name);
        String unpaid = PartnerPayment.getUnpaidName(lstAccounts[0].Name);

        List <String> lstStr = PartnerPayment.calculatePartnerPayments(lstAccounts[0].Id);

        test.stopTest();


    }
    
    @isTest
    private static void testPartnerPayment_noPaymentInfo() {
        PartnerPayment.paymentMethodOverride = true;
        testPArtnerPayment();
        PArtnerPayment.paymentMethodOverride = null;
    }
    
    @isTest
    private static void testPartnerPayment_1quarterAhead() {
        Integer nextQuarterMonth = Date.today().month() + 3;
        if (nextQuarterMonth > 12) {
            nextQuarterMonth -= 12;
        }
        
        PartnerPayment.monthOverride = nextQuarterMonth;
        testPartnerPayment();
        PartnerPayment.monthOverride = null;
        
    }
    
    @isTest
    private static void testGetEligbilityMessages() {
        system.assertEquals(4, PartnerPayment.getEligibilityMessages().size());
    }
    
    @isTest
    private static void testPartnerPayment_2quartersAhead() {
        Integer nextQuarterMonth = Date.today().month() + 6;
        if (nextQuarterMonth > 12) {
            nextQuarterMonth -= 12;
        }
        
        PartnerPayment.monthOverride = nextQuarterMonth;
        testPartnerPayment();
        PartnerPayment.monthOverride = null;
        
    }
    
    @isTest
    private static void testPartnerPayment_3quartersAhead() {
        Integer nextQuarterMonth = Date.today().month() + 9;
        if (nextQuarterMonth > 12) {
            nextQuarterMonth -= 12;
        }
        
        PartnerPayment.monthOverride = nextQuarterMonth;
        testPartnerPayment();
        PartnerPayment.monthOverride = null;
        
    }
    
    @isTest
    private static void testLogExceptions() {
        try {
            List<String> i = null;
            Integer iSize = i.size();
        }
        catch (Exception e) {
            system.assertEquals(PartnerPayment.logExceptions('test', e).size(), 2);
        }
    }

    @isTest
    private static void testConstructor() {
        system.assertNotEquals(null, new PartnerPayment());
    }
    
    @isTest
    private static void testOneTimeBounty()
    {
        List <Account> lstAccounts = [select Id, Name from Account order by Name];

        test.startTest();

        List <String> lstStr = PartnerPayment.calculateOneTimeBounty(lstAccounts[1].Id);

        test.stopTest();


    }


    @isTest
    private static void testMastersPayment()
    {
        List <Account> lstAccounts = [select Id, Name from Account order by Name];


        test.startTest();

        List <String> lstStr = PartnerPayment.calculateMastersPayment(lstAccounts[2].Id);

        test.stopTest();


    }
}
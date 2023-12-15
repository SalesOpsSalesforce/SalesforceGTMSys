/* Class:       AccountTriggerHandlerTest
** Created by:  OpFocus 
** Description: Methods for testing account triggers
*/

@isTest
private class AccountTriggerHandlerTest
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
        // If the TriggerDisablementSwitch has this disabled, enable it for this unit tests so
        // we can cover that code.
        TriggerDisablementSwitchHelper.mapSwitches.put('Klaviyo_Product_Usage_Creation_Triggers'.toLowerCase(), false);

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
        Account a1 = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '1212');
        Account a2 = new Account(Name='Test Account 2', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = 'AB11');
        Account a3 = new Account(Name='Test Account 3', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Experts_Tier__c='Silver');
        insert new List <Account> {a1, a2, a3};

        Account a4 = new Account(Name='Test Account 4', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = 'AB22');
        Account a5 = new Account(Name='Test Account 5', SUPPORT_Account_Manager__c=UserInfo.getUserId(), RP_Agency_Experts_Accounts_Status__c='Active', Experts_Partner_Account__c=a3.Id, Product_Klaviyo_Account_ID__c = 'AB33');
        Account a6 = new Account(Name='Test Account 6', SUPPORT_Account_Manager__c=UserInfo.getUserId(), RP_Agency_Experts_Accounts_Status__c='Active', Experts_Partner_Account__c=a3.Id, Product_Klaviyo_Account_ID__c = 'AB44');
        Account a7 = new Account(Name='Test Account 7', SUPPORT_Account_Manager__c=UserInfo.getUserId(), RP_Agency_Experts_Accounts_Status__c='Active', Experts_Partner_Account__c=a3.Id, Product_Klaviyo_Account_ID__c = 'AB55');
        Account a8 = new Account(Name='Test Account 8', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Experts_Tier__c='Silver');   
        
        insert new List <Account> {a4, a5, a6, a7, a8};

        List <OpportunityStage> oppStage = [select ApiName,IsActive, IsClosed, IsWon, DefaultProbability from OpportunityStage where IsActive = true and DefaultProbability = 25 limit 1];

        Opportunity o1 = new Opportunity(Name='Test Opp 1', AccountId=a2.Id, StageName='Closed/Won',        Amount=100.0, CloseDate=lstPayoutDates[0].Masters_Annual_Date__c.date().addDays(-1), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Cancellation', Opportunity_Product__c = 'Email Subscription');
        Opportunity o2 = new Opportunity(Name='Test Opp 2', AccountId=a2.Id, StageName='Closed/Won',        Amount=100.0, CloseDate=lstPayoutDates[0].Masters_Annual_Date__c.date().addDays(-1), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Cancellation', Opportunity_Product__c = 'Email Subscription');
        Opportunity o3 = new Opportunity(Name='Test Opp 1', AccountId=a5.Id, StageName=oppStage[0].ApiName, Amount=100.0, CloseDate=lstPayoutDates[0].Masters_Annual_Date__c.date().addDays(-1), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Cancellation', Opportunity_Product__c = 'Email Subscription');
        Opportunity o4 = new Opportunity(Name='Test Opp 2', AccountId=a6.Id, StageName='Closed/Won',        Amount=100.0, CloseDate=lstPayoutDates[0].Masters_Annual_Date__c.date().addDays(-1), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Cancellation', Opportunity_Product__c = 'Email Subscription');
        Opportunity o5 = new Opportunity(Name='Test Opp 3', AccountId=a7.Id, StageName='Closed Won',        Amount=100.0, CloseDate=lstPayoutDates[0].Masters_Annual_Date__c.date().addDays(-1), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Expand: Organic Growth', Opportunity_Product__c = 'Email Subscription');
        insert new List <Opportunity> {o1, o2, o3, o4, o5};
                
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
    private static void testPartnerPayments()
    {
        List <Account> lstAccounts = [select Id, Name from Account order by Name];

        test.startTest();

        String paymnt = AccountTriggerHandler.getPaymentNameFormula(lstAccounts[0].Name);
        String unpaid = AccountTriggerHandler.getUnpaidName(lstAccounts[0].Name);

        AccountTriggerHandler.overrideMapAccount = true;
        update new List <Account> {
            new Account(Id=lstAccounts[0].Id, Trigger_Partner_Payout_Payment_New__c=true),
            new Account(Id=lstAccounts[1].Id, Trigger_Partner_Payout_Payment_New__c=true),
            new Account(Id=lstAccounts[2].Id, Trigger_Partner_Payout_Payment_New__c=true)
        };
        AccountTriggerHandler.overrideMapAccount = false;

        test.stopTest();
        
    }

    @isTest
    private static void testPartnerPayments_hasPayments() {
        AccountTriggerHandler.overrideHasReferralPartnerPayments = true;
        AccountTriggerHandler.overrideReferralPartnerPayments = true;
        try {
            testPartnerPayments();
            system.assert(true, 'There should not be an exception thrown.');
        }
        catch (Exception e) {
            system.assert(false, 'There should not be an exception thrown.');
        }
        AccountTriggerHandler.overrideHasReferralPartnerPayments = false;
        AccountTriggerHandler.overrideReferralPartnerPayments =false;
    }

    @isTest
    private static void testOneTimeBounty()
    {
        List <Account> lstAccounts = [select Id, Name, RP_Partner_Rev_Share_Payment_Method__c, RP_Referral_Partner_s_Main_Email__c from Account order by Name];

        test.startTest();

        AccountTriggerHandler.overrideReferralPartnerPayments = true;
        List <String> lstStr = AccountTriggerHandler.calculateOneTimeBounty(new List<Account> {lstAccounts[1]});
        AccountTriggerHandler.overrideReferralPartnerPayments = false;

        test.stopTest();
        
    }

    @isTest
    private static void testKPU_Insert ()
    {
        // If the TriggerDisablementSwitch has this disabled, enable it for this unit tests so
        // we can cover that code.
        TriggerDisablementSwitchHelper.mapSwitches.put('Klaviyo_Product_Usage_Creation_Triggers'.toLowerCase(), false);

        Account a = [Select Id, Klaviyo_Product_Usage__c from Account where Name='Test Account 1'];
        Klaviyo_Product_Usage__c kpu = [Select Id from Klaviyo_Product_Usage__c limit 1];
        System.assertEquals(kpu.Id, a.Klaviyo_Product_Usage__c);
    }

    @isTest
    private static void testKPU_Update ()
    {
        // If the TriggerDisablementSwitch has this disabled, enable it for this unit tests so
        // we can cover that code.
        TriggerDisablementSwitchHelper.mapSwitches.put('Klaviyo_Product_Usage_Creation_Triggers'.toLowerCase(), false);

        Account a = [Select Id, Klaviyo_Product_Usage__c from Account where Name='Test Account 2'];
        a.Product_Klaviyo_Account_ID__c = '3333';
        update a;

        Klaviyo_Product_Usage__c kpu = [Select Id from Klaviyo_Product_Usage__c where Klaviyo_Account_ID__c = '3333'];
        a = [Select Id, Klaviyo_Product_Usage__c from Account where Name='Test Account 2'];
        System.assertEquals(kpu.Id, a.Klaviyo_Product_Usage__c);
    }
  
    ////[RGaokar 10/5/2022 TP #89085 Method:updateMasterPartnerManagedMRR] 
    //test method for Master Partner Managed MRR roll up
    @isTest
    private static void testMasterPartnerManagedMRR()
    { 
        //update MRR
        Opportunity o = [Select id from Opportunity where name = 'Test Opp 3' limit 1];
        test.startTest();
        update (new opportunity (Id=o.Id, Amount = 200));
        List <Account> accList = [select Id,name, MRRCalc__c, Experts_Partner_Account__c, Total_MRR_of_Managed_Accounts__c from Account where name in ('Test Account 7', 'Test Account 8' )];
        Account partnerAcc = [Select id, Total_MRR_of_Managed_Accounts__c from Account where name = 'Test Account 3' limit 1];
        system.assertEquals(200, partnerAcc.Total_MRR_of_Managed_Accounts__c);
        
        //update Masters Partner Account 
        accList[0].Experts_Partner_Account__c = accList[1].id;
        update accList[0];
        List <Account> partnerAccList = [select Id,Total_MRR_of_Managed_Accounts__c from Account where name in ('Test Account 3', 'Test Account 8' )];
        system.assertEquals(0, partnerAccList[0].Total_MRR_of_Managed_Accounts__c);
        system.assertEquals(200, partnerAccList[1].Total_MRR_of_Managed_Accounts__c);
                
        //update Agency Retainer Status
        //Pending
        accList[0].RP_Agency_Experts_Accounts_Status__c = 'Pending';
        update accList[0];
        Account pendingPartnerAcc = [Select id, Total_MRR_of_Managed_Accounts__c from Account where name = 'Test Account 8' limit 1];
        system.assertEquals(0, pendingPartnerAcc.Total_MRR_of_Managed_Accounts__c);
        //Active - No Payout
        accList[0].RP_Agency_Experts_Accounts_Status__c = 'Active - No Payout';
        update accList[0];
        Account activeNPPartnerAcc = [Select id, Total_MRR_of_Managed_Accounts__c from Account where name = 'Test Account 8' limit 1];
        system.assertEquals(200, activeNPPartnerAcc.Total_MRR_of_Managed_Accounts__c);
        //Archived
        accList[0].RP_Agency_Experts_Accounts_Status__c = 'Archived';
        update accList[0];
        Account newPartnerAcc = [Select id, Total_MRR_of_Managed_Accounts__c from Account where name = 'Test Account 8' limit 1];
        system.assertEquals(0, newPartnerAcc.Total_MRR_of_Managed_Accounts__c);
        test.stopTest();
    }
    
    //[RGaokar 11/12/2021 TP #90961 Method: AlexaRankUpdate] Test method for Alexa rank 
   @isTest 
   static void testAlexaRank(){ 
       List<Account> accList = new List<Account>(); 
       for(integer i = 0; i<1;i++){ //[RGaokar 08/24/2022 SFDC-697 Changing account count from 2 to 1]
            Account acc = new Account(Name='Test Account '+i);
            accList.add(acc);
        }
       accList[0].Website = 'www.test.com';
       //accList[1].Website = 'http/http/http/null';//[RGaokar 08/24/2022 SFDC-697 Changing account count from 2 to 1]
       Test.StartTest();
       insert accList;
       accList[0].Website = 'www.test1.com';
       update accList[0];
       Test.StopTest();
    }
    
    //[VRajapatruni 12/02/2021 TP #91911] Test method for updateAccountRollUp
    @isTest
    private static void testAccountMRRRollUp()
    {    
        
        Test.startTest();
        
        Set<Id> acctIds = new Set<Id>();
        List <Account> mrrAccList = [select Id, ParentId,
                                             Parent.ParentId,
                                             Parent.Parent.ParentId,
                                             Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.Parent.ParentId,
                                             Total_MRR_of_Child_Accounts__c from Account limit 10 ];
        
        mrrAccList[0].ParentId = mrrAccList[2].id;
        update mrrAccList[0];
        
        acctIds.add(mrrAccList[0].id);
        acctIds.add(mrrAccList[1].id);
        
        //Call the MRR Roll up batch class using the account Ids
        Database.executeBatch(new AccountMRRRollUpUpdateBatch(acctIds), 10);
        System.debug('Total_MRR_of_Child_Accounts__c ' +mrrAccList[0].Total_MRR_of_Child_Accounts__c);
        system.assertEquals(null, mrrAccList[0].Total_MRR_of_Child_Accounts__c);
        system.assertEquals(null, mrrAccList[1].Total_MRR_of_Child_Accounts__c); 
        
        Test.StopTest(); 
       
    }
    
    //[VRajapatruni 12/02/2021 TP #91911] Test method for KlaviyoAccountSync
    static testMethod void testAccountTrigger() {
        /** Test the trigger on an Account for insert & update runs successfully. */
        Test.startTest();

        List<User> users = [SELECT Id FROM User WHERE userType='Standard' LIMIT 1];
        Id userId = users.get(0).Id;
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User usr = new User(Id = userId,
                            LastName = 'person',
                            FirstName='Test',
                            Alias = 'tperson',
                            Email = 'test.person@email.com',
                            Username = 'test.person@email.com',
                            ProfileId = p.Id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        
        Account acct = new Account(Name='### Test Account ###',
                                      Product_Klaviyo_Account_ID__c = 'abc123');
        // Set new account Owner
        acct.OwnerId = usr.Id;
        acct.Onboarding_Specialist__c = usr.Id;
        insert acct;
        // Set new CSM
        acct.Channel_Manager__c = usr.Id;
        update acct;

        Test.stopTest();
        
    }
    
    //[VRajapatruni 12/02/2021 TP #91911] Test method for updateAssociatedAccounts
    @isTest
    private static void testAssociatedAccounts(){
        
        Test.StartTest();
        
        // Insert an account for a specific user
        Account aaa = new Account(Name='Test Account AA', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '12127');
        aaa.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        aaa.FINANCE_Payment_Method__c = 'Stripe';
        insert aaa;
        
        List<User> users = [SELECT Id FROM User WHERE userType='Standard' LIMIT 1];
        Id userId = users.get(0).Id;
        aaa.ownerID = userId;
        update aaa;
        
        // Retrieve the users associated accounts and validate the count
        List <User> userList = [select Id, Associated_Accounts__c from User where id =: userinfo.getuserid()];
        // Using Not equals 0 instead of equals 5 in order to avoid any issues if any new accounts are added in the future
        // system.assertNotEquals(0, userList[0].Associated_Accounts__c);
        
        delete aaa;
        
        Test.StopTest(); 
        
    }
    
    
    //[VRajapatruni 12/02/2021 TP #91911] Test method for UpdateTargetAccountLeadStatus. 
    @isTest
    private static void testTargetAccountDQtest(){
        
        Test.StartTest();
        
        Account atad = new Account(Name='Test Account DQ', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '12126', Target_Account_Status__c = 'Untouched');
        atad.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        atad.FINANCE_Payment_Method__c = 'Stripe';
        atad.Current_Email_Platform__c = 'Klaviyo';
        atad.Ecommerce_Platform__c = 'Shopify';
        atad.Medal__c = 'Tier 1';
        atad.Country__c = 'United States'; 
        insert atad;
        
        Lead ltad = new Lead(FirstName = 'Test Lead', LastName = 'Test Last name', Account__c = atad.Id, Company = 'Test Company');
        insert ltad;
        
        List <Account> tapAccListInsert = [select Id, Target_Account_Status__c from Account where name in ('Test Account DQ') limit 1];
        system.assertEquals('Untouched', +tapAccListInsert[0].Target_Account_Status__c);
        
        atad.Target_Account_Status__c = 'DQ - Do not Contact';
        update atad;
        
        List <Account> tapAccListUpdate = [select Id, Target_Account_Status__c from Account where name in ('Test Account DQ') limit 1];
        system.assertEquals('Untouched', +tapAccListInsert[0].Target_Account_Status__c);
        
        Test.StopTest();
        
    }
    
    //[VRajapatruni 12/02/2021 TP #91911] Test method for AccountTransferToPlaceholder. 
    @isTest
    private static void testAccountTransferToPlaceholder(){
        
        Test.StartTest();
        
        Account attp = new Account(Name='Test Account TransferToPH', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '12123');
        attp.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        attp.FINANCE_Payment_Method__c = 'Stripe';
        insert attp;
        
        Lead ltop = new Lead(FirstName = 'Test Account', LastName = 'TransferToPH', Account__c = attp.Id, Company = 'Test Company TOP');
        insert ltop;
        
        attp.Transfer_to_Spec_Ops_Placeholder__c  = true;
        attp.Transfer_to_Core_Placeholder__c = true;
        Update attp;
        
        List <Account> transferToPHAccList = [select Id, ownerId from Account where name like '%TransferToPH%' limit 1];
        system.assertEquals(System.label.Core_Placeholder_Id, +transferToPHAccList[0].ownerId);  
        
        Test.StopTest(); 
         
    }
    
    //[RGaokar 09/14/2022] SFDC-207 Automation Cleanup - Moving calcRegionForCountryCode & calcRegionForCountry in Account before save flow
    //[VRajapatruni 12/02/2021 TP #91911] Test method for calcRegionForCountryCode and calcRegionForCountry. 
   /* @isTest
    private static void testUpdateAccountRegionForCountry(){
    
        Test.StartTest();
        
        Account aar1 = new Account(Name='TestAccountA1.com', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '12125', Country__c = 'United States');
        aar1.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        aar1.FINANCE_Payment_Method__c = 'Stripe';
        aar1.Target_Account_Status__c = 'Untouched';
        aar1.Current_Email_Platform__c = 'Klaviyo';
        aar1.Ecommerce_Platform__c = 'Shopify';
        aar1.Medal__c = 'Tier 1'; 
        insert aar1; 
        
        Account aar2 = new Account(Name='TestAccountA2.com', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = '121214', Country__c = 'Canada');
        aar2.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Klaviyo Account').getRecordTypeId(); 
        aar2.FINANCE_Payment_Method__c = 'Stripe';
        aar2.Target_Account_Status__c = 'Untouched';
        aar2.Current_Email_Platform__c = 'Klaviyo';
        aar2.Ecommerce_Platform__c = 'Shopify';
        aar2.Medal__c = 'Tier 1'; 
        insert aar2;
        
        List <Account> accRegionAccListInsert = [select Id, SALES_Geographical_Location__c from Account where name in ('TestAccountA2.com') limit 1];
        system.assertEquals('Canada', +accRegionAccListInsert[0].SALES_Geographical_Location__c);
        
        aar2.Country__c = 'United States';
        update aar2;
        
        List <Account> accRegionAccListUpdate1 = [select Id, SALES_Geographical_Location__c from Account where name in ('TestAccountA2.com') limit 1];
        system.assertEquals('US', +accRegionAccListUpdate1[0].SALES_Geographical_Location__c);
        
        aar2.SALES_Geographical_Location__c = null;
        update aar2;
        
        Database.executeBatch(new AccountRegionForCountryBatch(),10);
        
        List <Account> accRegionAccListUpdate2 = [select Id, SALES_Geographical_Location__c from Account where name in ('TestAccountA2.com') limit 1];
        system.assertEquals(null, +accRegionAccListUpdate2[0].SALES_Geographical_Location__c);
        
        Test.StopTest();
          
    }*/
    
    //[RGaokar 08/18/2022 SFDC-524 Charm Revenue Rollup Scheduler]
    @isTest
    private static void testCharmRollup(){
        Map <String,Schema.RecordTypeInfo> accRecordTypeMap = Account.sObjectType.getDescribe().getRecordTypeInfosByName();//[RGaokar 08/18/2022 SFDC-524 Charm Revenue Rollup Scheduler - Get account record type]
        //Create Parent Accounts
        Account ParentLevel1 = new Account(Name='Level 1', recordtypeId = accRecordTypeMap.get('Parent Account').getRecordTypeId());//Top Level Parent
        Account ParentLevel2 = new Account(Name='Level 2', recordtypeId = accRecordTypeMap.get('Parent Account').getRecordTypeId());
        Account ParentLevel3 = new Account(Name='Level 3', recordtypeId = accRecordTypeMap.get('Parent Account').getRecordTypeId());
        Account ParentLevel4 = new Account(Name='Level 4', recordtypeId = accRecordTypeMap.get('Parent Account').getRecordTypeId());
        Account ParentLevel5 = new Account(Name='Level 5', recordtypeId = accRecordTypeMap.get('Parent Account').getRecordTypeId());
        List<Account> parentAccounts = new List <Account> {ParentLevel1, ParentLevel2, ParentLevel3, ParentLevel4,ParentLevel5};
        insert parentAccounts;
        
        //Add parents in account hierarchy
        ParentLevel5.ParentId = ParentLevel4.id;
        ParentLevel4.ParentId = ParentLevel3.id;
        ParentLevel3.ParentId = ParentLevel2.id;
        ParentLevel2.ParentId = ParentLevel1.id;
        update parentAccounts;
        
        test.startTest();
        //Create child account
        Account acc = new Account(Name = 'Child Account', website = 'https://www.google.com', parentId = ParentLevel4.Id, recordtypeId = accRecordTypeMap.get('Klaviyo Account').getRecordTypeId());
        insert acc;
        List <Account> accList = [Select id, Clean_Website__c from Account where id =:acc.Id];
        
        //Charm revenue update
        CharmDataEnrichmentCallouts.processCharmCallouts(accList);
        
        //Charm rollup update
        String sch = '0 0 23 * * ?';
        CharmRevenueRollupScheduler charmRollupSch = new CharmRevenueRollupScheduler();
        system.schedule('Test Charm Roll Up Scheduler', sch, charmRollupSch);
      
        //delete child
        delete accList[0];
        
        //undelete child
        undelete accList[0];
        
        //Update Parent
        accList[0].parentId = ParentLevel5.Id;
        update accList[0];
        
        //Charm rollup update
        CharmRevenueRollupScheduler charmRollupSch2 = new CharmRevenueRollupScheduler();
        system.schedule('Test Charm Roll Up Scheduler 2', sch, charmRollupSch2);
        
        test.stopTest();
    }
    
}
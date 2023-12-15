/* Class:       LeadTriggerHandlerTest
 * Created On:
 * Created by:
 * Description: Unit tests for the LeadTriggerHandler class
 */
@isTest
public class LeadTriggerHandlerTest {
    
    @isTest
    static void testBeforeUpdate() {
        // If the functionality is disabled, we'll still do some testing to get code coverage
        Boolean leadTriggerIsDisabled = TriggerDisablementSwitchHelper.isDisabled('Lead_MQL_And_Workable');

        Lead oldLead = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com');
        insert oldLead;

        oldLead =
            [select Id, FM_MQL_Flag__c,  FORMULA_Workable_Lead__c, MQL_Date__c, Workable_Date__c
            from   Lead
            where  Id = :oldLead.Id];

        if (!leadTriggerIsDisabled) {
            system.assert(!oldLead.FM_MQL_Flag__c);
            system.assert(!oldLead.FORMULA_Workable_Lead__c);
            system.assert(oldLead.MQL_Date__c != Date.today());
            system.assert(oldLead.Workable_Date__c != Date.today());
        }

        update oldLead;

        oldLead =
        [select Id, FM_MQL_Flag__c,  FORMULA_Workable_Lead__c, MQL_Date__c, Workable_Date__c
        from   Lead
        where  Id = :oldLead.Id];

        if (!leadTriggerIsDisabled) {
            system.assert(oldLead.MQL_Date__c != Date.today());
            system.assert(oldLead.Workable_Date__c != Date.today());
        }
    }
    
    @isTest
    static void testBeforeInsert() {
        // If the functionality is disabled, we'll still do some testing to get code coverage
        Boolean leadTriggerIsDisabled = TriggerDisablementSwitchHelper.isDisabled('Lead_MQL_And_Workable');

        Lead oldLead = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com');
        insert oldLead;

        oldLead =
        [select Id, FM_MQL_Flag__c,  FORMULA_Workable_Lead__c, MQL_Date__c, Workable_Date__c
        from   Lead
        where  Id = :oldLead.Id];

        if (!leadTriggerIsDisabled) {
            system.assert(!oldLead.FM_MQL_Flag__c);
            system.assert(!oldLead.FORMULA_Workable_Lead__c);
            system.assert(oldLead.MQL_Date__c != Date.today());
            system.assert(oldLead.Workable_Date__c != Date.today());
        }
    }

    //[RGaokar 10/06/2022] SFDC-213 Automation Cleanup - Commenting test method as calcRegionForCountryCode & calcRegionForCountry is moving to Lead before save flow
   /* @isTest
    static void testRegionMappings() {
        // If the functionality is disabled, we'll still do some testing to get code coverage
        Boolean mappingIsDisabled = TriggerDisablementSwitchHelper.isDisabled('Lead_Country_Code_And_Region_Mapping');

        // Get some of the valid mappings defined in a custom metadata type
        // Note: The Label field has the country
        List<Country_and_Region_Mapping__mdt> lstMappings =
            [select id, Label, Country_Code__c, Region__c
             from   Country_and_Region_Mapping__mdt
             limit 2];

        if (lstMappings.size() != 2) {
            // There aren't enough mappings defined for us to run this test. Skip it.
            return;
        }

        Lead ld = TestData.buildLead('testLead', 'TestCompany', 'test@test.com');

        // Set the Lead's "Country Indicated at Signup" (MARKETING_SignupFormField_7__c)
        // to match lstMappings[0]'s.
        // Trigger should change its Region to match lstMappings[0]'s too
        ld.MARKETING_SignupFormField_7__c = lstMappings[0].Country_Code__c;
        insert ld;

        ld = [select id, SALES_Geographical_Location__c from Lead where id=:ld.Id];
        if (!mappingIsDisabled) {
            System.assertEquals(lstMappings[0].Region__c, ld.SALES_Geographical_Location__c);
        }

        // Clear the Lead's region
        ld.SALES_Geographical_Location__c = null;
        update ld;

        ld = [select id, SALES_Geographical_Location__c from Lead where id=:ld.Id];
        if (!mappingIsDisabled) {
            System.assertEquals(null, ld.SALES_Geographical_Location__c);
        }

        // Update the Lead's "Country Indicated by Rep" (Country_Location__c)
        // to match lstMapping[0]'s.
        // Trigger should update the region.
        ld.Country_Location__c = lstMappings[1].Label;
        update ld;

        ld = [select id, SALES_Geographical_Location__c from Lead where id=:ld.Id];
        if (!mappingIsDisabled) {
            System.assertEquals(lstMappings[1].Region__c, ld.SALES_Geographical_Location__c);
        }
    }*/

    @isTest
    static void testKPULinkInsert() {

        // If the TriggerDisablementSwitch has this disabled, enable it for this unit tests so
        // we can cover that code.
        TriggerDisablementSwitchHelper.mapSwitches.put('Klaviyo_Product_Usage_Creation_Triggers'.toLowerCase(), false);

        Lead l = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com');
        l.Klaviyo_Account_ID__c = '123456';
        insert l;

        l = [select Id, Klaviyo_Product_Usage__c from Lead where  Id = :l.Id];
        System.assertNotEquals(null, l.Klaviyo_Product_Usage__c);

        Klaviyo_Product_Usage__c kpu = new Klaviyo_Product_Usage__c(Klaviyo_Account_ID__c='456789');
        insert kpu;
        
        kpu.Contact_at_Close_Date__c = 1000;
        kpu.PRODUCT_of_Emailable_Profiles__c = 1000;
        update kpu;

        Lead l2 = TestData.buildLead('gfdff', 'retgssrtrt', 'fsdfdf@hghgh.com');
        l2.Klaviyo_Account_ID__c = '456789';
        insert l2;

        l2 = [select Id, Klaviyo_Product_Usage__c from Lead where  Id = :l2.Id];
        System.assertEquals(kpu.Id, l2.Klaviyo_Product_Usage__c);
    }

    @isTest
    static void testKPULinkUpdate() {

        // If the TriggerDisablementSwitch has this disabled, enable it for this unit tests so
        // we can cover that code.
        TriggerDisablementSwitchHelper.mapSwitches.put('Klaviyo_Product_Usage_Creation_Triggers'.toLowerCase(), false);

        Lead l = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com');

        insert l;

        l = [select Id, Klaviyo_Product_Usage__c from Lead where  Id = :l.Id];
        System.assertEquals(null, l.Klaviyo_Product_Usage__c);

        l.Klaviyo_Account_ID__c = '123456';
        update l;

        l = [select Id, Klaviyo_Product_Usage__c from Lead where  Id = :l.Id];
        System.assertNotEquals(null, l.Klaviyo_Product_Usage__c);
    }

// [vrajapatruni 01/06/2020] 
/*@isTest
    static void Stamp_RP_Time_of_Lead_Submission() {

        TriggerDisablementSwitchHelper.mapSwitches.put('Klaviyo_Product_Usage_Creation_Triggers'.toLowerCase(), false);
        
        Account acc = TestData.buildAccount('Test Account'); 
        insert acc;
        
        Account acc2= TestData.buildAccount('Test Account2'); 
        insert acc2;
        
        Lead l = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com');
        l.Referral_Partner_Account__c = acc.id;
        l.LeadSource = 'Inbound';
        insert l;

        l = [select Id, Klaviyo_Product_Usage__c from Lead where  Id = :l.Id];
        System.assertEquals(null, l.Klaviyo_Product_Usage__c);

        l.Klaviyo_Account_ID__c = '123456';
        l.Referral_Partner_Account__c = acc2.id;
        l.LeadSource = 'Inbound';
        update l;
        
        l = [select Id, Klaviyo_Product_Usage__c from Lead where  Id = :l.Id];
        System.assertNotEquals(null, l.Klaviyo_Product_Usage__c);
        
    }*/

//[RGaokar 04/18/2022 TP #117943 Method Stamp_Sales_Initial_Stamp_of_Working_BDR reverted back to apex and removed from before save flow as Leandata trigger is not processing flow logic]
//[RGaokar 03/28/2022 TP #92538 Method Stamp_Sales_Initial_Stamp_of_Working_BDR moved to lead before save flow, thus commenting test method]
// [vrajapatruni 01/14/2020] 
@isTest
    static void Stamp_Sales_Initial_Stamp_of_Working_BDR() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
        UserRole obj=new UserRole(Name= 'testStampWorkingBDR'); 
        insert obj; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg888.com', title = 'Product Specialist', UserRoleId = obj.Id);

        System.runAs(u) {
            
            Lead l = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com'); 
            l.LeadSource = 'Agency';
            l.MARKETING_Initial_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l.MARKETING_Initial_Lead_Source__c = 'Agency';
            l.MARKETING_Most_Recent_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l.Working_BDR__c = null; 
            l.Transferred_to_aBDR__c = false; 
            insert l;
    
            
        }     
    }

// [vrajapatruni 01/26/2021] 
//[12/29/2021 RGaokar TP #92539 The method Lead_No_Show_Update_Lead_status is moved to before save flow]
/*@isTest
    static void Lead_No_Show_Update_Lead_status(){

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
        UserRole obj=new UserRole(Name= 'testStampWorkingBDR'); 
        insert obj; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg888.com', title = 'Product Specialist', UserRoleId = obj.Id);

        System.runAs(u) {
            
            Lead l = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com'); 
            l.LeadSource = 'Agency';
            l.MARKETING_Initial_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l.MARKETING_Initial_Lead_Source__c = 'Agency';
            l.MARKETING_Most_Recent_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l.Working_BDR__c = null; 
            l.Transferred_to_aBDR__c = false; 
            l.Showed_for_Demo__c = 'No Show';
            insert l;
    
            
        }     
    }*/

// [vrajapatruni 01/26/2021] 
//[12/29/2021 RGaokar TP #92545 The method Lead_No_Show_Update_Lead_status_Email_Alert is moved to after save flow]
/*@isTest
    static void Lead_No_Show_Update_Lead_status_Email_Alert() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
        UserRole obj=new UserRole(Name= 'testStampWorkingBDR'); 
        insert obj; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg888.com', title = 'Product Specialist', UserRoleId = obj.Id);

        System.runAs(u) {
            
            Lead l = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com'); 
            l.LeadSource = 'Agency';
            l.MARKETING_Initial_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l.MARKETING_Initial_Lead_Source__c = 'Agency';
            l.MARKETING_Most_Recent_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l.Working_BDR__c = null; 
            l.Transferred_to_aBDR__c = false;
            l.Showed_for_Demo__c = 'No Show';
            insert l;
    
            
        }     
    }*/

// [vrajapatruni 02/17/2021] 
@isTest
    static void Stamp_Sales_Lead_Status_Date_Stamps() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; 
        UserRole obj=new UserRole(Name= 'testStampWorkingBDR'); 
        insert obj; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg888.com', title = 'Product Specialist', UserRoleId = obj.Id);

        System.runAs(u) {
            
            Lead l9 = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com'); 
            l9.LeadSource = 'Agency';
            l9.MARKETING_Initial_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l9.MARKETING_Initial_Lead_Source__c = 'Agency';
            l9.MARKETING_Most_Recent_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l9.Working_BDR__c = null; 
            l9.Transferred_to_aBDR__c = false;
            l9.Showed_for_Demo__c = 'No Show';
            
            insert l9;
            
            l9.status = 'Prequalified'; 
            update l9; 
                  
            Lead l1 = TestData.buildLead('Unalplara', 'TestCompany', 'test2@test.com'); 
            l1.LeadSource = 'Agency';
            l1.MARKETING_Initial_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l1.MARKETING_Initial_Lead_Source__c = 'Agency';
            l1.MARKETING_Most_Recent_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
            l1.Working_BDR__c = null; 
            l1.Transferred_to_aBDR__c = false;
            l1.Showed_for_Demo__c = 'No Show';
            
            insert l1;
            l1.status = 'Disqualified';
            update l1;
                   
        }  
    }
    
    //[RGaokar 03/03/2022 TP #92543] This method is moved to before save flow, so this method can be deleted once the 
    // Stamp_Sales_Initial_Touch_Time_Batch class is deleted.
    // [RGaokar 12/17/2021 Stamp_Sales_Initial_Touch_Time_Batch]    
   @isTest
    static void testStamp_Sales_Initial_Touch_Time_Batch(){
        Lead ld = new lead(Lastname ='testLead', Company = 'TestCompany', Email ='test@test.com',
                                     Status = 'Attempted', FLOW_Time_of_Initial_Touch__c = datetime.now());
        Test.StartTest();
        insert ld;
        List <id>listLeadIds = new List <id>();
        listLeadIds.add(ld.Id);
        Database.executeBatch(new Stamp_Sales_Initial_Touch_Time_Batch(listLeadIds),1);
        Test.StopTest();
        
        
    }
  
 // [RGaokar 11/10/2021 Alexa Rank test]    
   @isTest
    static void testAlexaRank(){
        List<Lead>ldList = new List<Lead>();
        for(integer i = 0; i<2;i++){
            Lead ld = TestData.buildLead('testLead '+i, 'TestCompany '+i, 'test'+i+'@test.com');
            ldList.add(ld);
        }
        ldList[0].Website = 'www.test.com';
        ldList[1].Website = 'http/http/http/null';
        Test.StartTest();
        insert ldList;
        ldList[0].Website = 'www.test1.com';
        update ldList[0];
        Test.StopTest();
    }
    
    // [RGaokar 12/06/2021 TP #97229]Match lead for deduplication logic
    // [RGaokar 12/09/2021 TP #97066]Merge lead based on deduplication logic    
   @isTest
    static void testLeadDeduplication(){
        List<User> userList = new List<User>();
        List<Account> accList = new List<Account>();
        List<Lead>existingLdList = new List<Lead>();
        List<Lead>newLdList = new List<Lead>();
        
        Profile salesProfile = [Select id from profile where name = 'AE Sales User'];
        Profile adminProfile = [Select id from profile where name = 'Primary Salesforce Admin'];
        
        Userrole bdrRole = [Select Id,DeveloperName from userrole where DeveloperName like 'iBDR' limit 1];
        
        Userrole PSRole = [Select Id,DeveloperName from userrole where DeveloperName like 'Product_Specialist' limit 1];
        
        Userrole GARole = [Select Id,DeveloperName from userrole where DeveloperName = 'GA' limit 1];

        User uBDR = new User(LastName = 'BDR User', email = 'bdr@test.com', username = 'bdr@test.com'+ UserInfo.getOrganizationId(),
                            profileid = salesProfile.Id, UserroleId = bdrRole.Id, Alias = 'bdruser', 
            				EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
            				TimeZoneSidKey='America/Los_Angeles');
        User uPS = new User(LastName = 'PS User', email = 'ps@test.com', username = 'ps@test.com'+ UserInfo.getOrganizationId(),
                            profileid = salesProfile.Id, UserroleId = PSRole.Id, Alias = 'psuser', 
            				EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
            				TimeZoneSidKey='America/Los_Angeles');
        User uAESales = new User(LastName = 'AE Sales User', email = 'ae@test.com', username = 'ae@test.com'+ UserInfo.getOrganizationId(),
                                 profileid = salesProfile.Id, UserroleId = bdrRole.Id, Alias = 'bdruser',EmailEncodingKey='UTF-8', 
                                 LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles');
        User sysAdmin = new User(LastName = 'Sys Admin User', email = 'admin@test.com', username = 'admin@test.com'+ UserInfo.getOrganizationId(),
                                 profileid = adminProfile.Id,UserroleId = GARole.Id,Alias = 'admuser',EmailEncodingKey='UTF-8', 
                                 LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles');
        userList.add(uBDR);
        userList.add(uPS);
        userList.add(uAESales);
        userList.add(sysAdmin);
        insert userList;
        
        System.runAs(sysAdmin){
            for(integer i = 0; i<10;i++){
                Lead ld = new lead(Lastname ='testLead '+i, Company = 'TestCompany '+i, Email ='test'+i+'@test.com',
                                  LeadSource = 'Partnership', MARKETING_Most_Recent_Lead_Source_Detail__c = 'Seminar / Conference',
                                  ownerid = sysAdmin.id);
                existingLdList.add(ld);
            }
            Account customerAcc = new Account(Name = 'Customer Account', ownerid = uAESales.id);
            Account partnerAcc = new Account (Name = 'Partner Account');
            accList.add(customerAcc);
            accList.add(partnerAcc);
            insert accList;
            
            //Campaign
            Campaign cp = new Campaign(Name = 'Test Campaign');
            insert cp;
            
            // existing matching customer lead
            for(integer i = 0; i<2;i++){
                existingLdList[i].Account__c = customerAcc.id;
                existingLdList[i].Website = 'www.testAccount.com';
            }
            existingLdList[0].Klaviyo_Account_ID__c = 'test1';
            
            // existing matching partner lead
            for(integer i = 2; i<4;i++){
                existingLdList[i].Referral_Partner_Account__c = partnerAcc.Id;
                existingLdList[i].Website = 'www.testPartner.com';
            }
            existingLdList[2].Klaviyo_Account_ID__c = 'test3';
            
            // existing matching inbound lead
            existingLdList[4].ownerid = uBDR.id;
            existingLdList[4].Status = 'Untouched';
            existingLdList[4].Website = 'www.testInbound.com';
            existingLdList[4].Klaviyo_Account_ID__c = 'test5';
            existingLdList[5].ownerid = uPS.Id;
            existingLdList[5].Status = 'Attempted';
            existingLdList[5].Website = 'www.testInbound.com';
            
            // existing matching qualified lead
            existingLdList[6].ownerid = uPS.Id;
            existingLdList[6].Status = 'Qualified - Passed to Sales Rep';
            existingLdList[6].Website = 'www.testQualified.com';
            existingLdList[6].Klaviyo_Account_ID__c = 'test7';
            existingLdList[7].ownerid = uAESales.Id;
            existingLdList[7].Status = 'Qualified - No Show';
            existingLdList[7].FLOW_Flip_Date_Time__c = Date.Today().addDays(-90);
            existingLdList[7].Flip_Reject_Approval_Status__c = 'Rejected';
            existingLdList[7].Website = 'www.testQualified.com';
            
            // existing email matching lead
            existingLdList[8].Website = 'www.testEmailMatch.com';
            existingLdList[9].Website = 'www.testEmailMatch.com';
            
            insert existingLdList;
            for(integer i = 0; i<10;i++){
                Test.setCreatedDate(existingLdList[i].Id, Date.Today().addDays(-2));
            }
            
            Test.StartTest();
            //New leads
            for(Integer i = 10; i<20; i++){
                Lead ld = New lead(Lastname ='testLead '+i, Company = 'TestCompany '+i, LeadSource = 'Inbound',
                                   MARKETING_Most_Recent_Lead_Source_Detail__c = 'Internal Email',
                                   MostRecentCampaignID__c = cp.id,
                                   MARKETING_utm_Content_Last__c = 'new', MARKETING_utm_Medium_Last__c = 'new',
                                   MARKETING_utm_Source_Last__c = 'new', MARKETING_utm_Term_Last__c = 'new',
                                   PRODUCT_DateTime_Free_Account_Creation__c = DateTime.newInstance(2010,12,12),
                                   PRODUCT_Date_Time_of_Last_Demo_Request__c = DateTime.newInstance(2010,12,12),
                                   Phone = '1111',MARKETING_utm_Campaign_Last__c = 'Test Campaign',
                                   ownerid = sysAdmin.id);
                newLdList.add(ld);
            }
            
            //new customer lead
            for(integer i = 0; i<2;i++){
                newLdList[i].Account__c = customerAcc.id;
                newLdList[i].Website = 'www.testAccount.com';
            }
            newLdList[0].Klaviyo_Account_ID__c = 'test10';
            newLdList[0].Email = 'test1@test.com';
            newLdList[1].Email = 'test0@test.com';
            
            //new partner lead
            newLdList[2].Klaviyo_Account_ID__c = 'test12';
            newLdList[2].Email = 'test2@test.com';
            newLdList[2].Website = 'www.testPartner.com';
            newLdList[3].Email = 'test3@test.com';
            newLdList[3].Website = 'www.testPartner.com';
            
            //new Inbound lead
            newLdList[4].Klaviyo_Account_ID__c = 'test14';
            newLdList[4].Email = 'test4@test.com';
            newLdList[4].Website = 'www.testInbound.com';
            newLdList[5].Email = 'test5@test.com';
            newLdList[5].Website = 'www.testInbound.com';
            
            //new Qualified lead
            newLdList[6].Klaviyo_Account_ID__c = 'test16';
            newLdList[6].Email = 'test6@test.com';
            newLdList[6].Website = 'www.testQualified.com';
            newLdList[7].Email = 'test7@test.com';
            newLdList[7].Website = 'www.testQualified.com';
            
            //new Email Match lead
            newLdList[8].Klaviyo_Account_ID__c = 'test18';
            newLdList[8].Email = 'test8@test.com';
            newLdList[8].Website = 'www.testEmailMatch.com';
            newLdList[9].Email = 'test9@test.com';
            newLdList[9].Website = 'www.testEmailMatch.com';
            
            insert newLdList;
            
            Map<id, lead> newInsertedLead = new Map<id, lead>([Select id,Matched_Lead__c from lead where id in:newLdList]);
            
            system.assertEquals(existingLdList[1].id, newInsertedLead.get(newLdList[0].id).Matched_Lead__c);//customer lead with Klaviyo Acc
            system.assertEquals(existingLdList[0].id, newInsertedLead.get(newLdList[1].id).Matched_Lead__c);//customer lead
            
            system.assertEquals(existingLdList[5].id, newInsertedLead.get(newLdList[4].id).Matched_Lead__c);//Inbound lead with Klaviyo Acc
            system.assertEquals(existingLdList[5].id, newInsertedLead.get(newLdList[5].id).Matched_Lead__c);//Inbound lead
            
            system.assertEquals(existingLdList[7].id, newInsertedLead.get(newLdList[6].id).Matched_Lead__c);//Qualified lead with Klaviyo Acc
            system.assertEquals(existingLdList[7].id, newInsertedLead.get(newLdList[7].id).Matched_Lead__c);//Qualified lead
            
            system.assertEquals(existingLdList[8].id, newInsertedLead.get(newLdList[8].id).Matched_Lead__c);//Email Match lead with Klaviyo Acc
            system.assertEquals(existingLdList[9].id, newInsertedLead.get(newLdList[9].id).Matched_Lead__c);//Email Match lead
            Test.StopTest();
        }
    }

}
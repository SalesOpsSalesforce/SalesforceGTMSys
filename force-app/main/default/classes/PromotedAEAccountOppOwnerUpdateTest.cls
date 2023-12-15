@isTest
public class PromotedAEAccountOppOwnerUpdateTest {
    @isTest
    private static void testPromotedAEAccountOppOwnershipChange(){
        Profile AEProfile = [Select id from profile where name = 'AE Sales User'];
        Profile salesManagerProfile = [Select id from profile where name = 'Sales Management User'];
        Profile adminProfile = [Select id from profile where name = 'Primary Salesforce Admin'];
        Userrole GARole = [Select Id,DeveloperName from userrole where DeveloperName = 'GA' limit 1];
        Id roleChangeRquestRecordTypeId = Schema.SObjectType.Sales_Ops_Request__c.getRecordTypeInfosByDeveloperName().get('Role_Change').getRecordTypeId();
        
        //Create users
        List<user> userList = new List<user>();
        userList.add(new User(LastName = 'Promoted AE User1', email = 'AE1@test.com', username = 'AE1@test.com'+ UserInfo.getOrganizationId(),
                              profileid = AEProfile.Id,UserroleId = GARole.Id,Alias = 'ae1user',EmailEncodingKey='UTF-8', 
                              LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles'));
        
        userList.add(new User(LastName = 'Promoted AE User2', email = 'AE2@test.com', username = 'AE2@test.com'+ UserInfo.getOrganizationId(),
                              profileid = AEProfile.Id,UserroleId = GARole.Id,Alias = 'ae2user',EmailEncodingKey='UTF-8', 
                              LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles'));
        
        userList.add(new User(LastName = 'Manager User', email = 'manager@test.com', username = 'manager@test.com'+ UserInfo.getOrganizationId(),
                              profileid = salesManagerProfile.Id,UserroleId = GARole.Id,Alias = 'mguser',EmailEncodingKey='UTF-8', 
                              LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles'));
        
        userList.add(new User(LastName = 'Sys Admin User', email = 'admin@test.com', username = 'partnersysadmin@test.com'+ UserInfo.getOrganizationId(),
                                 profileid = adminProfile.Id,UserroleId = GARole.Id,Alias = 'admuser',EmailEncodingKey='UTF-8', 
                                 LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles'));
        
        //AEs for Account without opportunity
        userList.add(new User(LastName = 'Promoted AE User3', email = 'AE3@test.com', username = 'AE3@test.com'+ UserInfo.getOrganizationId(),
                              profileid = AEProfile.Id,UserroleId = GARole.Id,Alias = 'ae3user',EmailEncodingKey='UTF-8', 
                              LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles'));
        
        userList.add(new User(LastName = 'Promoted AE User4', email = 'AE4@test.com', username = 'AE4@test.com'+ UserInfo.getOrganizationId(),
                              profileid = AEProfile.Id,UserroleId = GARole.Id,Alias = 'ae4user',EmailEncodingKey='UTF-8', 
                              LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles'));
        insert userList;
        
        System.runAs(userList[3]){
            //Create accounts
            List<account> customerAccList = new List<account>();
            customerAccList.add(new Account(Name = 'Test Account 1', Product_Klaviyo_Account_ID__c = 'KID123', ownerid = userList[0].id));//With opportunities
            customerAccList.add(new Account(Name = 'Test Account 2', Product_Klaviyo_Account_ID__c = 'KID456', ownerid = userList[1].id));//With opportunities
            customerAccList.add(new Account(Name = 'Test Account 3', Product_Klaviyo_Account_ID__c = 'KID321', ownerid = userList[4].id));//Without opportunities
            customerAccList.add(new Account(Name = 'Test Account 4', Product_Klaviyo_Account_ID__c = 'KID654', ownerid = userList[5].id));//Without opportunities
            insert customerAccList;
            customerAccList[1].Similarweb_Total_Visits__c = 30000;//New Business Territory = MM
            customerAccList[3].Similarweb_Total_Visits__c = 30000;//New Business Territory = MM
            update customerAccList;
            
            //Create Opportunities
            List<opportunity> oppList = new List<opportunity>();
            oppList.add(new Opportunity(Name = 'Test Opp 1', Accountid = customerAccList[0].id, Closedate = date.today(), StageName = 'S1: Evaluation', Amount = 100, ownerid = userList[0].id, Opportunity_Product__c = 'Email Subscription'));
            oppList.add(new Opportunity(Name = 'Test Opp 2', Accountid = customerAccList[1].id, Closedate = date.today(), StageName = 'S1: Evaluation', Amount = 100, ownerid = userList[1].id, Opportunity_Product__c = 'Email Subscription'));
            insert oppList;
            
            //Create Role Change Sales Op Request
            List<Sales_Ops_Request__c> requests = new List<Sales_Ops_Request__c>();
            requests.add(new Sales_Ops_Request__c(Sales_Rep__c = userList[0].id, Role_Change_to__c = 'U SMB AE (I)', Role_Change_Effective_Date__c = Date.Today().addDays(-90), 
                                                  Request_Status__c = 'Completed', Previous_Manager__c = userList[2].id, recordtypeId=roleChangeRquestRecordTypeId));
            requests.add(new Sales_Ops_Request__c(Sales_Rep__c = userList[1].id, Role_Change_to__c = 'MM AE (I)', Role_Change_Effective_Date__c = Date.Today().addDays(-120), 
                                                  Request_Status__c = 'Completed', Previous_Manager__c = userList[2].id, recordtypeId=roleChangeRquestRecordTypeId));
            requests.add(new Sales_Ops_Request__c(Sales_Rep__c = userList[4].id, Role_Change_to__c = 'U SMB AE (I)', Role_Change_Effective_Date__c = Date.Today(), 
                                                  Request_Status__c = 'Completed', Previous_Manager__c = userList[2].id, recordtypeId=roleChangeRquestRecordTypeId));
            requests.add(new Sales_Ops_Request__c(Sales_Rep__c = userList[5].id, Role_Change_to__c = 'MM AE (I)', Role_Change_Effective_Date__c = Date.Today(), 
                                                  Request_Status__c = 'Completed', Previous_Manager__c = userList[2].id, recordtypeId=roleChangeRquestRecordTypeId));
            insert requests;
            
            //Run scheduler test
            Test.startTest();
            //Test Ownership change for accounts with open opportunities
            PromotedAEAccountOppOwnerUpdateScheduler testOwnerChange = new PromotedAEAccountOppOwnerUpdateScheduler();
            String sch = '0 0 23 * * ?';
            system.schedule('Test Promoted AE Account & opportunities Ownership Change', sch, testOwnerChange);
            
            //Test Ownership change for accounts without open opportunities 
            PromotedAERoleChangeTodayScheduler testRoleChangeToday = new PromotedAERoleChangeTodayScheduler();
            system.schedule('Test Promoted AE Account Ownership Change', sch, testRoleChangeToday);
            Test.stopTest();
        }
    }
}
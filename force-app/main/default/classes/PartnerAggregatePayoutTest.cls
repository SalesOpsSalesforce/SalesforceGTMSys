@isTest
private class PartnerAggregatePayoutTest {
    @isTest
    private static void testPartnerAggregatePayout(){
        Id klaviyoAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Klaviyo_Account').getRecordTypeId();
        Id partnerAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Referral_Partner_Account').getRecordTypeId();
        Profile adminProfile = [Select id from profile where name = 'Primary Salesforce Admin'];
        Userrole GARole = [Select Id,DeveloperName from userrole where DeveloperName = 'GA' limit 1];
        User sysAdmin = new User(LastName = 'Sys Admin User', email = 'admin@test.com', username = 'partnersysadmin@test.com'+ UserInfo.getOrganizationId(),
                                 profileid = adminProfile.Id,UserroleId = GARole.Id,Alias = 'admuser',EmailEncodingKey='UTF-8', 
                                 LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles');
        insert sysAdmin;
        
        System.runAs(sysAdmin){
            List<account> partnerAccList = new List<account>();
            partnerAccList.add(new Account(Name = 'Referral Partner Account', Services_Tier__c  = 'Silver', RecordtypeId = partnerAccRecordTypeId));
            partnerAccList.add(new Account(Name = 'Managed Partner Account', Experts_Tier__c  = 'Silver', RecordtypeId = partnerAccRecordTypeId));
            partnerAccList.add(new Account(Name = 'Platform Partner Account', Services_Tier__c = 'Silver', RecordtypeId = partnerAccRecordTypeId));
            insert partnerAccList;
            
            List<account> customerAccList = new List<account>();
            customerAccList.add(new Account(Name = 'Test Account - Referral Payout', Product_Klaviyo_Account_ID__c = 'KAI123', RecordtypeId = klaviyoAccRecordTypeId));
            customerAccList.add(new Account(Name = 'Test Account - Managed Payout', Product_Klaviyo_Account_ID__c = 'KAI456', RecordtypeId = klaviyoAccRecordTypeId, Experts_Partner_Account__c = partnerAccList[1].id, RP_Agency_Experts_Accounts_Status__c = 'Active'));
            customerAccList.add(new Account(Name = 'Test Account - Platform Payout', Product_Klaviyo_Account_ID__c = 'KAI789', RecordtypeId = klaviyoAccRecordTypeId));
            customerAccList.add(new Account(Name = 'Test Account - EOM Referral Payout', Product_Klaviyo_Account_ID__c = 'KAI321', RecordtypeId = klaviyoAccRecordTypeId));
            insert customerAccList;
            
            List<opportunity> oppList = new List<opportunity>();
            oppList.add(new Opportunity(Name = 'Referral Test Opp', Accountid = customerAccList[0].id, Closedate = date.today().addMonths(-1), StageName = 'S1: Evaluation', RP_Referral_Partner_Account__c = partnerAccList[0].id, Amount = 100, ownerid = sysAdmin.id, Opportunity_Product__c = 'Email Subscription'));
            oppList.add(new Opportunity(Name = 'Managed Test Opp', Accountid = customerAccList[1].id, Closedate = date.today().addMonths(-1), StageName = 'S1: Evaluation', Amount = 100, ownerid = sysAdmin.id, Opportunity_Product__c = 'Email Subscription'));
            oppList.add(new Opportunity(Name = 'Platform Test Opp', Accountid = customerAccList[2].id, Closedate = date.today().addMonths(-1), StageName = 'S1: Evaluation', Platform_Partner_Account__c = partnerAccList[2].id, Amount = 100, ownerid = sysAdmin.id, Opportunity_Product__c = 'Email Subscription'));
            oppList.add(new Opportunity(Name = 'Referral Test EOM Opp 1', Accountid = customerAccList[3].id, Closedate = date.today().addMonths(-1), StageName = 'S1: Evaluation', RP_Referral_Partner_Account__c = partnerAccList[0].id, Amount = 100, ownerid = sysAdmin.id, Opportunity_Product__c = 'Email Subscription'));
            insert oppList;
            
            oppList[0].stagename = 'Closed Won';
            oppList[1].stagename = 'Closed Won';
            oppList[2].stagename = 'Closed Won';
            oppList[3].stagename = 'Closed Won';
            update oppList;
            
            Test.startTest();
            List<Partner_Split__c> psList = new List<Partner_Split__c>();
            //Creating manual splits to avoid any faliures of split creation due to any opportunity or MPO logic changes.
            psList.add(new Partner_Split__c(Opportunity__c = oppList[0].id, Partner_Account__c  = partnerAccList[0].id, Customer_Account__c = customerAccList[0].id,
                                            Payout_Percent__c = 10, Payout__c = true, Partner_Type__c = 'Referral Partner', RevShare_of_Months__c = 12));
            psList.add(new Partner_Split__c(Opportunity__c = oppList[1].id, Partner_Account__c  = partnerAccList[1].id, Customer_Account__c = customerAccList[1].id,
                                            Payout_Percent__c = 10, Payout__c = true, Partner_Type__c = 'Managed'));
            psList.add(new Partner_Split__c(Opportunity__c = oppList[2].id, Partner_Account__c  = partnerAccList[2].id, Customer_Account__c = customerAccList[2].id,
                                            Payout_Percent__c = 10, Payout__c = true, Partner_Type__c = 'Platform Partner', RevShare_of_Months__c = 12));
            psList.add(new Partner_Split__c(Opportunity__c = oppList[3].id, Partner_Account__c  = partnerAccList[0].id, Customer_Account__c = customerAccList[3].id,
                                            Payout_Percent__c = 10, Payout__c = true, Partner_Type__c = 'Referral Partner', RevShare_of_Months__c = 12, EOM_Partner_Split__c = true));//EOM
            
            insert psList;
            
            
            //Insert Payments for Customers
            List<Klaviyo_Payment__c> paymentList = new List<Klaviyo_Payment__c>();
            paymentList.add(new Klaviyo_Payment__c(Account__c = customerAccList[0].id, Amount__c = 100, Payment_Date__c = date.today().addMonths(-1),
                                                   Klaviyo_Payment_Product__c = 'Email Subscription', Status__c = 'Succeeded'));
            paymentList.add(new Klaviyo_Payment__c(Account__c = customerAccList[1].id, Amount__c = 100,
                                                   Klaviyo_Payment_Product__c = 'Email Subscription', Status__c = 'Succeeded'));
            paymentList.add(new Klaviyo_Payment__c(Account__c = customerAccList[2].id, Amount__c = 100, Payment_Date__c = date.today().addMonths(-1),
                                                   Klaviyo_Payment_Product__c = 'Email Subscription', Status__c = 'Succeeded'));
            paymentList.add(new Klaviyo_Payment__c(Account__c = customerAccList[3].id, Amount__c = 100, Payment_Date__c = date.today().addMonths(-1),
                                                   Klaviyo_Payment_Product__c = 'Email Subscription', Status__c = 'Succeeded'));//EOM
            insert paymentList;
            
            
            //EOM opprtunity creation
            Opportunity OpportunityEOM = new Opportunity(Name = 'Referral Test EOM Opp 2', Accountid = customerAccList[3].id, Closedate = date.today().addMonths(-1), 
                                                         StageName = 'Closed Won', RP_Referral_Partner_Account__c = partnerAccList[0].id, Amount = 100, 
                                                         ownerid = sysAdmin.id, Opportunity_Product__c = 'Email Subscription');
            insert OpportunityEOM;
            
            
            Partner_Split__c EOMPS = new Partner_Split__c(Opportunity__c = OpportunityEOM.id, Partner_Account__c  = partnerAccList[0].id, Customer_Account__c = customerAccList[3].id,
                                            			  Payout_Percent__c = 10, Payout__c = true, Partner_Type__c = 'Referral Partner', RevShare_of_Months__c = 12, EOM_Partner_Split__c = true);
            insert EOMPS;
            
            PartnerAggregatePayoutCalculator.calculateAggregatePayout();
            Test.stopTest();
        }
    } 
}
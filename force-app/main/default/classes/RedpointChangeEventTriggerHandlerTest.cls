//[RGaokar 11/03/2022 SFDC - 1157 SF to Redpoint Helper Class for Redpoint Callouts]
@isTest
public class RedpointChangeEventTriggerHandlerTest {
    @testSetup
    static void dataSetup(){
        Profile salesProfile = [Select id from profile where name = 'AE Sales User'];
        
        List<User> userList = new List<User>();
        User uBDR1 = new User(FirstName = 'Test',LastName = 'BDR User 1', email = 'bdr1@test.com', username = 'bdr1@test.com'+ UserInfo.getOrganizationId(),
                              Alias = 'bdruser1', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                              TimeZoneSidKey='America/Los_Angeles', profileid = salesProfile.Id);
        User uBDR2 = new User(FirstName = 'Test',LastName = 'BDR User 2', email = 'bdr2@test.com', username = 'bdr2@test.com'+ UserInfo.getOrganizationId(),
                              Alias = 'bdruser2', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                              TimeZoneSidKey='America/Los_Angeles', profileid = salesProfile.Id);
        userList.add(uBDR1);
        userList.add(uBDR2);
        insert userList;
    }
    
    @isTest
    static void testAccountContactChangeEvents(){
        Test.enableChangeDataCapture();//Enable all Change Data Capture entities for notifications.
        List<User> userList = [Select id from User];
        Account parentAccount = new Account(Name = 'Parent Test Account');
        insert parentAccount;
        Account a = new Account(Name = 'Test Account', Industry = 'Automotive', Onboarding_Specialist__c = userList[0].Id);
        insert a;
        Contact c = new Contact(LastName = 'TestContact', AccountId = a.Id, Email = 'test@test.com');
        insert c;
        Test.getEventBus().deliver();//Call deliver to fire the trigger and deliver the create change event.
        
        //Update Account
        a.Industry = 'Education';
        a.Channel_Manager__c = userList[1].Id; 
        a.Onboarding_Specialist__c = null;
        a.ParentId = parentAccount.Id;
        //a.Paying_Parent__c = parentAccount.Id;
        update a;
        Test.getEventBus().deliver();//Call deliver to fire the trigger and deliver the account update change event.
        //Schedule Batch Test
        a.Failed_Redpoint_Sync__c = true;
        update a;
        
        //Update Contact
        //c.Phone = '12345667';
        c.Email = 'test123@test.com';
        update c;
        Test.getEventBus().deliver();//Call deliver to fire the trigger and deliver the contact update change event.
        
        //Schedule Batch Test
        c.Failed_Redpoint_Sync__c = true;
        update c;
        Test.startTest();
        RedpointFailedRecordSyncScheduler redpointSch = new RedpointFailedRecordSyncScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Redpoint Scheduler', sch, redpointSch);
        
        //KPU Redpoint_Formula_Sync_Widget batch test
        Klaviyo_Product_Usage__c kpu = new Klaviyo_Product_Usage__c (Klaviyo_Account_ID__c = 'Test1234', PRODUCT_Klaviyo_Account_Status__c = 'Active');
        insert kpu;
        a.Klaviyo_Product_Usage__c = kpu.Id;
        update a;
        kpu.PRODUCT_of_SMS_Subscribers__c = 200;
        update kpu;
        //Calling batch separately to get code coverage for first time deployment of flow & class together
        RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget param = new RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget();
        param.sObjId = a.Id;
        param.sObjectType = 'Account';
        List<RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget> paramList = new List<RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget>();
        paramList.add(param);
        RedpointKPUSyncWidgetBatch redpointWidget = new RedpointKPUSyncWidgetBatch(paramList);
        Database.executeBatch(redpointWidget);
        
        //KPU RedpointKPUNightlySyncWidget Scheduler & Batch test for Redpoint_Update__c = true
        kpu.Redpoint_Update__c = true;//Set Redpoint_Update__c flag
        update kpu;
        //Call scheduler class
        RedpointKPUSyncWidgetScheduler nightlySyncRedpointChanges = new RedpointKPUSyncWidgetScheduler();
        String schNightlySync = '0 0 23 * * ?';
        system.schedule('Test Redpoint Nightly Sync Scheduler', schNightlySync, nightlySyncRedpointChanges);
        Test.stopTest();
    }
    
    @isTest
    static void testLeadChangeEvents(){
        //Creating Users in this method as method is failing with no user 'name' error 
        Profile salesProfile = [Select id from profile where name = 'AE Sales User'];
        Profile adminProfile = [Select id from profile where name = 'Primary Salesforce Admin'];
        
        List<User> userList = new List<User>();
        User uBDR = new User(FirstName = 'Test',LastName = 'BDR User', email = 'bdr@test.com', username = 'bdr@test.com'+ UserInfo.getOrganizationId(),
                             Alias = 'bdruser', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                             TimeZoneSidKey='America/Los_Angeles', profileid = salesProfile.Id);
        User sysAdmin = new User(LastName = 'Sys Admin User', email = 'admin@test.com', username = 'admin@test.com'+ UserInfo.getOrganizationId(),
                                 profileid = adminProfile.Id,Alias = 'admuser',EmailEncodingKey='UTF-8', 
                                 LanguageLocaleKey='en_US', LocaleSidKey='en_US',TimeZoneSidKey='America/Los_Angeles');
        userList.add(uBDR);
        userList.add(sysAdmin);
        insert userList;
        
        System.runAs(sysAdmin){
            Test.enableChangeDataCapture();// Enable all Change Data Capture entities for notifications.
            Lead l = new Lead(LastName = 'TestContact', Company = 'Test Company', Email = 'test@test.com', Status = 'Untouched', OwnerId = userList[0].Id);
            insert l;
            Test.getEventBus().deliver();//Call deliver to fire the trigger and deliver the lead create change event.
            
            l.Status = 'Prequalified ';
            l.SALES_Current_Email_Platform__c = 'Klaviyo';
            update l;
            Test.getEventBus().deliver();//Call deliver to fire the trigger and deliver the lead update change event.
            
            //Schedule Batch Test
            l.Failed_Redpoint_Sync__c = true;
            update l;
            Test.startTest();
            RedpointFailedRecordSyncScheduler redpointSch = new RedpointFailedRecordSyncScheduler();
            String sch = '0 0 23 * * ?';
            system.schedule('Test Redpoint Scheduler', sch, redpointSch);
            
            //KPU Redpoint_Formula_Sync_Widget batch test
            Klaviyo_Product_Usage__c kpu = new Klaviyo_Product_Usage__c (Klaviyo_Account_ID__c = 'Test1234', PRODUCT_Klaviyo_Account_Status__c = 'Active');
            insert kpu;
            l.Klaviyo_Product_Usage__c = kpu.Id;
            update l;
            kpu.PRODUCT_of_SMS_Subscribers__c = 200;
            update kpu;
            //Calling batch separately to get code coverage for first time deployment of flow & class together
            RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget param = new RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget();
            param.sObjId = l.Id;
            param.sObjectType = 'Lead';
            List<RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget> paramList = new List<RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget>();
            paramList.add(param);
            RedpointKPUSyncWidgetBatch redpointWidget = new RedpointKPUSyncWidgetBatch(paramList);
            Database.executeBatch(redpointWidget);
            
            //[RGaokar 07/27/2023 SFDC:3218 Extending RedpointKPUSyncWidgetBatch class as a HELPER class to handle all use cases other than KPU]
            //Send related record for Redpoint Sync Widget Update
            RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget paramRelatedRecords = new RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget();
            paramRelatedRecords.sObjectType = 'Lead';
            List<sObject> relatedsObjRecords = new List<sObject>();
            relatedsObjRecords.add(l);
            paramRelatedRecords.relatedsObjRecords = relatedsObjRecords;
            List<RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget> paramRelatedRecordList = new List<RedpointKPUSyncWidgetBatch.paramRedpointSyncWidget>();
            paramRelatedRecordList.add(paramRelatedRecords);
            RedpointKPUSyncWidgetBatch.updateRedpointSyncWidget(paramRelatedRecordList);
            
            //KPU RedpointKPUNightlySyncWidget Scheduler & Batch test for Redpoint_Update__c = true
            kpu.Redpoint_Update__c = true;//Set Redpoint_Update__c flag
            update kpu;
            //Call scheduler class
            RedpointKPUSyncWidgetScheduler nightlySyncRedpointChanges = new RedpointKPUSyncWidgetScheduler();
            String schNightlySync = '0 0 23 * * ?';
            system.schedule('Test Redpoint Nightly Sync Scheduler', schNightlySync, nightlySyncRedpointChanges);
            Test.stopTest();
            
            //[RGaokar 09/12/2023 SFDC-3536 Shut down the direct call from SF to Redpoint]
            //[RGaokar 03/28/2023 SFDC-2233 Workato Task Reduction: Reduce frequency of calling Workato recipe]
            //Calling static method to make sure that there is an code coverage for both Workato Callout & direct callout
            /*List<RedpointCalloutHandler.RedpointRecordWrapper>payloadList = new List<RedpointCalloutHandler.RedpointRecordWrapper>();
            Lead l1 = new Lead(LastName = 'TestLead1', Company = 'Test Company', Email = 'test@test.com', Status = 'Untouched', OwnerId = userList[0].Id,
                               Klaviyo_Profile_ID__c = '2222');
            insert l1;
            List<lead> leadList = new List<lead>();
            leadList.add(l);
            leadList.add(l1);
            for(lead ld:leadList){
                map<string,object> leadRecordMap = new map<string,object>();
                leadRecordMap.put('SF_Id', ld.id);
                leadRecordMap.put('Industry', 'Education');
                leadRecordMap.put('email', ld.Email);
                leadRecordMap.put('Klaviyo_Profile_ID__c', ld.Klaviyo_Profile_ID__c);
                RedpointCalloutHandler.RedpointRecordWrapper payload = new RedpointCalloutHandler.RedpointRecordWrapper(leadRecordMap);
                payloadList.add(payload);
            }
            
            RedpointCalloutHandler.processRedpointAPIPayload(payloadList);
            map<string,string>processedRequestMap = new map<string,string>();
            processedRequestMap.put(l.Id, 'error message');
            RedpointCalloutHandler.processRedpointErrors(processedRequestMap);*/
        }
    }
}
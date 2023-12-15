//[RGaokar 2/27/2023 SFDC-1881 Diligent <> SFDC Processor Test]
@isTest
public class DiligentSearchProcessorTest {
    @isTest
    public static void testDiligentSearchProcess(){
        Id klaviyoAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Klaviyo_Account').getRecordTypeId();
        Id partnerAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Referral_Partner_Account').getRecordTypeId();
        Account a = new Account(Name = 'Test Account', Industry = 'Automotive', RecordtypeId = klaviyoAccRecordTypeId, website = 'facebook.com',
                                FINANCE_Payment_Method__c = 'Billed Under Parent Account');
        Test.startTest();
        insert a;
        
        Account partnerAcc = new Account(Name = 'Test Account', RecordtypeId = partnerAccRecordTypeId, website = 'test.com', Diligent_Term_Id__c = 9999 , Diligent_List_Id__c = 5555);
        insert partnerAcc;
        
        //Execute batches & queueable apex seperately for code coverage
        //Prepare a payload for asynchronous jobs
        List<DiligentSearchProcessor.DiligentPayload> diligentPayloads = new List<DiligentSearchProcessor.DiligentPayload>();
        DiligentSearchProcessor.DiligentPayload payload = new DiligentSearchProcessor.DiligentPayload();
        payload.term = a.website;
        payload.accountId = a.id;
        payload.country = 'USA';
        diligentPayloads.add(payload);
        
        //Calling DiligentSearchProcessor aynchronous jobs
        DiligentSearchProcessor.getDiligentSearchTerms(diligentPayloads);// Queueable
        Database.executeBatch(new DiligentSearchBatch(diligentPayloads), 100);//Batch
        
        //Calling DiligentSearchStatusProcessor aynchronous jobs
        diligentPayloads[0].search_id = 11111;
        system.enqueueJob(new DiligentSearchStatusProcessor(diligentPayloads));// Queueable
        Database.executeBatch(new DiligentSearchStatusBatch(diligentPayloads), 100);//Batch
        
        //Calling DiligentSearchResult aynchronous jobs
        diligentPayloads[0].status = 'Finished';
        diligentPayloads[0].responseBody = DiligentCalloutHelper.getTestResponseBody('results');
        system.enqueueJob(new DiligentSearchResultProcessor(diligentPayloads));// Queueable
        Database.executeBatch(new DiligentSearchResultBatch(diligentPayloads), 100);//Batch
        
        //Calling DiligentMonitorTermProcessor aynchronous jobs
        system.enqueueJob(new DiligentMonitorTermProcessor(diligentPayloads));
        Database.executeBatch(new DiligentMonitorTermBatch(diligentPayloads), 100);
        
        //Calling Diligent Failure handling scheduler
        a.Diligent_Search_Failed__c = true;
        update a;
        DiligentFailureScheduler diligentFailureSch = new DiligentFailureScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Diligent Failure Scheduler', sch, diligentFailureSch);
        
        //Calling Diligent Activate/Deactivate List Scheduler
        DiligentActivateListScheduler diligentListActivate = new DiligentActivateListScheduler();
        system.schedule('Test Diligent Activation Scheduler', sch, diligentListActivate);
        
        DiligentDeactivateListScheduler diligentListDeactivate = new DiligentDeactivateListScheduler();
        system.schedule('Test Diligent Deactivation Scheduler', sch, diligentListDeactivate);
        
        //Calling Diligent Monitor Result Scheduler
        DiligentMonitorResultsScheduler diligentMonitorResults = new DiligentMonitorResultsScheduler();
        system.schedule('Test Diligent Monitor Result Scheduler', sch, diligentMonitorResults);
        
        Test.stopTest();
    }
    
}
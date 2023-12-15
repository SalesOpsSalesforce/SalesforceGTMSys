/* Class:       AccountTriggerHandlerTest
** Created by:  OpFocus (MJ Kahn) in April 2020
** Description: Methods for testing the BatchRunUpdateJobs and ScheduledRunUpdateJobs
*/
@IsTest
private class BatchRunUpdateJobsTest {
    @IsTest
    static void testBatchJob() {

        // Unfortunately, since Salesforce doesn't let us create records for custom metadata types, we can't create
        // Scheduled_Job__mdt or Job Action records. The best we can do is run the job and hope that the system
        // has some records defined already.

        List<Scheduled_Job__mdt> lstJobs =
            [select Id, Label, Object_API_Name__c, Record_Matching_Criteria__c, Email_Address_for_Errors__c,
                    Run_in_Test_Mode__c, Batch_Size__c,
                    (select Id, Type__c, Target_Field_API_Name__c, Source_Field_API_Name__c, Text_Value__c
                     from   Scheduled_Job_Actions__r
                     where  Active__c = true
                     order by Label)
            from Scheduled_Job__mdt
            where Active__c = true
            ];

        Test.startTest();
        BatchRunUpdateJobs cls = new BatchRunUpdateJobs(lstJobs);
        Database.executeBatch(cls);
        Test.stopTest();

        System.assertNotEquals(null, cls.lstErrors);

        // A few more calls, just to force some coverage
        cls.lstJobs = lstJobs;
        cls.currentJob = lstJobs[0];
//        cls.lstJobs = new List<Scheduled_Job__mdt>();
        cls.execute(null, new List<Account>());
        cls.start(null);

        cls.lstJobs = new List<Scheduled_Job__mdt>();
        cls.start(null);
        cls.execute(null);

        // Cover the Schedulable jobs
        cls.lstJobs = lstJobs;
        cls.execute(null);

        ScheduledRunUpdateJobs clsSchedulable = new ScheduledRunUpdateJobs();

        clsSchedulable.execute(null);
    }


    @IsTest
    static void testExecute() {
        // Unfortunately, since Salesforce doesn't let us create records for custom metadata types, we can't insert
        // Scheduled_Job__mdt or Job Action records. But we can instantiate them outside of the database and then
        // pass them into the Batch Apex job's execute() method.

        Scheduled_Job__mdt job1 = createJob('Job_1', 'Account', 'Id <> null');
        Scheduled_Job_Action__mdt job1Action1 = createJobAction(job1, 'job1Action1', 'Copy Field', 'AccountNumber', 'Name','');
        Scheduled_Job_Action__mdt job1Action2 = createJobAction(job1, 'job1Action2', 'Set Field', 'Site', '',    'Test Site');
        Scheduled_Job_Action__mdt job1Action3 = createJobAction(job1, 'job1Action3', 'Email Alert', 'LEAD_Date_Time_of_Last_Demo_Request__c','', '');
        Scheduled_Job_Action__mdt job1Action4 = createJobAction(job1, 'job1Action4', 'Invalid Action', '','', '');

        Account acct = TestData.buildAccount('Original Account Name');
        acct.AccountNumber = 'Original Account Number';
        acct.Site = 'Original Account Site';
        acct.LEAD_Date_Time_of_Last_Demo_Request__c = null;
        insert acct;

        Test.startTest();
        BatchRunUpdateJobs cls = new BatchRunUpdateJobs(new List<Scheduled_Job__mdt>{job1});
        cls.lstErrors = new List<String>();
        cls.currentJob = job1;
        cls.doExecute(job1, new List<Scheduled_Job_Action__mdt>{job1Action1, job1Action2, job1Action3, job1Action4}, new List<Account>{acct});
        Test.stopTest();

        acct = [select id, Name, AccountNumber, Site, LEAD_Date_Time_of_Last_Demo_Request__c from Account];
        System.assertEquals( acct.Name, acct.AccountNumber,'Copy Field action did not work');
        System.assertEquals('Test Site', acct.Site, 'Set Field action did not work');
        System.assertNotEquals(null, acct.LEAD_Date_Time_of_Last_Demo_Request__c, 'Email Alert action did not work');

        // We expect 1 error, from an invalid action
        System.assertEquals(1, cls.lstErrors.size(), 'Unexpected error occurred: ' + cls.lstErrors);

        cls.finish(null);

        // Run it again, this time with an invalid Account field name, just to generate an exception
        Scheduled_Job_Action__mdt job1Action5 = createJobAction(job1, 'job1Action5', 'Copy Field', 'BadFieldName1', 'BadFieldName2','');

        BatchRunUpdateJobs cls2 = new BatchRunUpdateJobs(new List<Scheduled_Job__mdt>{job1});
        cls2.lstErrors = new List<String>();
        cls2.currentJob = job1;
        cls2.doExecute(job1, new List<Scheduled_Job_Action__mdt>{job1Action5}, new List<Account>{acct});

        // A few more calls, just to force some coverage
        cls2.doExecute(job1, new List<Scheduled_Job_Action__mdt>(), new List<Account>{acct});

        // Run it again, this time with a really long value to put into Name to force an error on the DML update
        Scheduled_Job_Action__mdt job1Action6 = createJobAction(job1, 'job1Action6', 'Set Field', 'Name', '' ,'a'.repeat(1000));

        BatchRunUpdateJobs cls3 = new BatchRunUpdateJobs(new List<Scheduled_Job__mdt>{job1});
        cls3.lstErrors = new List<String>();
        cls3.currentJob = job1;
        cls3.doExecute(job1, new List<Scheduled_Job_Action__mdt>{job1Action6}, new List<Account>{acct});

        // More calls to force errors to get code coverage
        Scheduled_Job_Action__mdt copyActionNoFields = createJobAction(job1, 'copyActionNoFields', 'Copy Field', null, null,null);
        cls.copyField(job1, copyActionNoFields, new Account());

        Scheduled_Job_Action__mdt setActionNoFields = createJobAction(job1, 'setActionNoFields', 'Set Field', null, null,null);
        cls.setField(job1, setActionNoFields, new Account());

        Scheduled_Job_Action__mdt setActionBadTargetType = createJobAction(job1, 'setActionBadTargetType', 'Set Field', 'AnnualRevenue', null,'Bad Value for AnnualRevenue field');
        cls.setField(job1, setActionBadTargetType, new Account());

        Scheduled_Job_Action__mdt emailActionNoFields = createJobAction(job1, 'emailActionNoFields', 'Email Alert', null, null,null);
        cls.sendEmailAlert(job1, emailActionNoFields, new Account());

        Scheduled_Job_Action__mdt setActionBadEmailAlert = createJobAction(job1, 'setActionBadEmailAlert', 'Email Alert', 'AnnualRevenue', null,'');
        cls.sendEmailAlert(job1, setActionBadEmailAlert, new Account());
    }



    private static Scheduled_Job__mdt createJob(String devName, String objectApiName, String criteria) {
        Scheduled_Job__mdt job = new Scheduled_Job__mdt();
        job.Label = devName;
        job.DeveloperName = devName;
        job.Object_API_Name__c = objectApiName;
        job.Record_Matching_Criteria__c = criteria;
        job.Email_Address_for_Errors__c = 'test@test.com';
        job.Run_in_Test_Mode__c = false;
        job.Active__c = true;
        return job;
    }

    private static Scheduled_Job_Action__mdt createJobAction(Scheduled_Job__mdt job, String devName, String actionType, String targetFieldName, String sourceFieldName, String textValue) {
        Scheduled_Job_Action__mdt action = new Scheduled_Job_Action__mdt();
        action.Label = devName;
        action.DeveloperName = devName;
        action.Type__c = actionType;
        action.Target_Field_API_Name__c = targetFieldName;
        action.Source_Field_API_Name__c = sourceFieldName;
        action.Text_Value__c = textValue;
        action.Active__c = true;
        job.Scheduled_Job_Actions__r.add(action);
        return action;
    }

}
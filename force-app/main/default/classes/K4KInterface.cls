public class K4KInterface implements Schedulable {
    // Process a list of accounts for K4K based on the fields in
    // Custom Metadata Type K4K_Account_Field__mdt
    //
    // When deploying or saving, may need to anonymously run the following to clear any currently scheduled jobs:
    //    K4KInterface.clearAllPreviousK4KJobs();
    // Scheduled jobs can then be requeued by re-scheduling them:
    //    K4KInterface.setup('Account');
    //    K4KInterface.setup('Customer_Onboarding__c');
    //    K4KInterface.setup('Lead');
    //
    // Additionally, you can run a similar job maually using:
    //    K4KInterface.manualRun(fromClause, whereClause);
    // or
    //    K4KInterface.manualRun(sobjectType);

    public static String cronJobName = 'K4KProcessor Job';
    private String cronJobQuery;
    private String sobjectType;
    private List<String> sobjectTypes = new List<String>{'Account', 'Customer_Onboarding__c', 'Lead'};

    // Initialize using a schedule
    public K4KInterface(String sobjectType) {
        this.sobjectType = sobjectType;
    }

    // -------------------------------------------------------------------------
    // Execution functions

    // ========== Invocable functions
    @InvocableMethod(label='K4KInterface' description='Run K4K processing code on a specific record' category='K4K')
    public static void invocableK4KProcessor(List<SObject> sObjectList) {
        //	Args:
        //		sObjectList: list of arbitrary type sobjects for processing
        try {
            K4KProcessor k4kClient = new K4KProcessor(new Set<SObject>(sObjectList));
            ID jobID = System.enqueueJob(k4kClient);
            System.debug('Queued new job with jobID' + jobID);
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
    }

    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window using a query
    public static void manualRun(String fromClause, String whereClause) {
        try {
            String soqlQuery = buildSobjectQuery(fromClause, whereClause);
            K4KProcessor k4kClient = new K4KProcessor(new Set<SObject>(Database.query(soqlQuery)));
            ID jobID = System.enqueueJob(k4kClient);
            System.debug('Queued new job with jobID' + jobID);
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
    }
    // use this method to run this from an Execute Anonymous Window as if it were a cron run
    public static void manualRun(String sobjectType) {
        try {
            K4KInterface.syncRecentlyModifiedRecords(sobjectType);
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
    }

    public static void setup(String sobjectType) {
        // use this method to schedule this job
        //
        // This was most recently scheduled using the following code:
        //  String sobjectType = 'Account';
        //  String sobjectType = 'Customer_Onboarding__c';
        //  String sobjectType = 'Lead';
        //  K4KInterface.setup(sobjectType);
        Map <String, String> k4kSettings = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Code_Setting__mdt','K4K Settings Config');
        String cronSchedule = k4kSettings.get('Cron Schedule');
        String cronJobName = K4KInterface.cronJobName + ' ' + sobjectType;
        if(Test.isRunningTest()){
            cronJobName += ' test';
        }
        clearPreviousJobs(sobjectType);
        system.debug('Scheduling "' + cronJobName + '" using the schedule "' + cronSchedule + '"');
        System.schedule(cronJobName, cronSchedule, new K4KInterface(sobjectType));
    }

    public void execute(SchedulableContext context) {
        K4KInterface.syncRecentlyModifiedRecords(this.sobjectType);
    }

    public static void syncRecentlyModifiedRecords(String sobjectType){
        // Sync records of a given sobject type that were modified in the last 60 mins
        try {
            // Determine when now and 60 minutes ago is
            Datetime d = Datetime.now();
            String fromDate = d.addMinutes(-60).formatGMT('yyyy-MM-dd HH:mm:ss|').replace(' ','T').replace('|','Z');
            String toDate = d.formatGMT('yyyy-MM-dd HH:mm:ss|').replace(' ','T').replace('|','Z');
            // Query for each set of sobjects
            String soqlQuery = buildSobjectQuery(
                sobjectType,
                'LastModifiedDate > '+ fromDate + 'AND LastModifiedDate < '+ toDate +''
            );
            if (sobjectType == 'Customer_Onboarding__c'){
                soqlQuery = buildSobjectQuery(
                    sobjectType,
                    '(Onboarding_Completed_Start_Date_Time__c > '+ fromDate + 'AND Onboarding_Completed_Start_Date_Time__c < '+ toDate +') OR ' +
                    '(Onboarding_Canceled_Start_Date_Time__c > '+ fromDate + 'AND Onboarding_Canceled_Start_Date_Time__c < '+ toDate +')'
                );
            }
            System.debug('Making SOQL query using: ' + soqlQuery);
            Set<SObject> sobjects = new Set<SObject>(Database.query(soqlQuery));
            System.debug('Returned query set size: ' + sobjects.size());
            K4KProcessor k4kClient = new K4KProcessor(sobjects);
            // Enqueue job
            ID jobID = System.enqueueJob(k4kClient);
            System.debug('Queued new job with jobID' + jobID);
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
    }

    // ========== Utility functions
    // Build query for Sobject using all possible fields
    public static String buildSobjectQuery(String fromClause, String whereClause) {
        // Get all of the fields on the object
        //  NOTE: for Account, Lead, and Customer_Onboarding__c we now query for just the fields we care about,
        //  the return was too large to process with all fields.
        Map <String, String> k4kFields = new Map <String, String>();
        String fieldNames;
        String extraFields = ''; // Some processing requires fields we don't track
        if (fromClause == 'Account') {
            k4kFields = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Account_Field__mdt','K4K_CS_v1');
            fieldNames = String.join(k4kFields.values(), ',');
            //fieldNames = String.join(new List<String>(Schema.SObjectType.Account.fields.getMap().keySet()), ',');
        } else if (fromClause == 'Case') {
            fieldNames = String.join(new List<String>(Schema.SObjectType.Case.fields.getMap().keySet()), ',');
        } else if (fromClause == 'Lead') {
            extraFields = ',Email';
            k4kFields = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Lead_Field__mdt','K4K_M_v1');
            fieldNames = String.join(k4kFields.values(), ',');
            //fieldNames = String.join(new List<String>(Schema.SObjectType.Lead.fields.getMap().keySet()), ',');
        } else if (fromClause == 'Customer_Onboarding__c') {
            extraFields = ',Main_User__c,Economic_Buyer__c';
            k4kFields = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Customer_Onboarding_Field__mdt','K4K_OB_v1');
            fieldNames = String.join(k4kFields.values(), ',');
            //fieldNames = String.join(new List<String>(Schema.SObjectType.Customer_Onboarding__c.fields.getMap().keySet()), ',');
        } else if (fromClause == 'Solution_Architect_Request__c') {
            fieldNames = String.join(new List<String>(Schema.SObjectType.Solution_Architect_Request__c.fields.getMap().keySet()), ',');
        }
        return 'SELECT '+ fieldNames + extraFields +' FROM '+fromClause+' WHERE '+whereClause;
    }

    // clears previous scheduled jobs
    public static void clearPreviousJobs() {
        CronTrigger[] lstJob = getCurrentCronTriggers(K4KInterface.cronJobName);
        for (CronTrigger cr : lstJob) {
            System.abortJob(cr.Id);
        }
    }

    // clears sobject type-specific scheduled jobs
    public static void clearPreviousJobs(String sobjectType) {
        CronTrigger[] lstJob = getCurrentCronTriggers(K4KInterface.cronJobName + ' ' + sobjectType);
        for (CronTrigger cr : lstJob) {
            System.abortJob(cr.Id);
        }
    }

    // clears all previous scheduled jobs
    public static void clearAllPreviousK4KJobs() {
        List<CronTrigger> lstJobs = new List<CronTrigger>();
        CronTrigger[] lstJob = getAllCurrentK4KCronTriggers(K4KInterface.cronJobName);
        for (CronTrigger cr : lstJob) {
            System.debug('Canceling Job:"' + cr.CronJobDetail.Name + '"');
            System.abortJob(cr.Id);
        }
    }

    // query for scheduled jobs for this class
    // @return list of Scheduled Jobs
    public static List<CronTrigger> getCurrentCronTriggers(String cronJobName) {
        if(Test.isRunningTest()){
            cronJobName += ' test';
        }
        return [
            SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :cronJobName
        ];
    }

    // query for scheduled jobs for this class
    // @return list of Scheduled Jobs
    public static List<CronTrigger> getAllCurrentK4KCronTriggers(String cronJobName) {
        if(Test.isRunningTest()){
            cronJobName += ' test';
        }
        cronJobName = '%' + cronJobName + '%';
        return [
            SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, State
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :cronJobName
        ];
    }
}
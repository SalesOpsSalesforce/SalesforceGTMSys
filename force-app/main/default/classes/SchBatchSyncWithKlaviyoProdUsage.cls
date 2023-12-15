/**
 * Name: SchBatchSyncWithKlaviyoProdUsage
 * Created on: May 2020
 * Created by: J. Pipkin (OpFocus, Inc)
 * Description:
 */

public class SchBatchSyncWithKlaviyoProdUsage implements Schedulable, Database.Batchable<SObject>, Database.Stateful {
    

    private SchBatchSyncWithKlaviyoProdUsage() {
    }

    // -------------------------------------------------------------------------------------
    // ---------------- Schedulable Part ---------------------------------------------------
    // -------------------------------------------------------------------------------------
    public static String jobName = 'SchBatchSyncWithKlaviyoProdUsage Job';

    // use this method to schedule this job
    public static void setup() {
        KPU_Job_Settings__mdt cronSetting = [Select Schedule_Cron__c from KPU_Job_Settings__mdt where DeveloperName = 'Default'];
        String cronText = cronSetting.Schedule_Cron__c;
        if(Test.isRunningTest()){
            jobName += 'test';
        }
        clearJob();
        System.schedule(jobName, cronText , new SchBatchSyncWithKlaviyoProdUsage());
    }

    // use this method to run this job once manually
    public static void manual() {
        KPU_Job_Settings__mdt batchSetting = [Select Batch_Size__c from KPU_Job_Settings__mdt where DeveloperName = 'Default'];
        Database.executeBatch(new SchBatchSyncWithKlaviyoProdUsage(), Integer.valueOf(batchSetting.Batch_Size__c));
    }

    // -------------------------------------------------------------------------------------
    // ---------------- Schedulable Part ---------------------------------------------------
    // -------------------------------------------------------------------------------------

    public void execute(SchedulableContext sc) {
        // first check if previous job is still running. if so, do nothing.
        if(!isPreviousJobExecuting()) {
            manual();
        }
    }

    // -------------------------------------------------------------------------------------
    // ---------------- Batchable Part ---------------------------------------------------
    // -------------------------------------------------------------------------------------
    public String dmlFailures = '';
    public List<KPU_Mapping__mdt> mappings;
    public Map<String,Set<String>> kpuFields;
    public Map<String, List<KPU_Mapping__mdt>> mappingByObject;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'Select Id from Klaviyo_Product_Usage__c where Updated_by_Heroku__c = true';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Klaviyo_Product_Usage__c> records) {

        try {
            // first gather all the metadata into usable maps
            mappings = [Select Object__c, KPU_Field__c, Target_Field__c, Is_Active__c from KPU_Mapping__mdt
            where Is_Active__c = true];
            Set<String> fields = new Set<String>{'Updated_by_Heroku__c', 'Klaviyo_Account_ID__c'};
            kpuFields = new Map<String,Set<String>>();
            mappingByObject = new Map<String, List<KPU_Mapping__mdt>>();
            for(KPU_Mapping__mdt km : mappings) {
                // gather source fields for initial query
                if(km.KPU_Field__c != null) fields.add(km.KPU_Field__c);

                // store target fields by object for query
                String key = km.Object__c.toLowerCase();
                if(!kpuFields.containsKey(key)) {
                    kpuFields.put(key, new Set<String>());
                }
                kpuFields.get(key).add(km.Target_Field__c);

                // store mapping records by object
                if(!mappingByObject.containsKey(key)) {
                    mappingByObject.put(key, new List<KPU_Mapping__mdt>());
                }
                mappingByObject.get(key).add(km);
            }

            records = Database.query('Select ' + String.join(new List<String>(fields),',') + ' from Klaviyo_Product_Usage__c where Id in : records');

            Set<String> kaIds = new Set<String>();
            Map<String, KPUWrapper> wrapperMap = new Map<String, KPUWrapper>();
            // get the account ids that will be used in this batch
            for(Klaviyo_Product_Usage__c kpu : records) {
                kaIds.add(kpu.Klaviyo_Account_ID__c);
                wrapperMap.put(kpu.Klaviyo_Account_ID__c, new KPUWrapper(kpu));
            }

            // gather related accounts
            kpuFields.get('account').add('Product_Klaviyo_Account_ID__c');
            Account[] lstAccount = Database.query('Select ' + String.join(new List<String>(kpuFields.get('account')), ',') +
                    ' from Account where Product_Klaviyo_Account_ID__c in :kaIds FOR UPDATE'); //[SFDC-795 VRajapatruni 09/13/2022] Added FOR UPDATE to avoid row locking

            for(Account a : lstAccount) {
                wrapperMap.get(a.Product_Klaviyo_Account_ID__c).a = new Account(Id=a.Id);
            }

            // gather related leads
            // [2/7/2022 RGaokar TP #107010 The converted leads are excluded from KPU to lead sync]
            kpuFields.get('lead').add('Klaviyo_Account_ID__c');
            Lead[] lstLead = Database.query('Select ' + String.join(new List<String>(kpuFields.get('lead')), ',') +
                    ' from Lead where Klaviyo_Account_ID__c in :kaIds AND isconverted = false FOR UPDATE'); //[SFDC-795 VRajapatruni 09/13/2022] Added FOR UPDATE to avoid row locking

            for(Lead l : lstLead) {
                wrapperMap.get(l.Klaviyo_Account_ID__c).l = new Lead(Id=l.Id);
            }

            System.debug(JSON.serializePretty(wrapperMap));

            // now do mapping updates
            Map<Id, Account> accountUpdates = new Map<Id, Account>();
            Map<Id, Lead> leadUpdates = new Map<Id, Lead>();
            for(Klaviyo_Product_Usage__c kpu : records) {
                KPUWrapper w = wrapperMap.get(kpu.Klaviyo_Account_ID__c);
                if(w.a != null) {
                    for(KPU_Mapping__mdt m : mappingByObject.get('account')) {
                        w.a.put(m.Target_Field__c, kpu.get(m.KPU_Field__c));
                    }
                    accountUpdates.put(w.a.Id, w.a);
                }
                if(w.l != null) {
                    for(KPU_Mapping__mdt m : mappingByObject.get('lead')) {
                        w.l.put(m.Target_Field__c, kpu.get(m.KPU_Field__c));
                    }
                    leadUpdates.put(w.l.Id, w.l);
                }
                kpu.Updated_by_Heroku__c = false;
            }

            // perform DML on account and lead
            doDML(accountUpdates.values());
            doDML(leadUpdates.values());
            doDML(records);

        } catch (Exception ex) {
            System.debug('error: ' + ex.getMessage() + ' -->> ' + ex.getStackTraceString());
            sendEmail('Exception occured in batch job SchBatchSyncWithKlaviyoProdUsage', ex.getMessage() + '\n' + ex.getStackTraceString());
        }


    }

    /**
     * generic method for updates and storing any exception thrown during update
*/
    private void doDML(List<SObject> objectList) {
        Database.SaveResult[] srList = Database.update(objectList, false) ;
        Integer i = 0;
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                    // for updates
                    String errMsg = 'Error updating Object (' + objectList[i].get('Id') + '):\n' + err.getStatusCode() + ':\n' +
                            err.getMessage() + ',\n' +
                            'fields that affected this error: ' + err.getFields() + '\n\n';
                    dmlFailures += errMsg;
                }
            }// some failures
            i++;
        }
    }

    public void finish(Database.BatchableContext bc) {

        AsyncApexJob aaJob = [SELECT ApexClass.Name, Status, ExtendedStatus, MethodName FROM AsyncApexJob WHERE Id = :bc.getJobId()];

        if (aaJob.Status == 'Failed' || Test.isRunningTest() || (aaJob.ExtendedStatus != null && aaJob.ExtendedStatus != '')) {

            String fbody = 'The batch job, SchBatchSyncWithKlaviyoProdUsage, failed to run.';
            fbody += '\n\nERROR: ' + aaJob.ExtendedStatus;

            sendEmail('Error in SchBatchSyncWithKlaviyoProdUsage', fbody);
        }
        if (dmlFailures != '' || Test.isRunningTest()) {
            String fbody = 'The batch job, SchBatchSyncWithKlaviyoProdUsage, had the follwing DML failures :';
            fbody += '\n\n' + dmlFailures;

            sendEmail('DML failures in SchBatchSyncWithKlaviyoProdUsage', fbody);
        }

    }
    // -------------------------------------------------------------------------------------
    // ---------------- Batchable Part ---------------------------------------------------
    // -------------------------------------------------------------------------------------

    private static void sendEmail(String subject, String body) {

        Messaging.SingleEmailMessage semResult = new Messaging.SingleEmailMessage();
        semResult.setToAddresses(new String[]{
                UserInfo.getUserEmail()
        });

        semResult.setSubject(subject);
        semResult.setPlainTextBody(body);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    semResult
            });
        } catch (Exception e) {
            System.debug(e);
        }

    }

    /**
     * clears previous scheduled jobs
*/
    public static void clearJob() {
        CronTrigger[] lstJob = getTriggers();
        for (CronTrigger cr : lstJob) {
            System.abortJob(cr.Id);
        }

    }

    /**
     * query for scheduled jobs for this class
     * @return list of Scheduled Jobs
*/
    public static List<CronTrigger> getTriggers() {
        return [
            SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, State
            FROM CronTrigger
            where CronJobDetail.Name = :jobName
        ];
    }

    /**
     * returns if the previous batch is still running or not
     * @return TRUE/FALSE
*/
    public static Boolean isPreviousJobExecuting() {
        Set<String> openStates = new Set<String>{'Holding', 'Queued', 'Preparing', 'Processing'};
        return [Select count() from AsyncApexJob where ApexClass.Name = 'SchBatchSyncWithKlaviyoProdUsage'
                    and Status in :openStates and JobType <> 'ScheduledApex'] > 0;
    }

    public class KPUWrapper {
        public Account a;
        public Lead l;
        public Klaviyo_Product_Usage__c kpu;

        public KPUWrapper(Klaviyo_Product_Usage__c kpu) {
            this.kpu = kpu;
        }
    }


}
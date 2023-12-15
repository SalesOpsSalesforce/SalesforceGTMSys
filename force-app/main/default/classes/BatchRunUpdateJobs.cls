/* Class:       BatchRunUpdateJobs
 * Created On:  April 2020
 * Created by:  MJ Kahn (OpFocus, Inc)
 * Description: A batchable job that accepts a list of Scheduled_Job__mdt records,
 *              runs the first one on the list, then launches another instance
 *              of itself to run with the rest of the list.
 */
global with sharing class BatchRunUpdateJobs implements System.Schedulable, Database.Batchable<SObject>, Database.Stateful {

    global List<Scheduled_Job__mdt> lstJobs;
    global List<String> lstErrors;

    global Scheduled_Job__mdt currentJob;

    global Boolean finishCalledManually = false;

    global Map<String,String> mapFieldTypesByFieldName;

    private static Set<DisplayType> stringTypes = new Set<DisplayType>{DisplayType.COMBOBOX,DisplayType.EMAIL,DisplayType.ID,DisplayType.MULTIPICKLIST,
            DisplayType.PHONE,DisplayType.PICKLIST,DisplayType.REFERENCE,DisplayType.STRING,DisplayType.TEXTAREA,DisplayType.URL};

    // Constructor
    global BatchRunUpdateJobs(List<Scheduled_Job__mdt> lstJobs) {
        this.lstJobs = lstJobs;
        this.lstErrors = new List<String>();
    }

    // Convenience method to launch the batch job with a list of Scheduled_Job__mdt records
    global static void launchBatchApexJob(List<Scheduled_Job__mdt> lstJobs) {
        if (!lstJobs.isEmpty()) {
            BatchRunUpdateJobs job = new BatchRunUpdateJobs(lstJobs);
            Integer batchSize = (lstJobs[0].Batch_Size__c == null) ? 200 : (Integer)lstJobs[0].Batch_Size__c;
            Database.executeBatch(job, batchSize);
        }
    }


    // ---------------------------------------- Schedulable Methods ----------------------------------------
    global void execute (SchedulableContext sc) {
        // Create a BatchRunUpdateJobs job, handing it all the Job records we have
        // It will execute the first job, then take that job off the list and
        // schedule the launch of another BatchRunUpdateJobs job to execute the next job,
        // and so on.
        if (!lstJobs.isEmpty()) {
            BatchRunUpdateJobs.launchBatchApexJob(lstJobs);
        }
    }


    // ---------------------------------------- Batchable Methods ----------------------------------------

    // Batchable start method
    global Database.QueryLocator start(Database.BatchableContext bc) {

        // Clear the error list for the start of a new batch
        this.lstErrors = new List<String>();

        // Get the first job from the list
        if (lstJobs.size() == 0) {
            // No more jobs to run. (We shouldn't have been launched in the first place.)
            lstErrors.add('No jobs found.');
            return null;
        }

        // Get the details on that job from Schedule_Job__mdt
        try {
            currentJob = [
                    select Id, Label, Object_API_Name__c, Record_Matching_Criteria__c, Email_Address_for_Errors__c,
                           Run_in_Test_Mode__c, Batch_Size__c,
                           (select Id, Type__c, Target_Field_API_Name__c, Source_Field_API_Name__c, Text_Value__c
                            from Scheduled_Job_Actions__r
                            where Active__c = true
                            order by Label)
                    from Scheduled_Job__mdt
                    where id = :lstJobs[0].Id and Active__c = true
            ];
        }
        catch (Exception ex) {
            // If the start() method doesn't return an interable, the system doesn't call finish(),
            // so we'll call it ourselves.
            lstErrors.add('Job ' + lstJobs[0].Id + ' not found or is not Active');
            finishCalledManually = true;
            finish(null);
            return null;
        }

        // If there are no actions to perform, there's no sense running the job
        if (currentJob.Scheduled_Job_Actions__r.isEmpty()) {
            // If the start() method doesn't return an interable, the system doesn't call finish(),
            // so we'll call it ourselves.
            lstErrors.add('Job ' + currentJob.Label + ' has no Scheduled Job Actions defined.');
            finishCalledManually = true;
            finish(null);
            return null;
        }

        // Fetch all of the records for the given object that meet the given criteria
        Set<String> setFieldNames = new Set<String>();
        for (Scheduled_Job_Action__mdt action : currentJob.Scheduled_Job_Actions__r) {
            if (action.Source_Field_API_Name__c != null) setFieldNames.add(action.Source_Field_API_Name__c);
            if (action.Target_Field_API_Name__c != null) setFieldNames.add(action.Target_Field_API_Name__c);
        }

        String soql = 'select id';
        for (String fldName : setFieldNames) soql += ', ' + fldName;

        soql += ' from ' + currentJob.Object_API_Name__c;
        if (currentJob.Record_Matching_Criteria__c != null) {
            soql += ' where ' + currentJob.Record_Matching_Criteria__c;
        }
        System.debug('===== start() Job ' + currentJob.Label + ': soql = ' + soql);

        Database.QueryLocator ql;
        try {
            ql = Database.getQueryLocator(soql);
        }
        catch (Exception ex) {
            // If the start() method doesn't return an interable, the system doesn't call finish(),
            // so we'll call it ourselves.
            lstErrors.add('Job ' + currentJob.Label + ': Error running SOQL query.\n' +
                    'Query: ' + soql + '\n' +
                    'Error: ' + ex.getMessage());
            finishCalledManually = true;
            finish(null);
            return null;
        }

        return  ql;
    }


    // Batchable execute method
    global void execute(Database.BatchableContext bc, List<sObject> lstRecords) {
        // The bulk of the logic is in a separate method that can be called from a unit test.
        doExecute(currentJob, currentJob.Scheduled_Job_Actions__r, lstRecords);
    }

    @TestVisible
    private void doExecute(Scheduled_Job__mdt currentJob, List<Scheduled_Job_Action__mdt> lstCurrentJobActions, List<sObject> lstRecords) {
        System.debug('===== execute(): lstRecords.size() = ' + lstRecords.size());
        if (lstRecords.isEmpty()) {
            // Shouldn't happen, but if we're called with 0 records, do nothing.
            return;
        }

        // If there are no actions to perform, there's no sense running the job
        // We've already checked for this in the start() method, but just to be on the safe side, we'll check again.
        if (lstCurrentJobActions.isEmpty()) {
            // If the start() method doesn't return an interable, the system doesn't call finish(),
            // so we'll call it ourselves.
            lstErrors.add('Job ' + currentJob.Label + ' has no Scheduled Job Actions defined.');
            finishCalledManually = true;
            finish(null);
            return;
        }

        // For the object we're working with, determine whether each field is a number field, a string field,
        // or some other type of field
        if (mapFieldTypesByFieldName == null) {
            mapFieldTypesByFieldName = new Map<String, String>();
            for (Schema.SObjectField f : lstRecords[0].getSObjectType().getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = f.getDescribe();
                if (stringTypes.contains(dfr.getType())) {
                    mapFieldTypesByFieldName.put(dfr.getName().toLowerCase(), 'string');
                } else {
                    mapFieldTypesByFieldName.put(dfr.getName().toLowerCase(), 'n/a');
                }
            }
        }

        // Given a set of records that meet the job's criteria, do the Job's Actions
        for (sObject record : lstRecords) {

            for (Scheduled_Job_Action__mdt action : lstCurrentJobActions) {
                if (action.Type__c == 'Copy Field') {
                    copyField(currentJob, action, record);
                }
                else if (action.Type__c == 'Set Field') {
                    setField(currentJob, action, record);
                }
                else if (action.Type__c == 'Email Alert') {
                    sendEmailAlert(currentJob, action, record);
                }
                else {
                    lstErrors.add('Job ' + currentJob.Label + ': Action ' + action.Id + ' has unknown type ' + action.Type__c);
                    System.debug('execute(): lstErrors = ' + lstErrors);
                    continue;
                }
            }
        }

        // Save the changes.
        // If the job's Run_in_Test_Mode__c is checked, roll back the changes as if they hadn't been made.
        // Then report any errors by adding them to lstErrors.
        Savepoint sp;
        if (currentJob.Run_in_Test_Mode__c) sp = Database.setSavepoint();
        List<Database.SaveResult> lstResults = Database.update(lstRecords, false);
        if (currentJob.Run_in_Test_Mode__c) Database.rollback(sp);

        for (Integer i=0; i<lstResults.size(); i++) {
            Database.SaveResult sr = lstResults[i];
            if (!sr.isSuccess()) {
                // Update failed, so get all errors
                String strError = 'Job ' + currentJob.Label + ': Unable to save updated ' + currentJob.Object_API_Name__c + ' record.\n';
                strError += 'Record Id: ' + lstResults[i].Id;
                for (Database.Error err : sr.getErrors()) {
                    strError = 'Error: ' + err.getStatusCode() + ': ' + err.getMessage();
                }
                lstErrors.add(strError);
                System.debug('execute(): lstErrors = ' + lstErrors);
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Report any errors that occurred
        System.debug('===== finish(): lstErrors = ' + lstErrors);
        System.debug('===== finish(): currentJob.Email_Address_for_Errors__c = ' + currentJob.Email_Address_for_Errors__c);
        if (!lstErrors.isEmpty() && currentJob != null && currentJob.Email_Address_for_Errors__c != null) {

            String subject = 'Errors from Scheduled Job ' + currentJob.Label;
            String body = String.join(lstErrors, '\n');

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(currentJob.Email_Address_for_Errors__c.split(';'));
            email.setSubject(subject);
            email.setPlainTextBody(body);
            try {
                System.debug('===== sending email: Subject: ' + subject + '\nBody: ' + body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
            catch(Exception ex) {
                 // No need to add this error to lstErrors at this point
                System.debug('finish(): Error sending email ' + JSON.serializePretty(email));
                System.debug(ex);
            }

        }

        // Take the job we just finished off the list, then launch a new instance of
        // this class with the remaining jobs.
        lstJobs.remove(0);
        if (!lstJobs.isEmpty()) {
            if (!finishCalledManually) {
                // This finish() method was not called manually by the code above,
                // but instead was called at the end of a batch.
                // we can only launch the batch job as follows if we're in the
                // finish() method at the end of a batch. If we were called manually,
                // we need to *schedule* the job to run in a minute.
                BatchRunUpdateJobs.launchBatchApexJob(lstJobs);
            }
            else {
                // This finish() method was called manually by an error in the start()
                // method. Salesforce won't allow us to launch a batch job in the context
                // of the start() or execute() methods, so instead, schedule the job to run
                // in just a few seconds.
                DateTime dt = System.now().addSeconds(15);
                String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
                Id jobId = System.schedule('BatchRunUpdateJobs ' + Datetime.now(), timeForScheduler, new BatchRunUpdateJobs(lstJobs));
            }
        }
    }


    // ---------------------------------------- Helper Methods ----------------------------------------

    // Given a record and a "Copy Field" action, copies the value from the Source Field to the Target Field.
    // Returns true if successful.
    @TestVisible
    private Boolean copyField(Scheduled_Job__mdt currentJob, Scheduled_Job_Action__mdt action, SObject record) {
        if (action.Source_Field_API_Name__c == null) {
            lstErrors.add('Job ' + currentJob.Label + ': ' +
                    'Unable to copy a field ' +
                    ' to field ' + action.Target_Field_API_Name__c +
                    ' for ' + currentJob.Object_API_Name__c + ' record Id ' + record.Id +
                    ' because no Source Field Name was specified.');
            System.debug('execute(): lstErrors = ' + lstErrors);
            return false;
        }

        try {
            record.put(action.Target_Field_API_Name__c, record.get(action.Source_Field_API_Name__c));
        } catch (Exception ex) {
            lstErrors.add('Job ' + currentJob.Label + ': ' +
                    'Unable to copy field ' + action.Source_Field_API_Name__c +
                    ' to field ' + action.Target_Field_API_Name__c +
                    ' for ' + currentJob.Object_API_Name__c + ' record Id ' + record.Id + '\n' +
                    'Error: ' + ex.getMessage());
            System.debug('execute(): lstErrors = ' + lstErrors);
            return false;
        }
        return true;
    }


    // Given a record and a "Set Field" action, copies the value from the Text Value Field to the Target Field.
    // Returns true if successful.
    @TestVisible
    private Boolean setField(Scheduled_Job__mdt currentJob, Scheduled_Job_Action__mdt action, SObject record) {
        try {
            String fieldType = mapFieldTypesByFieldName.get(action.Target_Field_API_Name__c.toLowerCase());
            if (fieldType == 'string') {
                String val = action.Text_Value__c;
                record.put(action.Target_Field_API_Name__c, val);
            } else {
                lstErrors.add('Job ' + currentJob.Label + ': ' +
                        'Unable to set field ' + action.Target_Field_API_Name__c +
                        ' to ' + action.Text_Value__c +
                        ' for ' + currentJob.Object_API_Name__c + ' record Id ' + record.Id +
                        ' because the field type is neither a number nor a string.');
                System.debug('execute(): lstErrors = ' + lstErrors);
                return false;
            }

        } catch (Exception ex) {
            lstErrors.add('Job ' + currentJob.Label + ': ' +
                    'Unable to set field ' + action.Target_Field_API_Name__c +
                    ' to ' + action.Text_Value__c +
                    ' for ' + currentJob.Object_API_Name__c + ' record Id ' + record.Id + '\n' +
                    'Error: ' + ex.getMessage());
            System.debug('execute(): lstErrors = ' + lstErrors);
            return false;
        }
        return true;
    }


    // Given a record and a "Send Email Alert" action, writes the current Date/Time to the Target Field.
    // We assume that the admin has defined a workflow rule that fires when the Target Field is changed
    // and performs a Workflow Email Alert action.
    // Returns true if successful.
    @TestVisible
    private Boolean sendEmailAlert(Scheduled_Job__mdt currentJob, Scheduled_Job_Action__mdt action, SObject record) {
        try {
            String fieldType = mapFieldTypesByFieldName.get(action.Target_Field_API_Name__c.toLowerCase());
            record.put(action.Target_Field_API_Name__c, Datetime.now());
        } catch (Exception ex) {
            lstErrors.add('Job ' + currentJob.Label + ': ' +
                    'Unable to set field ' + action.Target_Field_API_Name__c +
                    ' to the current date/time in order to trigger a workflow email alert' +
                    ' for ' + currentJob.Object_API_Name__c + ' record Id ' + record.Id + '\n' +
                    'Error: ' + ex.getMessage());
            System.debug('execute(): lstErrors = ' + lstErrors);
            return false;
        }
        return true;
    }

}
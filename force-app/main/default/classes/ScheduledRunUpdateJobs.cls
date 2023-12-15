/* Class:       ScheduledRunUpdateJobs
 * Created On:  April 2020
 * Created by:  MJ Kahn (OpFocus, Inc)
 * Description: A schedulable job that starts running a series of ScheduledRunUpdateJobs.
 */
global with sharing class ScheduledRunUpdateJobs implements System.Schedulable {

    // Schedulable execute method
    global void execute (SchedulableContext sc) {
        // Fetch a list of Scheduled Job records
        List<Scheduled_Job__mdt> lstJobs =
            [select id, Label, Batch_Size__c
             from   Scheduled_Job__mdt
             where  Active__c = true
             order by Label];

        // Create a BatchRunUpdateJobs job, handing it all the Job records.
        // It will execute the first job, then take that job off the list and
        // launch another BatchRunUpdateJobs job to execute the next job, and
        // so on.
        if (!lstJobs.isEmpty()) {
            BatchRunUpdateJobs.launchBatchApexJob(lstJobs);
        }
    }
}
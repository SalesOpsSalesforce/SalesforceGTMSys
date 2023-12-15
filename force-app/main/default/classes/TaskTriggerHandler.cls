/* Class:       TaskTriggerHandler
** Created by:  OpFocus 
** Description: Methods for Lead.trigger on Lead
*/
public class TaskTriggerHandler extends TriggerHandler
{

    private static Boolean isFirstInsert = true;
    private static Boolean isFirstUpdate = true;

    private List<Task> triggerNew = (Task[]) Trigger.new;
    private List<Task> triggerOld = (Task[]) Trigger.old;
    private Map<Id, Task> triggerNewmap = (Map<Id, Task>) Trigger.newMap;
    private Map<Id, Task> triggerOldmap = (Map<Id, Task>) Trigger.oldMap;

    private static Set<Id> setInsertedTaskIds = null;
    public static boolean isRunFromTask = false;
    

    // ----------- OVERRIDE METHODS ----------------


    public override void afterInsert()
    {
        // leadActivityCounter();[RGaokar 01/05/2022 TP #95332]Commenting method as the lead fields updated in this methods are no longer used.
        // accountActivityRollUpForTaskinsert();
    }

    public override void afterUpdate()
    {
        // accountActivityRollUpForTaskUpdate();
    }


    // ----------- PRIVATE METHODS ----------------

    //

    //
    // several task fields are updated by workflows, so need to handle after update
    // due to order of execution
    //
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_order_of_execution.htm
    // 
    // [RGaokar 01/05/2022 TP #95332]Commenting method as the lead fields updated in this methods are no longer used.
    /* private void leadActivityCounter() {

        // Criteria:
        // Task is created 
        // && FM_Is_Communication_Activity__c = True
        // && LeadActivity__c != null
        //
        // Get all tasks that meet the above criteria related to the Lead
        //
        // need to requery task records so FM_Is_Communication_Activity__c is populated by flow
        //
        // FM_Is_Communication_Activity__c is a formula field:
        //
        // IF(
        //     OR
        //     (
        //         WORKFLOW_Type__c = "Demo",
        //         WORKFLOW_Type__c = "Pre-Scheduled Call",
        //         WORKFLOW_Type__c = "Attempted",
        //         WORKFLOW_Type__c = "Left Message",
        //         WORKFLOW_Type__c = "Connected",
        //         AND
        //         (
        //             WORKFLOW_Type__c = "Email",
        //             OR
        //             (
        //                 BEGINS(Subject, "Email:"),
        //                 BEGINS(Subject, "Message Sent:"),
        //                 BEGINS(Subject, "Reply:")
        //             )
        //         )
        //     ),
        // True,False)

        System.debug(LoggingLevel.INFO, '========>>>> leadActivityCounter, task IDs: '+triggerNewmap.keySet());
        Map <Id, Task> mapLeadIdTask = new Map <Id, Task> ();
        Set <String> setWFCommTypes = new Set <String> {'Demo', 'Pre-Scheduled Call', 'Attempted', 'Left Message', 'Connected'};
        Set <Id> setOwnerIds = new Set <Id> ();
        for (Task t : triggerNew) {
            System.debug(LoggingLevel.INFO, '========>>>> checking task: '+t);
            System.debug(LoggingLevel.INFO, '========>>>> checking task.LeadActivity__c: '+t.LeadActivity__c);

            Boolean isCommunicationActivity = ( setWFCommTypes.contains(t.Type) 
                                                || (
                                                        t.Type == 'Email' 
                                                        && ( String.isNotBlank(t.Subject) && (t.Subject.startswith('Email:') || t.Subject.startswith('Message Sent:') || t.Subject.startswith('Reply:')) )
                                                    )
                                              );

            if (t.WhoId != null && t.WhoId.getSObjectType() == Lead.sObjectType && isCommunicationActivity ) {
                mapLeadIdTask.put(t.whoId, t);
                setOwnerIds.add(t.OwnerId);
            }
        }

        List <Lead> lstLeads = 
            [select 
                Id, FLOW_Date_Time_of_Response__c, FLOW_Flip_Date_Time__c, FLOW_DateTimeof_First_Reach_out_Activity__c, FLOW_Number_of_Calls_BeforeResponse__c,
                FLOW_Date_Time_of_First_iBDR_Connection__c, FLOW_Number_of_Emails_BeforeResponse__c, FLOW_DateTimeof_Last_Reach_out_Activity__c, FLOW_Num_of_Emails_Sent_Before_Flip__c
             from Lead 
             where Id in :mapLeadIdTask.keySet()];
        System.debug(LoggingLevel.INFO, '========>>>> found leads: '+lstLeads);
        
        // create map Task owner Title field
        Map <Id, String> mapTaskIdOwnerTitle = new Map <Id, String> ();
        Map <Id, String> mapOwnerIdTitle = new Map <Id, String> ();
        List <User> lstUsers = [select Id, Title from User where Id in :setOwnerIds];
        for (User u : lstUsers) {
            mapOwnerIdTitle.put(u.Id, u.Title);
        }

        for (Task t : triggerNew) {
            mapTaskIdOwnerTitle.put(t.Id, mapOwnerIdTitle.get(t.OwnerId));
        }
        
        if (lstLeads.size() > 0) {
            List <Lead> lstUpdateLeads = new List <Lead> ();
            for (Lead l : lstLeads) {
                Task t = mapLeadIdTask.get(l.Id);
                Boolean updateLead = false;
                System.debug(LoggingLevel.INFO, '========>>>> \n'
                    + 'lead: ' + l
                    + '\ntask, '
                    + 't.Type: ' + t.Type + ' ,'
                    + 't.Subject: ' + t.Subject + ' ,'
                    + 't.CreatedDate: ' + t.CreatedDate
                    );


                // Stamp FLOW_Number_of_Emails_BeforeResponse__c:
                // IF(
                // AND(
                // OR(
                // {Activity.CreatedDate}<={jLead.FLOW_Date_Time_of_Response__c},
                // ISBLANK({Lead.FLOW_Date_Time_of_Response__c})),
                // ISPICKVAL(Activity.Type},""Email""),
                // BEGINS({Activity.Subject},""Message Sent:"")),1,0)
                //
                if ((l.FLOW_Date_Time_of_Response__c == null || t.CreatedDate <= l.FLOW_Date_Time_of_Response__c)
                    && t.Type == 'Email'
                    && t.Subject.startsWith('Message Sent:')
                 ) {
                    if (l.FLOW_Number_of_Emails_BeforeResponse__c == null) l.FLOW_Number_of_Emails_BeforeResponse__c = 0;
                    l.FLOW_Number_of_Emails_BeforeResponse__c += 1;
                    updateLead = true;
                }

                // Stamp FLOW_Number_of_Calls_BeforeResponse__c:
                // IF(
                // AND(
                //   OR(
                //     {Activity.CreatedDate}<={Lead.FLOW_Date_Time_of_Response__c},
                //     ISBLANK({Lead.FLOW_Date_Time_of_Response__c})),
                //   OR(
                //     ISPICKVAL({Activity.Type},""Attempted""),
                //     ISPICKVAL({Activity.Type},""Connected"")
                //  )),1,0)
                //
                if (
                    (l.FLOW_Date_Time_of_Response__c == null || t.CreatedDate <= l.FLOW_Date_Time_of_Response__c)
                    && (t.Type == 'Attempted' || t.Type == 'Connected')
                 ) {
                    if (l.FLOW_Number_of_Calls_BeforeResponse__c == null) l.FLOW_Number_of_Calls_BeforeResponse__c = 0;
                    l.FLOW_Number_of_Calls_BeforeResponse__c += 1;
                    updateLead = true;
                }

                // Stamp FLOW_Num_of_Emails_Sent_Before_Flip__c:
                // IF(
                // AND(
                // OR(
                // {Activity.CreatedDate}<={Lead.FLOW_Flip_Date_Time__c},
                // ISBLANK({Lead.FLOW_Flip_Date_Time__c})),
                // ISPICKVAL({Activity.Type},""Email""),
                // BEGINS({Activity.Subject},""Message Sent:"")),1,0)
                //
                if ((l.FLOW_Flip_Date_Time__c == null || t.CreatedDate <= l.FLOW_Flip_Date_Time__c)
                    && t.Type == 'Email'
                    && t.Subject.startsWith('Message Sent:')
                 ) {
                    if (l.FLOW_Num_of_Emails_Sent_Before_Flip__c == null) l.FLOW_Num_of_Emails_Sent_Before_Flip__c = 0;
                    l.FLOW_Num_of_Emails_Sent_Before_Flip__c += 1;
                    updateLead = true;
                }

                // Stamp FLOW_Date_Time_of_Response__c:
                // IF(
                // {Is_Response_Connected_Activity__c}=FALSE,{Lead.FLOW_Date_Time_of_Response__c},
                // IF(
                // OR(
                // ISBLANK({Lead.FLOW_Date_Time_of_Response__c}),
                // {Activity.CreatedDate}<{Lead.FLOW_Date_Time_of_Response__c}),
                // {Activity.CreatedDate},{Lead.FLOW_Date_Time_of_Response__c}))
                //
                // FM_Is_Response_Connected_Activity__c, which is a formula field with this criteria:
                // IF(
                // OR 
                //     (
                //         WORKFLOW_Type__c = "Connected",
                //         WORKFLOW_Type__c = "Demo",
                //         WORKFLOW_Type__c = "Pre-Scheduled Call",
                //         AND
                //             (
                //                 WORKFLOW_Type__c = "Email",
                //                 BEGINS(Subject, "Reply:")
                //             )
                //     )
                //         ,TRUE,FALSE)
                //
                // WORKFLOW_Type__c is a text stamp of the standard Text field when the activity is created. I believe we may be again running into an order of execution error. 
                // Would it be simpler to refer to the standard Type field, as well the logic of the Is_Response_Connected_Activity__c formula in the trigger, instead? 
                //
                Set <String> setWFTypes = new Set <String> {'Connected', 'Demo', 'Pre-Scheduled Call'};

                Boolean isResponseConnectedActivity = (setWFTypes.contains(t.Type) || (t.Type == 'Email' && String.isNotBlank(t.Subject) && t.Subject.startswith('Reply:')));

                if (isResponseConnectedActivity 
                    || l.FLOW_Date_Time_of_Response__c == null 
                    || t.CreatedDate < l.FLOW_Date_Time_of_Response__c
                    ) {

                    l.FLOW_Date_Time_of_Response__c = t.CreatedDate;
                    updateLead = true;
                }


                // Stamp FLOW_DateTimeof_First_Reach_out_Activity__c:
                // IF(
                // ISBLANK({Lead.FLOW_DateTimeof_First_Reach_out_Activity__c}),
                // {Activity.CreatedDate},
                // IF(
                // {Lead.FLOW_DateTimeof_First_Reach_out_Activity__c}>={Activity.CreatedDate},
                // {Activity.CreatedDate},
                // {Lead.FLOW_DateTimeof_First_Reach_out_Activity__c}))
                //
                if (l.FLOW_DateTimeof_First_Reach_out_Activity__c == null || l.FLOW_DateTimeof_First_Reach_out_Activity__c >= t.CreatedDate) 
                {                        
                    l.FLOW_DateTimeof_First_Reach_out_Activity__c = t.CreatedDate;
                    updateLead = true;
                }



                // Stamp FLOW_DateTimeof_Last_Reach_out_Activity__c:
                // IF(
                // ISBLANK({Lead.FLOW_DateTimeof_Last_Reach_out_Activity__c}),
                // {Activity.CreatedDate},
                // IF(
                // {Lead.FLOW_DateTimeof_Last_Reach_out_Activity__c}<{Activity.CreatedDate},
                // {Activity.CreatedDate},
                // {Lead.FLOW_DateTimeof_Last_Reach_out_Activity__c}))
                if (l.FLOW_DateTimeof_Last_Reach_out_Activity__c == null || l.FLOW_DateTimeof_Last_Reach_out_Activity__c < t.CreatedDate) 
                {
                    l.FLOW_DateTimeof_Last_Reach_out_Activity__c = t.CreatedDate;
                    updateLead = true;
                }


                // Stamp FLOW_Date_Time_of_First_iBDR_Connection__c:
                // IF(
                // AND(
                // ISPICKVAL({Activity.Type},""Connected""),
                // OR(
                // CONTAINS({Activity.AssignedUserTitle},""iBDR""),
                // CONTAINS({Activity.AssignedUserTitle},""Inbound"")),
                // OR(
                // ISBLANK({Lead.FLOW_Date_Time_of_First_iBDR_Connection__c}),
                // {Lead.FLOW_Date_Time_of_First_iBDR_Connection__c}>{Activity.CreatedDate})),{Activity.CreatedDate},
                // {!Lead.FLOW_Date_Time_of_First_iBDR_Connection__c})"
                //      
                String ownerTitle = mapTaskIdOwnerTitle.get(t.Id);
                Boolean isIBDR = (String.isNotBlank(ownerTitle) && ownerTitle.containsIgnoreCase('ibdr'));
                Boolean isInbound = (String.isNotBlank(ownerTitle) && ownerTitle.containsIgnoreCase('Inbound'));
                if (
                    t.Type == 'Connected'
                    && (isIBDR || isInbound) 
                    && (l.FLOW_Date_Time_of_First_iBDR_Connection__c == null || l.FLOW_Date_Time_of_First_iBDR_Connection__c > t.CreatedDate) 
                        ){

                    l.FLOW_Date_Time_of_First_iBDR_Connection__c = t.CreatedDate;
                    updateLead = true;
                }
                
                if (updateLead) {
                    lstUpdateLeads.add(l);
                }

            }
            if (lstUpdateLeads.size() > 0) {
                update lstUpdateLeads;
            }
        }  
    }*/
    
    /*
    private void accountActivityRollUpForTaskInsert(){
        
        Set<Id> newAcctIds = new Set<Id>();
        System.debug('accountActivityRollUpForTaskInsert: In task trigger handler - Insert use case');
        
        for(Task t : triggerNew){
            if(t.AccountId <> null && t.ActivityDate <> null){
                newAcctIds.add(t.AccountId);
            }
        }
        
        if(!newAcctIds.isEmpty()){
            List<Account> acctRecs = [Select Id,
                                             ParentId,
                                             Parent.ParentId,
                                             Parent.Parent.ParentId,
                                             Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.Parent.ParentId 
                                               from account where Id in: newAcctIds];
            
            if(!acctRecs.isEmpty()){
            
                for(Task t : triggerNew){
                     
                    for(Account a : acctRecs){
                        
                        if(a.Id != null){
                            newAcctIds.add(a.Id);
                        }
                        if(a.ParentId != null){
                            newAcctIds.add(a.ParentId);
                        }
                        if(a.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.ParentId);
                        }
                        if(a.Parent.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.Parent.ParentId);
                        }
                        if(a.Parent.Parent.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.Parent.Parent.ParentId);
                        }
                        if(a.Parent.Parent.Parent.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.Parent.Parent.Parent.ParentId);
                        }
                        if(a.Parent.Parent.Parent.Parent.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.Parent.Parent.Parent.Parent.ParentId);
                        }
                    } 
                }
            }
            
            
            if(!newAcctIds.isEmpty() && !Test.isRunningTest()){
                System.debug('accountActivityRollUpForTaskInsert: Calling batch class using Acc Ids ' +newAcctIds);
                Database.executeBatch(new AccountMaxActivityRollUpBatch(newAcctIds), 10);
            } 
        }
        
    }
    
    private void accountActivityRollUpForTaskUpdate(){
        
        System.debug('accountActivityRollUpForTaskUpdate: In task trigger handler - Update use case');
        
        Set<Id> newAcctIds = new Set<Id>();
        for(Task t : triggerNew){
            if(t.AccountId <> null && t.ActivityDate <> null && t.ActivityDate <> triggerOldmap.get(t.Id).ActivityDate){
                newAcctIds.add(t.AccountId);
            }
        }
        
        if(!newAcctIds.isEmpty()){
            List<Account> acctRecs = [Select Id,
                                             ParentId,
                                             Parent.ParentId,
                                             Parent.Parent.ParentId,
                                             Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.Parent.ParentId 
                                               from account where Id in: newAcctIds];
            
            if(!acctRecs.isEmpty()){
            
                for(Task t : triggerNew){
                     
                    for(Account a : acctRecs){
                        
                        if(a.Id != null){
                            newAcctIds.add(a.Id);
                        }
                        if(a.ParentId != null){
                            newAcctIds.add(a.ParentId);
                        }
                        if(a.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.ParentId);
                        }
                        if(a.Parent.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.Parent.ParentId);
                        }
                        if(a.Parent.Parent.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.Parent.Parent.ParentId);
                        }
                        if(a.Parent.Parent.Parent.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.Parent.Parent.Parent.ParentId);
                        }
                        if(a.Parent.Parent.Parent.Parent.Parent.ParentId != null){
                            newAcctIds.add(a.Parent.Parent.Parent.Parent.Parent.ParentId);
                        }
                    } 
                }
            }
            
            if(!newAcctIds.isEmpty() && !Test.isRunningTest()){
                System.debug('accountActivityRollUpForTaskUpdate: Calling batch class using Acc Ids ' +newAcctIds);
                Database.executeBatch(new AccountMaxActivityRollUpBatch(newAcctIds), 10);
            } 
        }
        
    }
    */
}
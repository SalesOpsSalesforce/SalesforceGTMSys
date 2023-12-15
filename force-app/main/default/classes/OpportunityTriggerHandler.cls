/* *********
*  Date:            10/2019
*  Description:     Handler to update Opportunity for trigger actions
*  Developer:   OpFocus
* *********/
public with sharing class OpportunityTriggerHandler extends TriggerHandler {

    @TestVisible private static Boolean isFirstTimeInsert = true;
    @TestVisible private static Boolean isFirstTimeUpdate = true;
    @TestVisible private static Boolean isFirstTimeBeforeUpdate = true; //[vrajapatruni 09/12/2022 SFDC-200] Add update scenario for auto close salesforce created opportunities

    private List<Opportunity> triggerNew = (Opportunity[]) Trigger.new;
    private List<Opportunity> triggerOld = (Opportunity[]) Trigger.old;
    private Map<Id, Opportunity> triggerNewmap = (Map<Id, Opportunity>) Trigger.newMap;
    private Map<Id, Opportunity> triggerOldmap = (Map<Id, Opportunity>) Trigger.oldMap;

    // ----------- OVERRIDE METHODS ----------------
    // [vrajapatruni SFDC-965 AND 1212] Remove all code related to auto close functionality
    public override void afterInsert()
    {
        if (isFirstTimeInsert) {
            partnerMRRRollup();
            isFirstTimeInsert = false;
        }
    }

    public override void beforeUpdate()
    {
        for (Opportunity opportunityRecord : (List<Opportunity>)Trigger.new) {
            //if (opportunityRecord.IsWon && (opportunityRecord.IsWon != triggerNewmap.get(opportunityRecord.Id).IsWon || Test.isRunningTest()) && opportunityRecord.Primary_Quote__c != null) {
            if (opportunityRecord.IsWon && opportunityRecord.Contract__c != null && opportunityRecord.Primary_Quote__c != null && opportunityRecord.Trigger_Order_Creation__c == triggerOldmap.get(opportunityRecord.Id).Trigger_Order_Creation__c) {
                opportunityRecord.Trigger_Order_Creation__c = true;
            }
        }
    }

    public override void afterUpdate()
    {
        Map<Id, Opportunity> mapOfOldOpty = (Map<Id, Opportunity>)Trigger.oldmap;
        Map<Id, Opportunity> mapOfOptyAsParam = new Map<Id, Opportunity>();
        for(Opportunity opportunityRecord : (List<Opportunity>)Trigger.new){
            if(opportunityRecord.Trigger_Order_Creation__c == true && (opportunityRecord.Trigger_Order_Creation__c != mapOfOldOpty.get(opportunityRecord.Id).Trigger_Order_Creation__c)){
                mapOfOptyAsParam.put(opportunityRecord.Id, opportunityRecord);
            }
        }
        if(!mapOfOptyAsParam.isEmpty()){
            //OrderCreation.createOrder(JSON.serialize(mapOfOptyAsParam));
            OrderCreation.createOrder(mapOfOptyAsParam);
        }
        
        Organization Org = [Select Id, Name, IsSandbox from Organization];
        // [vrajapatruni SFDC-3174] Slack Integration  
        if((!Org.isSandbox || Test.isRunningTest()) && !System.isBatch() && !System.isQueueable() && !System.isScheduled() && !System.isFuture()){
            Map<String, String> mapOfOpportunity = new Map<String, String>();
            for(Opportunity opportunityRecord : (List<Opportunity>)Trigger.new){
                if(opportunityRecord.Approver_Level_Number_Backend__c != null && opportunityRecord.Approver_Level_Number_Backend__c != 0 && ((Map<Id, Opportunity>)Trigger.oldMap).containskey(opportunityRecord.Id) && opportunityRecord.Approver_Level_Number_Backend__c != ((Map<Id, Opportunity>)Trigger.oldMap).get(opportunityRecord.Id).Approver_Level_Number_Backend__c){
                    mapOfOpportunity.put(opportunityRecord.Id, opportunityRecord.Name);
                    }
            }
            if(!mapOfOpportunity.isEmpty()){
                SendMessageToSlack.SendMessage(mapOfOpportunity);
            }
        }
            
        // [vrajapatruni SFDC-] Auto Order Creation on Closed Won Opp with primary quote 
        if (isFirstTimeUpdate || Test.isRunningTest()) {
            partnerMRRRollup();
            isFirstTimeUpdate = false;
        }
    }
    
    // ----------- PRIVATE METHODS ----------------

    //
    // Partner Attributed MRR - Opportunity trigger
    //
    // Rolls up all won opportunities that are attributed to a partner
    //
        /*
        Criteria:
       Opportunity is moved to Closed Won,
        && RP_Referral_Partner_Account__c is not null,
        && SALES_PayoutAmounttoReferralPartner__c != ""No - No Payout - Not Part of the Program"" & != null
        OR
        Opportunity Update_Widget__c is changed

        Actions:

        1. 
        Get all opportunities where Stage = Closed Won,
        && RP_Referral_Partner_Account__c is the same as the Opportunity's RP_Referral_Partner_Account__c,
        && SALES_PayoutAmounttoReferralPartner__c != ""No - No Payout - Not Part of the Program"" & != null

        Stamp total Amount of all opportunities in collection in RP_ReferralPartner_Account__r.FL_Current_Attributed_Agency_MRR__c

        2. 
        Get all opportunities where Stage = Closed Won,
        && RP_Referral_Partner_Account__c is the same as the Opportunity's RP_Referral_Partner_Account__c,
        && SALES_PayoutAmounttoReferralPartner__c != ""No - No Payout - Not Part of the Program"" & != null

        Type__c = ""Land: New Account"" or ""Land: Account Reactivation"" count as +1, 
        Type__c = ""Cancellation"" count as -1, 
        Stamp total count of collection in RP_ReferralPartner_Account__r.FLOW_Current_Attributed_Paying_Customers__c

        3. 
        Get all opportunities where Stage = Closed Won,
        && RP_Referral_Partner_Account__c is the same as the Opportunity's RP_Referral_Partner_Account__c,
        && SALES_PayoutAmounttoReferralPartner__c != ""No - No Payout - Not Part of the Program"" & != null

        Type__c = ""Land: New Account"" or ""Land: Account Reactivation"" count as +1, 
        Stamp total count of all opportunities in collection in RP_ReferralPartner_Account__r.FLOW_All_Paid_Klaviyo_Customer_Referred__c

        4. 
        Get all opportunities where Stage = Closed Won,
        && RP_Referral_Partner_Account__c is the same as the Opportunity's RP_Referral_Partner_Account__c,
        && SALES_PayoutAmounttoReferralPartner__c != ""No - No Payout - Not Part of the Program"" & != null
        && Type__c = "Land: New Account" or "Land: Account Reactivation" 
        && Sort by most recent Close Date

        Stamp Close Date of most recently closed opportunity in collection in RP_ReferralPartner_Account__r.FLOW_Date_of_Most_Recent_RP_Customer__c
        */

    private void partnerMRRRollup()
    {
        Set <Id> setRefAccountIds = new Set <Id> ();
        
        for (Opportunity o : triggerNew) {
            String msg = '';
            msg += ' Name: ' + o.Name;
            msg += ' IsClosed: ' + o.IsWon;
            msg += ' RP_Referral_Partner_Account__c: ' + o.RP_Referral_Partner_Account__c;
            msg += ' Update_Widget__c: ' + o.Update_Widget__c;
            msg += ' SALES_PayoutAmounttoReferralPartner__c: ' + o.SALES_PayoutAmounttoReferralPartner__c;
            System.debug(LoggingLevel.INFO, '=========>>>> partnerMRRRollup, checking opp: '+msg);
            
            if (
            ( o.IsClosed && o.IsWon 
                && ((triggerOld == null || triggerOld.isEmpty()) || (!triggerOldmap.get(o.Id).IsClosed && !triggerOldmap.get(o.Id).IsWon))
                && o.RP_Referral_Partner_Account__c != null
                && ((String.isNotEmpty(o.SALES_PayoutAmounttoReferralPartner__c) && o.SALES_PayoutAmounttoReferralPartner__c != 'No - Not Part of the Program')))
                || ((triggerOld == null || triggerOld.isEmpty()) || o.Update_Widget__c != triggerOldmap.get(o.Id).Update_Widget__c ))
                 {

                if (o.RP_Referral_Partner_Account__c != null) {
                    setRefAccountIds.add(o.RP_Referral_Partner_Account__c);
                }
            }
        }
        System.debug(LoggingLevel.INFO, '=========>>>> partnerMRRRollup, updating accounts: '+setRefAccountIds);

        // can this be zero?
        List <Opportunity> lstMatchingOpps = 
            [select Id, RP_Referral_Partner_Account__c, Type__c, CloseDate, Amount, FM_Days_From_New_Account_Close__c, Opportunity_Product__c, PRODUCT_Opportunity_Product__c, AccountID, Name 
             from Opportunity 
             where 
                IsWon = TRUE
                and RP_Referral_Partner_Account__c in :setRefAccountIds
                and SALES_PayoutAmounttoReferralPartner__c <> null
                and SALES_PayoutAmounttoReferralPartner__c <> 'No - Not Part of the Program'
             order by CloseDate DESC
            ];
        
        System.debug(LoggingLevel.INFO, '=========>>>> partnerMRRRollup, found opportunities: '+lstMatchingOpps);
        Map <Id, Account> mapAccountIdAccount = new Map <Id, Account> ();
        for (Id i : setRefAccountIds) {
            Account a = new Account(Id=i);
            
            a.FL_Current_Attributed_Agency_MRR__c = 0.0;
            a.FLOW_Current_Attributed_Paying_Customers__c = 0;
            a.FLOW_All_Paid_Klaviyo_Customer_Referred__c = 0;
            a.FLOW_Date_of_Most_Recent_RP_Customer__c = null;

            mapAccountIdAccount.put(i, a);
        }
        
        Set <String> setTypesPlus = new Set <String> {'Land: New Account', 'Land: Account Reactivation'};
        
        for (Opportunity o : lstMatchingOpps) {
            Account a = mapAccountIdAccount.get(o.RP_Referral_Partner_Account__c);
            System.debug(LoggingLevel.INFO, '=========>>>> opportunity: '+o+', account: ' +a);

            if (o.Amount != null) {
                a.FL_Current_Attributed_Agency_MRR__c += o.Amount;
            }


            if (setTypesPlus.contains(o.Type__c)) {
                a.FLOW_Current_Attributed_Paying_Customers__c += 1;
                a.FLOW_All_Paid_Klaviyo_Customer_Referred__c += 1;

                if (a.FLOW_Date_of_Most_Recent_RP_Customer__c == null) {
                    a.FLOW_Date_of_Most_Recent_RP_Customer__c = o.CloseDate;
                }
            }
            else if (String.isNotBlank(o.Type__c) && o.Type__c.equals('Cancellation')) {
                a.FLOW_Current_Attributed_Paying_Customers__c += -1;
            }

            // [vrajapatruni 02/07/2023 SFDC-1581] Moved the logic for FLOW_MRRAttributedtoAgencyinLastYear__c and SMS_MRR_Attributed_to_Agency_Last_Year__c to PartnerAccountTotalMRRBatch
            
        }

        System.debug(LoggingLevel.INFO, '=========>>>> updating accounts: '+mapAccountIdAccount.values());
        if (mapAccountIdAccount.values().size() > 0) {
            update mapAccountIdAccount.values();
        }

    }
    
}
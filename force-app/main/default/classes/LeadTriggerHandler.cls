/* *********
*  Date:            10/2019
*  Description:     Handler to update Lead for trigger actions
*  Developer:   OpFocus
* *********/
public with sharing class LeadTriggerHandler extends TriggerHandler {

    @TestVisible private static Boolean isFirstTimeInsert = true;
    @TestVisible private static Boolean isFirstTimeUpdate = true;

    @TestVisible private List<Lead> triggerNew = (List<Lead>) Trigger.new;
    @TestVisible private List<Lead> triggerOld = (List<Lead>) Trigger.old;
    @TestVisible private Map<Id, Lead> triggerNewmap = (Map<Id, Lead>) Trigger.newMap;
    @TestVisible private Map<Id, Lead> triggerOldmap = (Map<Id, Lead>) Trigger.oldMap;

    // ----------- OVERRIDE METHODS ----------------

    public override void beforeInsert() {
               
        //calcRegionForCountryCode();//[RGaokar 10/06/2022] SFDC-213 Automation Cleanup - Moving calcRegionForCountryCode & calcRegionForCountry in Lead before save flow
        updateMQLandWorkableDates();
        linkToKPU();
        //Stamp_RP_Time_of_Lead_Submission(); //[vrajapatruni 01/06/2021] This method is for Stamp_RP_Time_of_Lead_Submission Process Builder
        //[RGaokar 04/18/2022 TP #117943 Method Stamp_Sales_Initial_Stamp_of_Working_BDR reverted back to apex and removed from before save flow as Leandata trigger is not processing flow logic]
        //[RGaokar 03/28/2022 TP #92538 Method Stamp_Sales_Initial_Stamp_of_Working_BDR moved to lead before save flow]
        Stamp_Sales_Initial_Stamp_of_Working_BDR(); //[vrajapatruni 01/12/2021] This method is for Stamp_Sales_Initial_Stamp_of_Working_BDR Process Builder
        //[12/29/2021 RGaokar TP #92539 The method Lead_No_Show_Update_Lead_status is moved to before save flow]
        //Lead_No_Show_Update_Lead_status(); //[vrajapatruni 01/20/2021] This method is for Lead No Show - Update Lead Status Process Builder
        Stamp_Sales_Lead_Status_Date_Stamps(); //[vrajapatruni 02/04/2021] This method is for Stamp_Sales_Lead_Status_Date_Stamps_and_Working_BDR_Flow Process Builder
        LeadTriggerHandlerWithoutSharing.getMatchLead(triggerNew);//[RGaokar 12/06/2021 TP #97229]Match lead for deduplication logic         
     }     
    
    public override void beforeUpdate() {
        
        //calcRegionForCountry();//[RGaokar 10/06/2022] SFDC-213 Automation Cleanup - Moving calcRegionForCountryCode & calcRegionForCountry in Lead before save flow
        updateMQLandWorkableDates();
        linkToKPU();
        //Stamp_RP_Time_of_Lead_Submission(); //[vrajapatruni 01/06/2021] This method is for Stamp_RP_Time_of_Lead_Submission Process Builder
        //[RGaokar 04/18/2022 TP #117943 Method Stamp_Sales_Initial_Stamp_of_Working_BDR reverted back to apex and removed from before save flow as Leandata trigger is not processing flow logic]
        //[RGaokar 03/28/2022 TP #92538 Method Stamp_Sales_Initial_Stamp_of_Working_BDR moved to lead before save flow]
        Stamp_Sales_Initial_Stamp_of_Working_BDR(); //[vrajapatruni 01/12/2021] This method is for Stamp_Sales_Initial_Stamp_of_Working_BDR Process Builder
        //[12/29/2021 RGaokar TP #92539 The method Lead_No_Show_Update_Lead_status is moved to before save flow]
        //Lead_No_Show_Update_Lead_status(); //[vrajapatruni 01/20/2021] This method is for Lead No Show - Update Lead Status Process Builder
        Stamp_Sales_Lead_Status_Date_Stamps(); //[vrajapatruni 02/04/2021] This method is for Stamp_Sales_Lead_Status_Date_Stamps_and_Working_BDR_Flow Process Builder
        //[RGaokar 03/03/2022 TP #92543] This method is moved to before save flow
        //Stamp_Sales_Initial_Touch_Time(); //[vrajapatruni 03/02/2021] This method is for Stamp_Sales_Initial Touch Time Process Builder
           
    }

    public override void afterInsert() {
        //[RGaokar 03/03/2022 TP #92543] This method is moved to before save flow
        //Stamp_Sales_Initial_Touch_Time(); //[vrajapatruni 03/02/2021] This method is for Stamp_Sales_Initial Touch Time Process Builder
        //[12/29/2021 RGaokar TP #92545 The method Lead_No_Show_Update_Lead_status_Email_Alert is moved to after save flow]
        //Lead_No_Show_Update_Lead_status_Email_Alert();
        //[RGaokar 02/14/2022 TP #106769] This method is moved to AutoConvertLeads class as an Invocable action which is called from lead after save flow.
        //LeadTriggerHandlerWithoutSharing.onLeadAPIAutoConvert(Trigger.new);//[RGaokar 10/28/2021 TP #92547] This method is from onLeadAPIAutoConvert trigger which is consolidated to lead trigger.
        alexaRankUpdate(Trigger.new,null);//[RGaokar 11/10/2021 TP #94326] Leads update with Alexa Rank
        LeadTriggerHandlerWithoutSharing.getSimilarWebMetrics(Trigger.new,null);//[RGaokar 04/29/2022 TP #119625] Lead Data Enrichment using SimilarWeb
        LeadTriggerHandlerWithoutSharing.charmDataEnrichment(Trigger.new,null);//[RGaokar 04/27/2022 TP #119370] Lead Data Enrichment using Charm io
    }
     
    public override void afterUpdate() {
        //[12/29/2021 RGaokar TP #92545 The method Lead_No_Show_Update_Lead_status_Email_Alert is moved to after save flow]
        //Lead_No_Show_Update_Lead_status_Email_Alert();
        //[RGaokar 02/14/2022 TP #106769] This method is moved to AutoConvertLeads class as an Invocable action which is called from lead after save flow.
        //LeadTriggerHandlerWithoutSharing.onLeadAPIAutoConvert(Trigger.new);//[RGaokar 10/28/2021 TP #92547] This method is from onLeadAPIAutoConvert trigger which is consolidated to lead trigger.
        alexaRankUpdate(Trigger.new, triggerOldmap); //[RGaokar 11/10/2021 TP #94326] Leads update with Alexa Rank
        LeadTriggerHandlerWithoutSharing.mergeLead(triggerNew,triggerOldmap);//[RGaokar 12/09/2021 TP #97066]Merge lead based on deduplication logic
        LeadTriggerHandlerWithoutSharing.getSimilarWebMetrics(Trigger.new,triggerOldmap);//[RGaokar 04/29/2022 TP #119625] Lead Data Enrichment using SimilarWeb
        LeadTriggerHandlerWithoutSharing.charmDataEnrichment(Trigger.new,triggerOldmap);//[RGaokar 04/27/2022 TP #119370] Lead Data Enrichment using Charm io
    }

    // ----------- PRIVATE METHODS -----------------

    private void updateMQLandWorkableDates() {
        // If this functionality is disabled, don't do it
        if (!TriggerDisablementSwitchHelper.isDisabled('Lead_MQL_And_Workable')) {
            //Must be in this order because Workable depends on recalculations in MQL prior to its recalculation
            updateMQL(triggerNew, triggerOldmap);
            updateWorkableLead(triggerNew, triggerOldmap); //[vrajapatruni 12/28/2020 Added for Workable lead date stamp]
        }
    }

    private void updateMQL(List<Lead> lstLeads, Map<Id, Lead> oldMap) {
        for (Lead ld : lstLeads) {
            if (ld.FM_MQL_Flag__c && (oldMap == null || oldMap.get(ld.id) == null || !oldMap.get(ld.id).FM_MQL_Flag__c)) {
                ld.MQL_Date__c = Date.today();
            }
        }
    }

    //[vrajapatruni 12/28/2020] The below method is used for stamping the date on the lead object when certain conditions are applied on Lead/Account KPUs
    private void updateWorkableLead(List<Lead> lstLeads, Map<Id, Lead> oldMap) {
       
       Savepoint sp = Database.setSavepoint();
       List <String> executionFlow = new List <String> ();
       try{ 
            Set<Id> acctIds = new Set<Id>();
            Set<Id> kpuIds = new Set<Id>();
                        
            for (Lead ld : lstLeads) {
                executionFlow.add('Lead is (1st loop) ' +ld.Id);
                if(ld.isConverted){
                    acctIds.add(ld.ConvertedAccountId);
                }
                executionFlow.add('List of converted account Ids ' +acctIds);
                
                if(!ld.isConverted && ld.Klaviyo_Product_Usage__c != null){
                    kpuIds.add(ld.Klaviyo_Product_Usage__c);
                }
                executionFlow.add('List of KPU Ids when lead is not converted and KPU is not blank ' +kpuIds);
            }
            
            Map<Id,Account> accMap = new Map<Id,Account>([Select Id, Klaviyo_Product_Usage__c, Klaviyo_Product_Usage__r.Contact_at_Close_Date__c from Account where Id in: acctIds]);
            Map<Id,Klaviyo_Product_Usage__c> kpuMap = new Map<Id,Klaviyo_Product_Usage__c>([Select Id,Contact_at_Close_Date__c from Klaviyo_Product_Usage__c where Id in: kpuIds]);
               
            for (Lead ld : lstLeads) {
                
                executionFlow.add('Lead is (2nd loop) ' +ld.Id);
                Boolean isCanStamp = false;
                
                if(!ld.isConverted && (ld.Klaviyo_Product_Usage__c == null || (kpuMap.keySet().contains(ld.Klaviyo_Product_Usage__c) && kpuMap.get(ld.Klaviyo_Product_Usage__c).Contact_at_Close_Date__c >= 1000))){            
                
                    isCanStamp = true;
                    executionFlow.add('Lead is not converted and (KPU is null or Contact_at_Close_Date__c >= 1000)');
                }
               
                if(!ld.isConverted && ld.Klaviyo_Product_Usage__c <> null ){            
                
                    isCanStamp = true;
                    executionFlow.add('Lead is converted and KPU is not null');
                }
                           
                if(ld.isConverted && ld.ConvertedAccountId <> null && accMap.get(ld.ConvertedAccountId) <> null && accMap.get(ld.ConvertedAccountId).Klaviyo_Product_Usage__c == null)
                {             
                    isCanStamp = true;
                    executionFlow.add('Lead is converted, Converted AccountID is not null, KPU is null');
                }
                
                if(ld.isConverted && ld.ConvertedAccountId <> null && accMap.get(ld.ConvertedAccountId) <> null && (accMap.get(ld.ConvertedAccountId).Klaviyo_Product_Usage__r.Contact_at_Close_Date__c >= 1000 || accMap.get(ld.ConvertedAccountId).Klaviyo_Product_Usage__r.Contact_at_Close_Date__c == null ))
                {             
                    isCanStamp = true;
                    executionFlow.add('Lead is converted, Converted AccountID is not null, Contact at close date >= 1000 or null');
                }
                
                if(isCanStamp && ld.FORMULA_Workable_Lead__c && (oldMap == null || oldMap.get(ld.Id) == null || !oldMap.get(ld.id).FORMULA_Workable_Lead__c || ld.CanLeadDatebeStamped__c)) {
                
                    ld.Workable_Date__c = Date.today();
                    ld.CanLeadDatebeStamped__c = false;
                    executionFlow.add('Lead workable date '+ld.Workable_Date__c);
                }
            } 
        }
        
        catch(Exception e){
            Database.RollBack(sp);
            ExceptionHandling.performExceptionHandling(e, 'Exception in Update Workable Lead method', executionFlow);
            
        }
     }
  
    //[vrajapatruni 12/23/2020] The below code is for Stamp_RP_Time_of_Lead_Submission Process Builder. Added the method to before Update and Insert
   /* private void stamp_RP_Time_of_Lead_Submission(){
        
        Savepoint sp = Database.setSavepoint();
        
        List <String> executionFlow = new List <String> ();
        try{
                   
            Set<Id> acctIds = new Set<Id>();
            for(Lead l : triggerNew){
                executionFlow.add('Lead is (1st loop) ' +l.Id);
                if(l.Referral_Partner_Account__c != null)
                    acctIds.add(l.Referral_Partner_Account__c);            
            }
            executionFlow.add('List of Account IDs '+acctIds);
            
            Map<Id,Account> accMap = new Map<Id,Account>([Select Id, Services_Tier__c, 
                                                                     RP_Current_Agency_Potential__c,
                                                                     RP_Early_Access_to_Program__c,
                                                                     RP_Referral_Partner_Tier__c,
                                                                     Credited_Agency_AOS__c,
                                                                     RP_Referral_Partner_AE_of_Record__c 
                                                                 from Account where Id in: acctIds]);
                   
            for(Lead l : triggerNew){
                
                executionFlow.add('Lead is (2nd loop) ' +l.Id);
                //Exisiting Lead
                if(Trigger.isUpdate && 
                        l.isConverted == false && 
                        l.Referral_Partner_Account__c != null && 
                        l.Referral_Partner_Account__c <> triggerOldMap.get(l.Id).Referral_Partner_Account__c
                ){
                    executionFlow.add('Lead is not converted, Referral Partner Account is not null and RFA value is changed');
                    //Stamp Time of Agency Submission
                    l.RP_Time_Partner_Submitted_Lead__c = DateTime.now();
                    executionFlow.add('Stamp Time of Agency Submission' +l.RP_Time_Partner_Submitted_Lead__c);
                    
                    //Update Lead Source Fields
                    if(l.LeadSource != 'Agency'){
                        l.LeadSource = 'Agency';
                        l.MARKETING_Initial_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
                        l.MARKETING_Initial_Lead_Source__c = 'Agency';
                        l.MARKETING_Most_Recent_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
                        executionFlow.add('Lead Source is not Agency and so leadsource, initial lead source detail, MRLS and MRLS detail are set');
                    } 
                                        
                    if(l.Referral_Partner_Account__c != null){                
                       
                           
                        executionFlow.add('RPA is not null ' +l.Referral_Partner_Account__c);
                       //Stamp Tier If condition for Null exception
                        if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Platinum')    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Advisors - Platinum';   
                        else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Gold')    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Advisors - Gold'; 
                        else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Silver')    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Advisors - Silver'; 
                        else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Klaviyo Partner')    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Klaviyo Partner';  
                        else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Platinum' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == TRUE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Influencers - Platinum';   
                        else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Gold' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == TRUE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Influencers - Gold'; 
                        else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Silver' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == TRUE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Influencers - Silver'; 
                        else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Platinum' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == FALSE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Platinum';   
                        else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Gold' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == FALSE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Gold'; 
                        else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Silver' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == FALSE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Silver';  
                        
                        //Update Agency Potencial
                        // if(String.isBlank(l.RP_Agency_Potential_at_Submission__c))
                        l.RP_Agency_Potential_at_Submission__c = accMap.get(l.Referral_Partner_Account__c).RP_Current_Agency_Potential__c;
                        
                        //Update AE of Record From Partner
                        l.AE_of_Record_at_Date_of_Lead_Submission__c = accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_AE_of_Record__c;
                        
                        //Update Payout Amount blank condition can be generic    
                        if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Silver')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Advisors Silver - 10%';
                        else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Gold')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Advisors Gold - 15%'; 
                        else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Platinum')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Advisors Platinum - 20%';
                        else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Klaviyo Partner')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Klaviyo Partner - 10%';   
                        else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Silver')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Influencers Silver - 5%';
                        else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Gold')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Influencers Gold - 10%'; 
                        else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Platinum')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Influencers Platinum - 15%'; 
                                
                        //Update Credited AOS
                        l.Credited_Agency_AOS__c = accMap.get(l.Referral_Partner_Account__c).Credited_Agency_AOS__c; 
                    } 
                    
                    //Stamp Account - RP Field
                    l.FLOW_ACCOUNT_Referral_Partner_Account__c = l.Referral_Partner_Account__c;
                    
                }
     
                //New Lead  
                if(Trigger.isInsert && l.Referral_Partner_Account__c != null){
                    
                        
                    executionFlow.add('New lead is created and RPA is not null. Its value is ' +l.Referral_Partner_Account__c);
                    l.RP_Time_Partner_Submitted_Lead__c = DateTime.now();  
                                    
                    if(l.LeadSource != 'Agency'){
                        l.LeadSource = 'Agency';
                        l.MARKETING_Initial_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
                        l.MARKETING_Initial_Lead_Source__c = 'Agency';
                        l.MARKETING_Most_Recent_Lead_Source_Detail__c = 'Agency - Verbal Referral/Non-Form Submission';
                     }
                    
                    //Stamp Tier
                    if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Platinum')    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Advisors - Platinum';   
                    else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Gold')    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Advisors - Gold'; 
                    else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Silver')    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Advisors - Silver'; 
                    else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Klaviyo Partner')    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Klaviyo Partner'; 
                                  
                    else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Platinum' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == TRUE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Influencers - Platinum';   
                    else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Gold' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == TRUE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Influencers - Gold'; 
                    else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Silver' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == TRUE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Influencers - Silver'; 
                                                
                    else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Platinum' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == FALSE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Platinum';   
                    else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Gold' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == FALSE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Gold'; 
                    else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Silver' && accMap.get(l.Referral_Partner_Account__c).RP_Early_Access_to_Program__c == FALSE)    
                            l.RP_Referral_Partner_Tier_at_Submission__c = 'Silver'; 
                    
                    //l.RP_Agency_Potential_at_Submission__c = l.Referral_Partner_Account__r.RP_Current_Agency_Potential__c;
                    l.RP_Agency_Potential_at_Submission__c = accMap.get(l.Referral_Partner_Account__c).RP_Current_Agency_Potential__c;
                    
                    //AE of Record From Partner
                    l.AE_of_Record_at_Date_of_Lead_Submission__c = accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_AE_of_Record__c;
                    
                    //Stamp Account RP field
                    l.FLOW_ACCOUNT_Referral_Partner_Account__c = l.Referral_Partner_Account__c;
                    
                    //Stamp Payout Amount                            
                    if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Silver')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Advisors Silver - 10%';
                    else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Gold')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Advisors Gold - 15%'; 
                    else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Platinum')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Advisors Platinum - 20%';
                    else if(accMap.get(l.Referral_Partner_Account__c).Services_Tier__c == 'Klaviyo Partner')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Klaviyo Partner - 10%';   
                    else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Silver')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Influencers Silver - 5%';
                    else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Gold')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Influencers Gold - 10%'; 
                    else if(accMap.get(l.Referral_Partner_Account__c).RP_Referral_Partner_Tier__c == 'Platinum')    
                            l.SALES_PayoutAmounttoReferralPartner__c = 'Yes - Influencers Platinum - 15%'; 
                    
                    //Credited AOS
                    l.Credited_Agency_AOS__c = accMap.get(l.Referral_Partner_Account__c).Credited_Agency_AOS__c; 
                               
                }
                
            //Reset the entries when the RP is changed to null
            if(Trigger.isUpdate &&
                   l.isConverted == false && 
                   l.Referral_Partner_Account__c == null && 
                   l.Referral_Partner_Account__c <> triggerOldMap.get(l.Id).Referral_Partner_Account__c
             ){
                        executionFlow.add('Existing lead is updated, not converted, RPA is null and RPA value is changed');
                        //Stamp Time of Agency Submission
                        l.RP_Time_Partner_Submitted_Lead__c = null;
                   
                        //Stamp Tier If condition for Null exception
                        l.RP_Referral_Partner_Tier_at_Submission__c = null;
                         
                        //Update Agency Potencial
                        l.RP_Agency_Potential_at_Submission__c = null;
                        
                        //Update AE of Record From Partner
                        l.AE_of_Record_at_Date_of_Lead_Submission__c = null;
                        
                        //Update Payout Amount blank condition can be generic
                        l.SALES_PayoutAmounttoReferralPartner__c = null; 
                                
                        //Update Credited AOS
                        l.Credited_Agency_AOS__c = null; 
                    
                        //Stamp Account - RP Field
                        l.FLOW_ACCOUNT_Referral_Partner_Account__c = null;
                     
                }  
            }            
          }
          
          catch(Exception e){
                Database.RollBack(sp);
                ExceptionHandling.performExceptionHandling(e, 'Exception in Stamp_RP_Time_of_Lead_Submission method', executionFlow);
                
            }
    }*/
    //[RGaokar 04/18/2022 TP #117943 Method Stamp_Sales_Initial_Stamp_of_Working_BDR reverted back to apex and removed from before save flow as Leandata trigger is not processing flow logic]
    //[RGaokar 03/28/2022 TP #92538 Method Stamp_Sales_Initial_Stamp_of_Working_BDR moved to lead before save flow]
    //[vrajapatruni 01/12/2021] The below code is for Stamp_Sales_Initial_Stamp_of_Working_BDR.
   private void Stamp_Sales_Initial_Stamp_of_Working_BDR(){
        
        Savepoint sp = Database.setSavepoint();
        List <String> executionFlow = new List <String> ();
        try{ 
           
           Set<Id> userIds = new Set<Id>();
           for(Lead l : triggerNew){
               executionFlow.add('Lead is ' +l.Id);
               userIds.add(l.OwnerId);
            }
            executionFlow.add('List of user IDs are ' +userIds);
            
            if(userIds.size() >0){
            
                Map<Id,User> userMap = new Map<Id,User>([Select Id, Title, UserRole.Name, User.Profile.Name from User where Id in: userIds]);
                for(Lead l : triggerNew){
                    if(Trigger.isUpdate || Trigger.isInsert){
                            
                          executionFlow.add('Lead created or updated');
                          executionFlow.add('Lead is ' +l.Id);
                          //Working BDR is NULL
                          if(l.OwnerId <> null && 
                             l.Working_BDR__c == null &&
                             string.valueOf(l.OwnerId).startsWith('005') &&
                             (l.Transferred_to_aBDR__c == false || l.Transferred_to_aBDR__c == NULL) &&
                             userMap.get(l.OwnerId) <> null &&
                             userMap.get(l.OwnerId).Profile.Name == 'BDR Sales User' &&
                             userMap.get(l.OwnerId).Title <> 'aBDR'
                             //Need to confirm if the title is from Lead or from user
                            ){
                                l.Date_Time_Working_BDR_Stamped__c = DateTime.Now();
                                l.Working_BDR__c = l.OwnerId;
                                l.SALES_Working_BDR_Role__c = userMap.get(l.OwnerId).UserRole.Name;
                                executionFlow.add('Working BDR was null, Owner Id starts with 005, Transfer to aBDR false or null -> Now Working BDR got updated');
                              }
                              
                          // Transferred to aBDR
                          if(l.OwnerId <> null &&
                              string.valueOf(l.OwnerId).startsWith('005') &&
                              (Trigger.isInsert || (Trigger.isUpdate && l.OwnerId <> triggerOldMap.get(l.Id).OwnerId) ) &&
                              l.FLOW_Flip_Channel__c == null && //$GlobalConstant.Null
                              l.Manually_Route__c <> True &&
                              (l.Transferred_to_aBDR__c == false || l.Transferred_to_aBDR__c == NULL) &&
                              userMap.get(l.OwnerId) <> null &&
                              userMap.get(l.OwnerId).Profile.Name == 'BDR Sales User' &&
                              userMap.get(l.OwnerId).Title <> 'aBDR'
                             ){
                                 l.Date_Time_Working_BDR_Stamped__c = DateTime.Now();
                                 l.Working_BDR__c = l.OwnerId;
                                 l.SALES_Working_BDR_Role__c = userMap.get(l.OwnerId).UserRole.Name;
                                 executionFlow.add('Owner Id starts with 005, Flow flip is null, Transfer to aBDR is false or null, Owner role is BDR Sales user and title not equal to aBDR -> Now Working BDR got updated');
                               }   
                                  
                          // Not Flipped/Owned by BDR?
                          if(Trigger.isUpdate && l.OwnerId <> triggerOldMap.get(l.Id).OwnerId){
                             if(l.FLOW_Flip_Date_Time__c == null && userMap.get(l.OwnerId) <> null && String.isNotBlank(userMap.get(l.OwnerId).Title) &&  
                                (userMap.get(l.OwnerId).Title.contains('AE')  || 
                                  userMap.get(l.OwnerId).Title.contains('Account Executive') ||
                                  userMap.get(l.OwnerId).Title.contains('CAM'))
                                 ){
                                   // Clear out Working BDR
                                     l.SALES_Working_BDR_Role__c = ''; //$GlobalConstant.EmptyString
                                     l.Working_BDR__c = null; //$GlobalConstant.Null
                                     executionFlow.add('Lead is updated and owner is changed, Owner Id title contains AE, Account Executive or CAM');
                                 }
                           }  
                     }
                 } 
           } 
       }
       
        catch(Exception e){
                Database.RollBack(sp);
                ExceptionHandling.performExceptionHandling(e, 'Exception in Stamp_Sales_Initial_Stamp_of_Working_BDR', executionFlow);
            }       
    }

    //[12/29/2021 RGaokar TP #92539 The method Lead_No_Show_Update_Lead_status is moved to before save flow]
    //[vrajapatruni 01/20/2021] This method is for Lead No Show - Update Lead Status
   /* private void Lead_No_Show_Update_Lead_status(){
    
        Savepoint sp = Database.setSavepoint();
        List <String> executionFlow = new List <String> ();
        try{ 
            
            for(Lead l : triggerNew){
                if(Trigger.isUpdate || Trigger.isInsert){
                     
                     executionFlow.add('Lead is created or updated');
                     executionFlow.add('Lead is ' +l.Id);
                     // Lead is no show
                     if(l.Showed_for_Demo__c == 'No Show' && l.Status <> 'Qualified - Partner Working on Lead' && 
                         (Trigger.isInsert || (Trigger.isUpdate && (l.Showed_for_Demo__c != triggerOldMap.get(l.Id).Showed_for_Demo__c)))){
                        
                            l.Status = 'Qualified - No Show';
                            executionFlow.add('Lead is no show' +l.Id);
                        }
            
                     // Lead is Converted (No show)
                     if(Trigger.isUpdate && 
                         l.Status <> triggerOldMap.get(l.Id).Status && 
                         String.isBlank(l.Showed_for_Demo__c) && 
                         (l.Status == 'Converted' || l.Status == 'Converted to Opportunity')) {
                            
                            l.Showed_for_Demo__c = 'Show';
                            executionFlow.add('Lead is converted - no show' +l.Id);
                                
                        }
                }
            } 
        }
        
        catch(Exception e){
             Database.RollBack(sp);
             ExceptionHandling.performExceptionHandling(e, 'Exception in Lead_No_Show_Update_Lead_status method', executionFlow);
        }   
    }*/ 
    
    //[12/29/2021 RGaokar TP #92545 The method Lead_No_Show_Update_Lead_status_Email_Alert is moved to after save flow]
    //[vrajapatruni 01/20/2021] This method is for Lead No Show - Update Lead Status - Email Alert Only
   /* private void Lead_No_Show_Update_Lead_status_Email_Alert(){
        
        List <String> executionFlow = new List <String> ();
        try{
                        
            List<EmailTemplate> emailTemplate = [SELECT Id, Body, Subject from EmailTemplate where Name = 'Lead No Show Alert'];
            List<User> ListUser = [SELECT Id from User where Name = 'Alexis Caso'];
            Set<Id> flipOwnerIds = new Set<Id>();
                
            for(Lead l:triggerNew){
                executionFlow.add('Lead is ' +l.Id);
                flipOwnerIds.add(l.FLOW_Flip_Owner__c);
            }
                
            Map<Id,user> flipOwnerUsersMap = new Map<Id,User>([Select Id, Email from User where id in:flipOwnerIds]);
                    
            for(Lead l : triggerNew){
                if(Trigger.isUpdate || Trigger.isInsert){
                    
                     executionFlow.add('Lead is created or updated');
                     executionFlow.add('Lead is ' +l.Id);
                    // Lead is no show
                    if(l.Showed_for_Demo__c == 'No Show' && l.Status <> 'Qualified - Partner Working on Lead' && 
                        (Trigger.isInsert || (Trigger.isUpdate && (l.Showed_for_Demo__c != triggerOldMap.get(l.Id).Showed_for_Demo__c || l.Status != triggerOldMap.get(l.Id).Status))) ){
                                    
                        String whatId = l.Id;
                        messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplate[0].Id, ListUser[0].Id, whatId);
                        String emailSubject = email.getSubject();
                        String emailTextBody = email.getPlainTextBody();
                        email.setTargetObjectId(ListUser[0].Id);
                        email.setSubject(emailSubject);
                        email.setWhatId(whatId);
                        if(l.FLOW_Flip_Owner__c <> null){
                            email.setToAddresses(new List<String>{flipOwnerUsersMap.get(l.FLOW_Flip_Owner__c).Email});
                            system.debug('Email sent to flip owner '+flipOwnerUsersMap.get(l.FLOW_Flip_Owner__c).Email);
                        }
                        email.setPlainTextBody(emailTextBody);
                        email.saveAsActivity = false;
                        Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                        system.debug('Email details '+r);
                }
              }
          } 
        }
        
        catch(Exception e){
             ExceptionHandling.performExceptionHandling(e, 'Exception in Lead_No_Show_Update_Lead_status_Email_Alert method', executionFlow);
            }    
    }*/
    
    //[vrajapatruni 02/04/2021] This method is for PB - Stamp_Sales_Lead_Status_Date_Stamps_and_Working_BDR_Flow
    private void Stamp_Sales_Lead_Status_Date_Stamps(){
        
        Savepoint sp = Database.setSavepoint();
        List <String> executionFlow = new List <String> ();
        try{
            
            Set<Id> ownerIds = new Set<Id>();
            
            for(Lead l : triggerNew){
                
                executionFlow.add('Lead is ' +l.Id);
                ownerIds.add(l.OwnerId);        
            }
            executionFlow.add('List of owner Ids ' +ownerIds);
            
            Map<Id, User> userMap = new Map<Id,User>([Select Id, UserRole.Name from User where Id in: ownerIds]);
            
            for(Lead l : triggerNew){
                
               executionFlow.add('Lead is ' +l.Id);
               // Lead status changed
               if(Trigger.isUpdate && (!l.isConverted) && l.Status <> 'Disqualified' && (l.Status <> triggerOldMap.get(l.Id).Status)){
                      
                      executionFlow.add('Lead is updated. not converted, status is not Disqualified and status changed');      
                      //Lead Status Before Conversion  
                      l.Lead_Status_Before_Conversion__c = l.status;
                      
                      //Prequalified
                      if(l.SALES_Time_of_Status_Change_to_Prequal__c == NULL && l.status == 'Prequalified'){
                          l.SALES_Time_of_Status_Change_to_Prequal__c = DateTime.now();
                      }
                      
                      //Attempted
                      if(l.SALES_Time_of_Status_Change_to_Attempted__c == NULL && l.status == 'Attempted'){
                          l.SALES_Time_of_Status_Change_to_Attempted__c = DateTime.now();
                      }
                      
                      //Qualiyfing
                      if(l.SALES_Time_of_Lead_Status_to_Qualifying__c == NULL && l.status == 'Qualifying'){
                          l.SALES_Time_of_Lead_Status_to_Qualifying__c = DateTime.now();
                      }
                      
                      //Qualified - Passed to Sales Rep
                      if(l.SALES_Time_of_StatusChange_to_Qual_Pass__c == NULL && l.status == 'Qualified - Passed to Sales Rep'){
                          l.SALES_Time_of_StatusChange_to_Qual_Pass__c = DateTime.now();
                      }
                                  
                      //Bought Without Engaging With Us
                      if(l.SALES_Time_of_StatusChange_AlreadyBought__c == NULL && l.status == 'Bought Without Engaging With Us'){
                          l.SALES_Time_of_StatusChange_AlreadyBought__c = DateTime.now();
                      } 
                      
                      //Bought Without Qualification
                      if(l.SALES_Time_BoughtwithoutQualification__c == NULL && l.status == 'Bought Without Qualification'){
                          l.SALES_Time_BoughtwithoutQualification__c = DateTime.now();
                      } 
                      
                      //Bought After Disqualification
                      if(l.SALES_TimeofBought_AfterDisqualification__c == NULL && l.status == 'Bought After Disqualification'){
                          l.SALES_TimeofBought_AfterDisqualification__c = DateTime.now();
                      } 
                      
                      //Most Recent Status Change
                      l.SALES_Time_of_Most_Recent_Status_Change__c = DateTime.now();
                      
                      //Bought After Qualification
                      if(l.SALES_Time_BoughtAfterQualification__c == NULL && l.status == 'Bought After Qualification'){
                          l.SALES_Time_BoughtAfterQualification__c = DateTime.now();
                      } 
                      
                      // Flow replace logic
                      if(l.OwnerId <> null && 
                          userMap.get(l.OwnerId) <> null && 
                          String.isNotBlank(userMap.get(l.OwnerId).UserRole.Name)){
                              if(userMap.get(l.OwnerId).UserRole.Name.containsIgnoreCase('BDR') && l.FLOW_Flip_Date_Time__c == null){//[RGaokar 6/9/2022 TP #125525 Excluded flipped leads for Working BDR update by adding l.FLOW_Flip_Date_Time__c == null condition]
                                   
                                   l.Working_BDR__c = l.OwnerId; 
                                   executionFlow.add('Entered flow logic -> User Role contatins BDR');   
                              }
                              
                              Else if(l.FLOW_Flip_Date_Time__c == null && 
                                  (userMap.get(l.OwnerId).UserRole.Name.containsIgnoreCase('Manager') || userMap.get(l.OwnerId).UserRole.Name.containsIgnoreCase('AE') || userMap.get(l.OwnerId).UserRole.Name.containsIgnoreCase('Account Executive') ) ){
                                     
                                      l.Working_BDR__c = null;
                                      executionFlow.add('Entered flow logic -> User Role contatins Manager, AE and Account Executive');   
                              }
                      }
               } 
                                  
               //Lead is Disqualified or Disqualification Reason is Changed
               Else if((Trigger.isInsert && l.Status == 'Disqualified') || (Trigger.isUpdate && l.Status == 'Disqualified' && (l.Status <> triggerOldMap.get(l.Id).Status))){
                      
                      executionFlow.add('Lead is created with Status as Disqualified or is updated to Disqualified Status');   
                      //Lead Status Before Conversion  
                      l.Lead_Status_Before_Conversion__c = l.status;
                      
                      //Stamp Date Fields
                      l.SALES_Time_of_Most_Recent_Status_Change__c = DateTime.now();
                      l.SALES_Time_of_Status_Change_to_Disqual__c = DateTime.now();
                      System.debug('About to enter');
                      // Flow replace logic
                      if(l.OwnerId <> null && 
                          userMap.get(l.OwnerId) <> null && 
                          String.isNotBlank(userMap.get(l.OwnerId).UserRole.Name)){
                              System.debug('Entered flow replace logic');
                              System.debug('Value of Workable Lead ' +l.FORMULA_Workable_Lead__c);
                              if(userMap.get(l.OwnerId).UserRole.Name.containsIgnoreCase('BDR') && l.FLOW_Flip_Date_Time__c == null){//[RGaokar 6/9/2022 TP #125525 Excluded flipped leads for Working BDR update by adding l.FLOW_Flip_Date_Time__c == null condition]
                                   
                                   System.debug('Entered the if');
                                   l.Working_BDR__c = l.OwnerId;
                                   executionFlow.add('Entered flow logic -> User Role contatins BDR');     
                              }
                              
                              Else if(l.FORMULA_Workable_Lead__c == false && l.FLOW_Flip_Date_Time__c == null && 
                                  (userMap.get(l.OwnerId).UserRole.Name.containsIgnoreCase('Manager') || userMap.get(l.OwnerId).UserRole.Name.containsIgnoreCase('AE') || userMap.get(l.OwnerId).UserRole.Name.containsIgnoreCase('Account Executive') ) ){
                                     
                                      System.debug('Entered the null bdr else');
                                      l.Working_BDR__c = null;
                                      executionFlow.add('Entered flow logic -> User Role contatins Manager, AE and Account Executive'); 
                              }
                      } System.debug('Crossed flow');
               }         
              
            } 
         }
         
         catch(Exception e){
             Database.RollBack(sp);
             ExceptionHandling.performExceptionHandling(e, 'Stamp_Sales_Lead_Status_Date_Stamps', executionFlow);
            }    
    }

    //[RGaokar 03/03/2022 TP #92543] This method is moved to before save flow
    //[vrajapatruni 03/02/2021] This method is for PB - Stamp_Sales_Initial Touch_Time Process Builder
    /*private void Stamp_Sales_Initial_Touch_Time(){
    	
        Savepoint sp = Database.setSavepoint();
        List <String> executionFlow = new List <String> ();
        try{
            List<Id> listLeadIds = new List<Id>();
            
            if(Trigger.isInsert || Trigger.isUpdate){
                for(Lead l : triggerNew){
                    if(l.Status <> 'Untouched' && l.FLOW_Time_of_Initial_Touch__c == Null && l.CreatedDate <> Null && l.CreatedDate >= datetime.valueOf('2016-01-20 00:00:00')
                      && l.MergeLead__c != 'Will Merge'&& l.MergeLead__c != 'Merge'){//[RGaokar 12/17/2021 l.MergeLead__c != 'Will Merge' & 'Merge' is added to avoid record locking for merge lead deduplication method(LeadTriggerHandlerWithoutSharing.mergeLead)]
                        listLeadIds.add(l.Id);
                    }
                }
            }
            
            //[RGaokar 12/17/2021 !Test.isRunningTest() is added as lead test class was hitting "No more than one executeBatch" error
            // and test coverage of Stamp_Sales_Initial_Touch_Time_Batch class is provided by testStamp_Sales_Initial_Touch_Time_Batch method in LeadTriggerHandlerTest]
            if(!listLeadIds.isEmpty() && !System.isBatch() && !System.isFuture() && !Test.isRunningTest()){
                Database.executeBatch(new Stamp_Sales_Initial_Touch_Time_Batch(listLeadIds),1);
            }
        }
        
        catch(Exception e){
             Database.RollBack(sp);
             ExceptionHandling.performExceptionHandling(e, 'Stamp_Sales_Initial_Touch_Time', executionFlow);
        }    
    }*/
  
    //[RGaokar 10/06/2022] SFDC-213 Automation Cleanup - Moving calcRegionForCountryCode & calcRegionForCountry in Lead before save flow
    // When a Lead is created, if it has a Country Code (MARKETING_SignupFormField_7__c),
    // use it to find the matching Region in Country_and_Region_Mapping__mdt.
    // Called on Before Insert
    /*private void calcRegionForCountryCode() {

        // If this functionality is disabled, don't do it
        if (TriggerDisablementSwitchHelper.isDisabled('Lead_Country_Code_And_Region_Mapping')) {
            return;
        }

        // Get a list of Country Codes to look up
        Set<String> setCodes = new Set<String>();
        for (Lead ld : triggerNew) {
            if (ld.MARKETING_SignupFormField_7__c != null) setCodes.add(ld.MARKETING_SignupFormField_7__c);
        }
        if (!setCodes.isEmpty()) {
            // Create a map of Regions, indexed by Country Code
            List<Country_and_Region_Mapping__mdt> lstMappings =
                [select id, Region__c, Country_Code__c
                 from   Country_and_Region_Mapping__mdt
                 where  Country_Code__c in :setCodes];

            Map<String, String> mapRegionsByCountryCode = new Map<String, String>();
            for (Country_and_Region_Mapping__mdt mapping : lstMappings) {
                mapRegionsByCountryCode.put(mapping.Country_Code__c.toLowerCase(), mapping.Region__c);
            }

            // Use the map to assign the correct Region to each Lead
            for (Lead ld : triggerNew) {
                if (ld.MARKETING_SignupFormField_7__c != null) {
                    String countryCode = ld.MARKETING_SignupFormField_7__c.toLowerCase();
                    if (mapRegionsByCountryCode.containsKey(countryCode)) {
                        String region = mapRegionsByCountryCode.get(countryCode);
                        ld.SALES_Geographical_Location__c = region;
                    }
                }
            }
        }
    }


    // When a Lead is updated, if it has a Country (Country_Location__c) and its
    // FLOW_Flip_Channel__c has changed and is not null, use the Country to
    // to find the matching Region in Country_and_Region_Mapping__mdt.
    // Called on Before Update
    private void calcRegionForCountry() {
        // Get a list of Country to look up
        Set<String> setCountries = new Set<String>();
        for (Lead ld : triggerNew) {
            Lead ldOld = triggerOldmap.get(ld.Id);
            // If the Lead has a Country and its Flow Flip Channel is non-null and has changed
            if (ld.Country_Location__c != null &&
                   ld.Country_Location__c != ldOld.Country_Location__c) {
                setCountries.add(ld.Country_Location__c);
            }
        }
        if (!setCountries.isEmpty()) {
            // Create a map of Regions, indexed by Country.
            // The Country is the Label field.
            List<Country_and_Region_Mapping__mdt> lstMappings =
            [select id, Region__c, Label
            from   Country_and_Region_Mapping__mdt
            where  Label in :setCountries];

            Map<String, String> mapRegionsByCountry = new Map<String, String>();
            for (Country_and_Region_Mapping__mdt mapping : lstMappings) {
                mapRegionsByCountry.put(mapping.Label.toLowerCase(), mapping.Region__c);
            }

            // Use the map to assign the correct Region to each Lead
            for (Lead ld : triggerNew) {
                Lead ldOld = triggerOldmap.get(ld.Id);
                if (ld.Country_Location__c != null  &&
                   ld.Country_Location__c != ldOld.Country_Location__c) {
                    String country = ld.Country_Location__c.toLowerCase();
                    if (mapRegionsByCountry.containsKey(country)) {
                        String region = mapRegionsByCountry.get(country);
                        ld.SALES_Geographical_Location__c = region;
                    }
                }
            }
        }
    }*/

    // When a Lead is created with a non-blank Klaviyo_Account_Id__c or a Lead is updated and its Klaviyo_Account_Id__c is changed and is non-blank, a trigger should:
    //   Create a Klaviyo Product Usage record with that Klaviyo Account Id if one does not already exist.
    //   Update the Lead to set its Klaviyo Product Usage field to look up to the new or existing record.
    //
    private void linkToKPU() {

        // If this functionality is disabled, don't do it
        if (TriggerDisablementSwitchHelper.isDisabled('Klaviyo_Product_Usage_Creation_Triggers')) {
            return;
        }

        List<Lead> lstProcess = new List<Lead>();
        Set<String> kaIds = new Set<String>();
        for(Lead l : triggerNew) {
            if(l.Klaviyo_Account_ID__c != null &&
                    (Trigger.isInsert ||
                    (Trigger.isUpdate && triggerOldmap.get(l.Id).Klaviyo_Account_ID__c != l.Klaviyo_Account_ID__c))){
                lstProcess.add(l);
                kaIds.add(l.Klaviyo_Account_ID__c);
            }
        }

        if(lstProcess.isEmpty()) return;
        System.debug('kaIds: ' + JSON.serialize(kaIds));

        // find existing KPU records
        Klaviyo_Product_Usage__c[] lstKPU = [Select Id, Klaviyo_Account_ID__c from Klaviyo_Product_Usage__c where Klaviyo_Account_ID__c in :kaIds];
        Map<String, Klaviyo_Product_Usage__c> mapKPU = new Map<String, Klaviyo_Product_Usage__c>();
        for(Klaviyo_Product_Usage__c kpu : lstKPU) {
            mapKPU.put(kpu.Klaviyo_Account_ID__c, kpu);
            kaIds.remove(kpu.Klaviyo_Account_ID__c);
        }

        System.debug('kaIds: ' + JSON.serialize(kaIds));

        // now the only KPU keys left are ones that don't exist. Insert the new records
        List<Klaviyo_Product_Usage__c> newKPUS = new List<Klaviyo_Product_Usage__c>();
        for(String ka : kaIds) {
            Klaviyo_Product_Usage__c kpu = new Klaviyo_Product_Usage__c();
            kpu.Klaviyo_Account_ID__c = ka;
            mapKPU.put(kpu.Klaviyo_Account_ID__c, kpu);
            newKPUS.add(kpu);
        }
        System.debug('newKPUS: ' + JSON.serializePretty(newKPUS));
        insert newKPUS;

        // link the KPU record to the lead
        for(Lead l : lstProcess) {
            Klaviyo_Product_Usage__c kpu = mapKPU.get(l.Klaviyo_Account_ID__c);
            if(kpu == null) continue;
            l.Klaviyo_Product_Usage__c = kpu.Id;
        }
    }
    
    //[RGaokar 11/10/2021 TP #94326] When a Lead is created with a Website but no Alexa_Rank__c, 
    //Or if the Website is changed on the Lead to a non-null value, update Alexa_Rank__c on the Lead with the value.
    //[RGaokar 11/10/2021 l.MergeLead__c != 'Will Merge' & 'Merge' is added to avoid record locking for merge lead deduplication method(LeadTriggerHandlerWithoutSharing.mergeLead)]
   public static void alexaRankUpdate(List<Lead> newLeadList, Map<Id, lead> oldMap){
        Set <Id> leadIds = new Set<Id>();
        for(Lead l:newLeadList){
            if(l.Website <> Null && l.MergeLead__c != 'Will Merge' && l.MergeLead__c != 'Merge' &&
               ((Trigger.isInsert && l.Alexa_Rank__c == null) || (Trigger.isUpdate && l.Website != oldMap.get(l.id).Website))){
                   leadIds.add(l.id);
            }
        }
        
        if(leadIds.size() > 0 && !System.isBatch() && !System.isFuture()){
            system.debug('leadIds.size()--'+ leadIds.size());
        	//Process callouts using batch of 50
        	//Database.executeBatch(new AlexaRankBatch(leadIds, 'Lead'), 50);//[RGaokar 08/10/2022 SFDC-608 Apex job holding - Shutting down batch jobs from trigger]
        } 
    }

    
    public class LeadTriggerHandlerException extends Exception {}
}
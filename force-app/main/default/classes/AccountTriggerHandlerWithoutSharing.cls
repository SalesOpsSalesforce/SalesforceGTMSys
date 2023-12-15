public class AccountTriggerHandlerWithoutSharing {
    //[RGaokar 10/5/2022 TP #89085] This method updates the "Total MRR of Managed Accounts" on the Referral Master Partner Account. 
    //When the Klaviyo or Parent accounts with Masters Partner Account is populated and with MRR > 0 and Agency Retainer Status is Active or Active No Payout, gets updated for MRR or Masters Partner Account then 
    //Update "Total MRR of Managed Accounts" (Sum of MRR of all accounts related to Master Referral Partner Account) on  Masters Partner Account.
    //When the Agency Retainer Status of Master Partner Account Changes to Pending or Archived then update the Total MRR of Managed Account for related Masters Partner Account.
    //If the Masters Partner Account gets changed then both old and new Masters Partner Accounts get updated for "Total MRR of Managed Accounts"
    private static Map<Id,Schema.RecordTypeInfo> acountRTMap = Account.sobjectType.getDescribe().getRecordTypeInfosById();//[RG 04/29/2022 Record Type Info]
    public static void updateMasterPartnerManagedMRR(List<Account> newAccList, Map<Id,Account> oldMap){
        set<id>partnerAccIds = new set<id>();
        
        for (Account a:newAccList){
            Boolean targetNewAcc = oldMap != null && a.Experts_Partner_Account__c != null && a.MRRCalc__c > 0;
            
            Boolean activeAgencyStatus = a.RP_Agency_Experts_Accounts_Status__c == 'Active' 
                                        || a.RP_Agency_Experts_Accounts_Status__c == 'Active - No Payout';
            
            Boolean nonActiveAgencyStatus = a.RP_Agency_Experts_Accounts_Status__c != 'Active' && a.RP_Agency_Experts_Accounts_Status__c != 'Active - No Payout';

            if(targetNewAcc && activeAgencyStatus && 
               (a.Experts_Partner_Account__c != oldMap.get(a.id).Experts_Partner_Account__c 
                || a.MRRCalc__c != oldMap.get(a.id).MRRCalc__c
                || (a.RP_Agency_Experts_Accounts_Status__c != oldMap.get(a.id).RP_Agency_Experts_Accounts_Status__c
                && oldMap.get(a.id).RP_Agency_Experts_Accounts_Status__c != 'Active' 
                && oldMap.get(a.id).RP_Agency_Experts_Accounts_Status__c != 'Active - No Payout'))){
                   partnerAccIds.add(a.Experts_Partner_Account__c);
             }else if(targetNewAcc && a.RP_Agency_Experts_Accounts_Status__c != oldMap.get(a.id).RP_Agency_Experts_Accounts_Status__c
               && nonActiveAgencyStatus && oldMap.get(a.id).RP_Agency_Experts_Accounts_Status__c != null){
                   partnerAccIds.add(a.Experts_Partner_Account__c);
               }
            
            if(oldMap != null && a.MRRCalc__c > 0 && oldMap.get(a.id).Experts_Partner_Account__c != null
               && a.Experts_Partner_Account__c != oldMap.get(a.id).Experts_Partner_Account__c
               && (oldMap.get(a.id).RP_Agency_Experts_Accounts_Status__c == 'Active' 
                   || oldMap.get(a.id).RP_Agency_Experts_Accounts_Status__c == 'Active - No Payout')){
                       partnerAccIds.add(oldMap.get(a.id).Experts_Partner_Account__c);
                   }            
        }
        
        if(partnerAccIds.size()>0){
            system.debug('Master Partner Accounts for Managed Accounts MRR update --'+partnerAccIds.size());
            List<account> updateAccList = new List<account>();
            Map<id, Decimal> partnerAccMRRMap = new Map<id, Decimal> ();
            List <AggregateResult> aggrResults = [Select Experts_Partner_Account__c, SUM(MRRCalc__c)TotalMRR from account 
                                                  where Experts_Partner_Account__c in : partnerAccIds
                                                  AND (RP_Agency_Experts_Accounts_Status__c = 'Active' OR RP_Agency_Experts_Accounts_Status__c = 'Active - No Payout') 
                                                  AND MRRCalc__c > 0 Group By Experts_Partner_Account__c];
            
            
            for (AggregateResult result: aggrResults){
                partnerAccMRRMap.put((id)result.get('Experts_Partner_Account__c'),(Decimal)result.get('TotalMRR'));
            }
            
            for(Id accId:partnerAccIds){
                Account a = new Account();
                if(partnerAccMRRMap.containsKey(accId)){
                    a.id = accId;
                    a.Total_MRR_of_Managed_Accounts__c = partnerAccMRRMap.get(accId); 
                }else{
                    a.id = accId;
                    a.Total_MRR_of_Managed_Accounts__c = 0;
                }
                updateAccList.add(a);   
            }
            
            
            if (updateAccList.size()>0){
                try{
                    update updateAccList;
                }catch(Exception e){
                    List <String> executionFlow = new List <String> ();
                    for(Account acc:updateAccList){
                        executionFlow.add(acc.id);
                    }
                    ExceptionHandling.performExceptionHandling(e, 'AccountTriggerHandler Class: updateMasterPartnerManagedMRR', executionFlow);
                }    
            }
        }    
        
    }
    
    // [VRajapatruni 07/21/2021] 
    // When an account is created or updated (Parent or MRR is changed), trigger should:
    // Calculate the MRR of all the accounts in the hierarchy and roll the corresponding MRR values to the parent accounts
    // The below method passes the current account and its parent accounts to the actual batch class where the actual processing happens
    public static void updateAccountRollUp(List<Account> acctList, Map<Id,Account> oldMap){
        
        Set<Id> acctIds = new Set<Id>();
        
        for(Account a : acctList){
        
            Account oldAcc = oldMap.get(a.Id);
            Boolean isUpdate = ( oldMap != null && oldMap.get(a.Id) != null ) ? true : false;
            
            // When an account is created or updated (Parent or MRR is changed) add the account to the set
            if(!isUpdate || (isUpdate && (a.ParentId <> oldAcc.ParentId || a.MRRCalc__c <> oldAcc.MRRCalc__c))){
                
                acctIds.add(a.Id);
                
                // When an updated (Parent is changed) add the parent account to the set for mrr recalculation
                if(isUpdate && a.ParentId <> oldAcc.ParentId && oldAcc.ParentId != null){
                    acctIds.add(oldAcc.ParentId);
                }
                
            } 
            
            System.debug('Account MRR Roll Up: Account ids picked for evaluation '+acctIds);       
        }
        
        if(!acctIds.isEmpty()){
            
            Set<Id> newAcctIds = new Set<Id>();
            
            //Get all the accounts in the hierarchy of the specific accounts in the set
            List<Account> acctRecs = [Select Id,
                                             ParentId,
                                             Parent.ParentId,
                                             Parent.Parent.ParentId,
                                             Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.Parent.ParentId 
                                               from account where Id in: acctIds]; 
                                               
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
            
            System.debug('new Account ids '+newAcctIds); 
               
            If(!newAcctIds.isEmpty() && !Test.isRunningTest()){    
                //Pass the account IDs to the batch class for processing
                System.debug('Passing the account IDs to the MRRRollUp batch class for processing ' +newAcctIds); 
                // [VRajapatruni 06/27/2023 SFDC-3017] Converting Batch jobs to dual mode - Batch and Queueable based on list size
                List<Account> listOfAccountForBatchOrEnque = [Select Id, Total_MRR_of_Child_Accounts__c, MRRCalc__c From Account Where Id In: newAcctIds order by ParentId];
                if(!listOfAccountForBatchOrEnque.isEmpty() && listOfAccountForBatchOrEnque.size() < 10){
                    System.enqueueJob(new AccountMRRRollUpUpdateQueueable(newAcctIds, listOfAccountForBatchOrEnque));
                }else if(!listOfAccountForBatchOrEnque.isEmpty() && listOfAccountForBatchOrEnque.size() >= 10){
                    Database.executeBatch(new AccountMRRRollUpUpdateBatch(newAcctIds), 20);
                }
            }                                                   
        }
    }
    
     
    // [VRajapatruni 04/07/2022 TP #86485] Account level rollups (Activity) ACCOUNT object
    // When an account is created or updated (Parent or ActivityDate is changed), trigger should:
    // Calculate the Max(Activity Dates) of all the accounts in the hierarchy and roll the corresponding values to the parent accounts
    // The below method passes the current account and its parent accounts to the actual batch class where the actual processing happens
    public static void updateAccountMaxActivity(List<Account> acctList, Map<Id,Account> oldMap){
        
        Set<Id> acctIds = new Set<Id>();
        
        for(Account a : acctList){
            
            Account oldAcc = oldMap.get(a.Id);
            Boolean isUpdate = ( oldMap != null && oldMap.get(a.Id) != null ) ? true : false;
            
            // When an account is created or updated (Parent or Activity Date is changed) add the account to the set
            if(!isUpdate 
                || (isUpdate && (a.ParentId <> oldAcc.ParentId 
                    || a.Calculated_Last_Activity_Date__c <> oldAcc.Calculated_Last_Activity_Date__c 
                    || a.LastActivityDate <> oldAcc.LastActivityDate 
                    || a.Last_Activity_Date_Custom__c <> oldAcc.Last_Activity_Date_Custom__c))){
                
                    acctIds.add(a.Id);
                    
                    if(isUpdate && a.ParentId <> oldAcc.ParentId && oldAcc.ParentId != null){
                        acctIds.add(oldAcc.ParentId);
                    }
            }     
        }
        
        if(!acctIds.isEmpty()){
            
            System.debug('Inside if loop');
            Set<Id> newAcctIds = new Set<Id>();
            
            //Get all the accounts in the hierarchy of the specific accounts in the set
            List<Account> acctRecs = [Select Id,
                                             ParentId,
                                             Parent.ParentId,
                                             Parent.Parent.ParentId,
                                             Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.Parent.ParentId 
                                               from account where Id in: acctIds]; 
            
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
            
            If(!newAcctIds.isEmpty() && !Test.isRunningTest()){   
                //Pass the account IDs to the batch class for processing
                Database.executeBatch(new AccountMaxActivityRollUpBatch(newAcctIds), 10);
            } 
                                                                  
        }
    }
    
    // [VRajapatruni 09/09/2021 TP #84782] 
    // In efforts to merge Klaviyo Account Sync trigger to Account trigger, moved the klaviyoAccount sync functionality to Account Trigger handler 
    // and this specific method is called from Account trigger in after insert and after update scenarios
    public static void KlaviyoAccountSync(List<Account> acctList, Map<Id,Account> oldMap){
    
    try{
        // Gather Set of accounts with changes to these fields
        Map <String, String> disabledTriggers = KlaviyoAccountSync.getMetadataTypeValuesByLabel('TriggerDisablementSwitch__mdt','DisableTriggers');
        if (!Boolean.valueOf(disabledTriggers.get('KlaviyoAccountSync')) && !KlaviyoAccountSync.alreadyProcessed){
            // Grab fields to watch for changes from K4K_Account_Field__mdt
            List<String> fields = new List<String> ();
            fields.add('SUPPORT_Account_Manager__c'); // Lookup(User) field for CSM
            fields.add('Onboarding_Specialist__c'); // Lookup(User) field for OBS
            fields.add('RP_Referral_Partner_Account__c'); // Lookup(Account) field for referal partner account
            fields.add('OwnerId'); // Lookup(User) field for AE
            // Gather Set of accounts with changes to these fields
            Set<String> objectFields = Schema.SObjectType.Account.fields.getMap().keySet();
            Set<Account> accountsToSync = new Set<Account>();
            for (Account account: acctList) { // Handle bulk inserts
                for (String field: fields) { // Check each watched field
                    if ((!Trigger.isUpdate || oldMap.get(account.Id).get(field) != account.get(field)) &&
                        (objectFields.contains(field.toLowerCase()) && !accountsToSync.contains(account) && account.get(field) != null)){
                            system.debug(field + ' changed');
                            accountsToSync.add(account); // change recorded for this field, add to list
                        }
                }
            }
            if (accountsToSync.size()>0){
                // Queue new CSM list for processing
                KlaviyoAccountSync klAccountSync = new KlaviyoAccountSync(accountsToSync);
                //[06/30/2021 vr] Added the if filter while 34 and 35 are already existing lines of code
                if(KlaviyoAccountSync.isRunFromTAPBatch <> true){
                    ID jobID = System.enqueueJob(klAccountSync);
                    System.debug('Queued new job with jobID' + jobID);
                }
            }
            KlaviyoAccountSync.alreadyProcessed = true;
        } else if (Boolean.valueOf(disabledTriggers.get('KlaviyoAccountSync'))) {
            // In case trigger is disabled by trigger-disable MDT, set "alreadyProcessed = true" so tests can still pass
            KlaviyoAccountSync.alreadyProcessed = true;
        }
    } catch (Exception ex) {
        System.debug('Exception: "' + ex.getMessage() +
                     '" of type "' + ex.getTypeName() +
                     '" caused by "' + ex.getCause() +
                     '" on line number ' + ex.getLineNumber() + '\n' +
                     'Stack Trace: ' + ex.getStackTraceString());
        }
    }

    // [VRajapatruni 11/21/2021 TP #91911] Account Trigger Handler Class Optimization
    // [VRajapatruni 02/03/2022 TP #89144] Associated Accounts Calculation Update
    // Associated Accounts is a field that calculates how many prospect Accounts a sales rep has in their name. 
    // The goal is to keep them under a specific limit of reasonable accounts to work (enforced via a decision point in the Account Claim flow). 
    // The request here is to alter how we calculate Associated Accounts when Parent Accounts are in play, as we may accidentally over-count how many prospects a rep is working due to the nature of how some Accounts are structured with Parent/Child relationships.
    // Previously, this is how we calculate Associated Accounts per Sales Rep. 
    // We count an Account if: the current sales rep is the owner and record type = 'Klaviyo Account', FINANCE_Payment_Method = ' Stripe', MRR = $0, and RU_of_Open_Opportunities__c = 0.
    // The above logic should stay true given that account does not have a Parent Account.
    // However, if the Parent Account field on the Account in question is not null, only one Child Account per Account Hierarchy should be counted towards the Associated Accounts number AND should only be counted if there are no paying Child Accounts or open opps in that Account hierarchy.

 
    public static void updateAssociatedAccounts(List<Account> accRecs, Map<Id,Account> oldMap){
        
        System.debug('AA: Entered Associated Accounts');
        Set<Id> userIds = new Set<id>();
        //[RGaokar 07/21/2023 SFDC-787 Too many SOQL queries Resolution]
        Set<id>newAccTopParentIDSet = new Set<id>();
        Set<id>oldAccTopParentIDSet = new Set<id>();
        
 
        // Gathering all the users that are involved in the update i.e new owner and/or old owner of account into the userIds set. 
        if(Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate){     
             
            for(Account a : accRecs){            
                
                    Account oldAcc = oldMap.get(a.Id);
                     
                    if(Trigger.isInsert || Trigger.isUnDelete || 
                        (Trigger.isUpdate && 
                            (a.OwnerId <> oldAcc.OwnerId || a.RecordTypeId <> oldAcc.RecordTypeId || a.FINANCE_Payment_Method__c <> oldAcc.FINANCE_Payment_Method__c || a.MRRCalc__c <> oldAcc.MRRCalc__c || a.RU_of_Open_Opportunities__c <> oldAcc.RU_of_Open_Opportunities__c || a.ParentID <> oldAcc.ParentID || a.Ultimate_Parent__c <> oldacc.Ultimate_Parent__c)
                        )
                    ){
                        // [SFDC-597 vrajapatruni 08/30/2022] Allow charlotte guest user to run AA. Removed && a.OwnerId <> system.label.Charlotte_Guest_Id from below 
                        if(a.OwnerId <> system.label.Salesforce_API_User_Id && a.OwnerId <> system.label.Special_Ops_Placeholder_Id && a.OwnerId <> system.label.Core_Placeholder_Id && a.OwnerId <> system.label.Klaviyo_Partners_Id
                            && a.OwnerId <> system.label.Partners_Site_Guest_User_Id && a.OwnerId <> system.label.Automated_Process_Id && a.OwnerId <> system.label.Platform_Integration_User_Id
                            && a.OwnerId <> system.label.Klaviyo_Partners_Site_Guest_User_Id && a.OwnerId <> system.label.Catherine_Catherine_Curran_Id && a.OwnerId <> system.label.Klaviyo_Site_Guest_User_Id){         
                      
                            userIds.add(a.OwnerId); 
                            newAccTopParentIDSet.add(a.Ultimate_Parent__c);
                        }
                        // [SFDC-597 vrajapatruni 08/30/2022] Allow charlotte guest user to run AA. Removed && oldAcc.OwnerId <> system.label.Charlotte_Guest_Id from below
                        if(Trigger.isUpdate && oldAcc.OwnerId <> system.label.Salesforce_API_User_Id && oldAcc.OwnerId <> system.label.Special_Ops_Placeholder_Id  && oldAcc.OwnerId <> system.label.Core_Placeholder_Id && oldAcc.OwnerId <> system.label.Klaviyo_Partners_Id
                            && oldAcc.OwnerId <> system.label.Partners_Site_Guest_User_Id    && oldAcc.OwnerId <> system.label.Automated_Process_Id    && oldAcc.OwnerId <> system.label.Platform_Integration_User_Id
                            && oldAcc.OwnerId <> system.label.Klaviyo_Partners_Site_Guest_User_Id  && oldAcc.OwnerId <> system.label.Catherine_Catherine_Curran_Id && oldAcc.OwnerId <> system.label.Klaviyo_Site_Guest_User_Id){
                            
                            if(a.OwnerId <> oldAcc.OwnerId){
                                userIds.add(oldAcc.OwnerId);
                            }
                            
                            if(a.ParentID <> oldAcc.ParentID){
                                userIds.add(a.OwnerId);
                                if(oldAcc.ParentID <> null){
                                    oldAccTopParentIDSet.add(oldAcc.Ultimate_Parent__c);
                                }
                            }
                        }
                     }
            } 
            
            //[RGaokar 07/21/2023 SFDC-787 Too many SOQL queries Resolution]
            if(!newAccTopParentIDSet.isEmpty()){
              List<Account>newAccountTopParents = [Select OwnerId from Account where id =: newAccTopParentIDSet];
                for(account a:newAccountTopParents){
                    userIds.add(a.OwnerId);
                }
            }
            
            if(!oldAccTopParentIDSet.isEmpty()){
              List<Account>oldAccountTopParents = [Select OwnerId from Account where id =: oldAccTopParentIDSet];
                for(account a:oldAccountTopParents){
                    userIds.add(a.OwnerId);
                }
            }
        } 
        
        if(Trigger.isDelete || Trigger.isUndelete){
             
             List<Id> DeletedAccountsIds = new List<Id>();
             Set<Id> acctIdsParent = new Set<Id>();
             for(Account a : accRecs){
                 acctIdsParent.add(a.Id);
                 // [SFDC-597 vrajapatruni 08/30/2022] Allow charlotte guest user to run AA. Removed && a.OwnerId <> system.label.Charlotte_Guest_Id from below
                 if(a.OwnerId <> system.label.Salesforce_API_User_Id && a.OwnerId <> system.label.Special_Ops_Placeholder_Id && a.OwnerId <> system.label.Core_Placeholder_Id && a.OwnerId <> system.label.Klaviyo_Partners_Id
                     && a.OwnerId <> system.label.Partners_Site_Guest_User_Id && a.OwnerId <> system.label.Automated_Process_Id && a.OwnerId <> system.label.Platform_Integration_User_Id
                     && a.OwnerId <> system.label.Klaviyo_Partners_Site_Guest_User_Id && a.OwnerId <> system.label.Catherine_Catherine_Curran_Id && a.OwnerId <> system.label.Klaviyo_Site_Guest_User_Id)
                 { 
                     userIds.add(a.OwnerId);
                     DeletedAccountsIds.add(String.valueOf(a.Id).substring(0, 15));
                 }
             }
              
             List<Account> ChildAccountsofDeletedParent = new List<Account>();
             if(Trigger.isDelete)
                 ChildAccountsofDeletedParent = [select OwnerId, (select id, OwnerId from ChildAccounts) from account where ParentId in: acctIdsParent];
             if(Trigger.isUnDelete){
                 ChildAccountsofDeletedParent = [select OwnerId,(select id, OwnerId from ChildAccounts) from account where ParentId__c =: acctIdsParent];
             }  
                        
             for(Account ac: ChildAccountsofDeletedParent){
                 // [SFDC-597 vrajapatruni 08/30/2022] Allow charlotte guest user to run AA. Removed && ac.OwnerId <> system.label.Charlotte_Guest_Id from below
                 if(ac.OwnerId <> system.label.Salesforce_API_User_Id && ac.OwnerId <> system.label.Special_Ops_Placeholder_Id && ac.OwnerId <> system.label.Core_Placeholder_Id && ac.OwnerId <> system.label.Klaviyo_Partners_Id
                     && ac.OwnerId <> system.label.Partners_Site_Guest_User_Id && ac.OwnerId <> system.label.Automated_Process_Id && ac.OwnerId <> system.label.Platform_Integration_User_Id
                     && ac.OwnerId <> system.label.Klaviyo_Partners_Site_Guest_User_Id && ac.OwnerId <> system.label.Catherine_Catherine_Curran_Id && ac.OwnerId <> system.label.Klaviyo_Site_Guest_User_Id){
                     userIds.add(ac.OwnerId);
                     
                 }    
                 if(ac.ChildAccounts != null){
                     for(Account cAcc: ac.ChildAccounts){
                          // [SFDC-597 vrajapatruni 08/30/2022] Allow charlotte guest user to run AA. Removed && cAcc.OwnerId <> system.label.Charlotte_Guest_Id from below
                          if(cAcc.OwnerId <> system.label.Salesforce_API_User_Id && cAcc.OwnerId <> system.label.Special_Ops_Placeholder_Id && cAcc.OwnerId <> system.label.Core_Placeholder_Id && cAcc.OwnerId <> system.label.Klaviyo_Partners_Id
                     && cAcc.OwnerId <> system.label.Partners_Site_Guest_User_Id && cAcc.OwnerId <> system.label.Automated_Process_Id && cAcc.OwnerId <> system.label.Platform_Integration_User_Id
                     && cAcc.OwnerId <> system.label.Klaviyo_Partners_Site_Guest_User_Id && cAcc.OwnerId <> system.label.Catherine_Catherine_Curran_Id && cAcc.OwnerId <> system.label.Klaviyo_Site_Guest_User_Id){     
                             userIds.add(cAcc.OwnerId);
                          }   
                     }
                 }    
             }
        }
        
        // By this point, we have gathered all the users that are involved in the update i.e new owner and old owner of account into the userIds set. 
        if(!userIds.isEmpty() && !System.isBatch() && !System.isFuture() && !Test.isRunningTest()){
            System.debug('User Ids are ' +userIds);
            // [VRajapatruni 06/27/2023 SFDC-3017] Converting Batch jobs to dual mode - Batch and Queueable based on list size
            List<User> listOfUsersForBatchOrEnque = [Select Id, Associated_Accounts__c, Name From User Where Id in: userIds AND isActive = true AND LastName != 'System' AND FirstName != 'Automated' AND (NOT Name  LIKE '%Site Guest%') AND (NOT Name LIKE '%Platform Integration User%') AND (NOT Name  LIKE '%Catherine Catherine Curran%') AND (NOT Name  LIKE '%Placeholder%') AND (NOT Name  LIKE '%Salesforce API%') AND (NOT Name  LIKE '%Klaviyo Partners%') ];
            if(!listOfUsersForBatchOrEnque.isEmpty() && listOfUsersForBatchOrEnque.size() < 10){
                System.enqueueJob(new updateAssociatedAccountsQueueable(userIds, listOfUsersForBatchOrEnque));
            }else if(!listOfUsersForBatchOrEnque.isEmpty() && listOfUsersForBatchOrEnque.size() >= 10){
                Database.executeBatch(new updateAssociatedAccountsBatch(userIds), 10);
            }
        }
    }
    
    // [VRajapatruni 11/21/2021 TP #91911]
    // When Target Account Status is changed to "DQ - Do not Contact", find all related leads (via Account__c field on Lead) that are not Converted and update the following Lead fields:
    // Lead Status = Disqualified,
    // Disqualification Reason = "Said No - Do Not Contact",
    // HasOptedOutOfEmail = TRUE
    public static void UpdateTargetAccountLeadStatus(List<Account> accRecs, Map<Id,Account> oldMap){    
    
        if(Trigger.isAfter){
            if(Trigger.isUpdate){
            
                Set<Id> acctIds = new Set<Id>();
                
                for(Account a : accRecs){
                    if(a.Target_Account_Status__c <> oldMap.get(a.Id).Target_Account_Status__c && a.Target_Account_Status__c == 'DQ - Do not Contact') {
                                        
                        if(Trigger.isUpdate)
                            acctIds.add(a.Id);     
                    }
                }
                
                if(!System.isBatch() && !System.isFuture()) {
                    List<Lead> leadList = [Select Id, OwnerId, Account__c, isConverted from Lead where Account__c in: acctIds and isConverted = false];
                    Set<Id> leadIds =new Set<Id>();
                    
                    for(Lead l : leadList){
                        if(l.isConverted == false)
                        {
                            leadIds.add(l.Id);
                        }
                    }
                    
                    if(!leadIds.isEmpty() && !System.isBatch() && !Test.isRunningTest())
                        Database.executeBatch(new TargetAccountDQBatch(leadIds, acctIds), 20);
                } 
            }
        }
    }
    
    // [VRajapatruni 11/21/2021 TP #91911]
    // "If an Account is marked Transfer_to_Spec_Ops_Placeholder__c  = True:
    // - Change the Account Owner to ""Special Ops Placeholder"" user
    // - Change all unconverted Leads, where the related Account__c is the Account that started process, so the Lead Owner is ""Special Ops Placeholder"" user
    // - Mark Transfer_to_Spec_Ops_Placeholder__c = False
    // If an Account is marked Transfer_to_Core_Placeholder__c = True:
    // - Change the Account Owner to ""Core Placeholder"" user
    // - Change all unconverted Leads where the related Account__c is the Account that started process so the Lead Owner is ""Core Placeholder"" user
    // - Mark Transfer_to_Core_Placeholder__c = False
    public static void UpdateAccountTransferToPlaceholder(List<Account> accRecs, Map<Id,Account> oldMap){    
    
        Set<Id> acctIds_Ops = new Set<Id>();
        Set<Id> acctIds_Core = new Set<Id>();
        
        for(Account a : accRecs){
        
            // [VRajapatruni 02/03/2022 TP #89144] Associated Accounts Calculation Update
            // Need to prepopulate the parentId__C field which is being used in AA undelete scenario
            if(a.ParentId <> null && String.isBlank(a.ParentId__c)){
                a.ParentId__c = a.ParentId;
            }
            else if(a.ParentId == null){
                a.ParentId__c = null;
            }
            
            if(a.Transfer_to_Spec_Ops_Placeholder__c == true && (Trigger.isInsert || Trigger.isUpdate && a.Transfer_to_Spec_Ops_Placeholder__c != oldMap.get(a.Id).Transfer_to_Spec_Ops_Placeholder__c)) {
                 
                 a.Transfer_to_Spec_Ops_Placeholder__c = false;
                                  
                 if(System.Label.Special_Ops_Placeholder_Id <> null)     
                    a.ownerId = System.Label.Special_Ops_Placeholder_Id;
                 
                 if(Trigger.isUpdate)
                     acctIds_Ops.add(a.Id);     
            }
            if(a.Transfer_to_Core_Placeholder__c == true && (Trigger.isINsert || Trigger.isUpdate && a.Transfer_to_Core_Placeholder__c != oldMap.get(a.Id).Transfer_to_Core_Placeholder__c)) {
                 
                 a.Transfer_to_Core_Placeholder__c = false;
                                  
                 if(System.Label.Core_Placeholder_Id <> null)     
                    a.ownerId = System.Label.Core_Placeholder_Id;
                 
                 if(Trigger.isUpdate)
                     acctIds_Core.add(a.Id);     
            }
        }
        
        if(!System.isBatch() && !System.isFuture() && (!acctIds_Ops.isEmpty() || !acctIds_Core.isEmpty() || Test.isRunningTest())) {
            List<Lead> leadList = [Select Id, OwnerId, Account__c, isConverted from Lead where (Account__c in: acctIds_Ops OR Account__c in: acctIds_Core) and isConverted = false];
            Set<Id> leadIds =new Set<Id>();
            
            for(Lead l : leadList){
                if(l.isConverted == false)
                {
                    leadIds.add(l.Id);
                }
            }
            
            if(!leadIds.isEmpty() && !Test.isRunningTest())
                Database.executeBatch(new AccountTransferToPlaceholderBatch(leadIds, acctIds_Ops, acctIds_Core), 20);
        } 
    }
    
    //[RGaokar 09/14/2022] SFDC-207 Automation Cleanup - Moving calcRegionForCountryCode & calcRegionForCountry in Account before save flow
    // [VRajapatruni 11/21/2021 TP #91911]
    // When an Account is created, if it has a Country Code (MARKETING_SignupFormFieacc_7__c),
    // use it to find the matching Region in Country_and_Region_Mapping__mdt.
    // Called on Before Insert
    /*public static void calcRegionForCountryCode(List<Account> triggerNew, Map<Id,Account> triggerOldmap) {

        System.debug('Account being inserted');
        // If this functionality is disabled, don't do it
        if (TriggerDisablementSwitchHelper.isDisabled('Account_Country_Code_And_Region_Mapping')) {
            return;
        }

        // Get a list of Country Codes to look up
        Set<String> setCodes = new Set<String>();
        for (Account acc : triggerNew) {
           if (acc.Country__c != null) 
               setCodes.add(acc.Country__c);
        }
        System.debug('List of codes' +setCodes);
        if (!setCodes.isEmpty()) {
            // Create a map of Regions, indexed by Country Code
            List<Country_and_Region_Mapping__mdt> lstMappings =
                [select id, Region__c, Label, Country_Code__c
                from   Country_and_Region_Mapping__mdt
                where  Label in :setCodes];
            System.debug('Mappings '+lstMappings);
            Map<String, String> mapRegionsByCountryCode = new Map<String, String>();
            for (Country_and_Region_Mapping__mdt mapping : lstMappings) {
                mapRegionsByCountryCode.put(mapping.Label.toLowerCase(), mapping.Region__c);
            }
            System.debug('Map '+mapRegionsByCountryCode);
            // Use the map to assign the correct Region to each Lead
            for (Account acc : triggerNew) {
                if (acc.Country__c != null) {
                    String countryCode = acc.Country__c.toLowerCase();
                    if (mapRegionsByCountryCode.containsKey(countryCode)) {
                    
                        String region = mapRegionsByCountryCode.get(countryCode);
                        acc.SALES_Geographical_Location__c = region;
                        
                    }
                }
            }
        }
    }

    // [VRajapatruni 11/21/2021 TP #91911]
    // When an Account is updated, if it has a Country (Country__c) and its
    // FLOW_Flip_Channel__c has changed and is not null, use the Country to
    // to find the matching Region in Country_and_Region_Mapping__mdt.
    // Called on Before Update
    public static void calcRegionForCountry(List<Account> triggerNew, Map<Id,Account> triggerOldmap) {
        // Get a list of Country to look up
        Set<String> setCountries = new Set<String>();
        for (Account acc : triggerNew) {
            Account accOld = triggerOldmap.get(acc.Id);
            // If the Account has a Country and its Flow Flip Channel is non-null and has changed
            if (acc.Country__c != null &&
                   acc.Country__c != accOld.Country__c) {
                setCountries.add(acc.Country__c);
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
            System.debug('Map ' +mapRegionsByCountry);
            // Use the map to assign the correct Region to each Lead
            for (Account acc : triggerNew) {
                Account accOld = triggerOldmap.get(acc.Id);
                if (acc.Country__c != null  &&
                   acc.Country__c != accOld.Country__c) {
                    String country = acc.Country__c.toLowerCase();
                    if (mapRegionsByCountry.containsKey(country)) {
                        String region = mapRegionsByCountry.get(country);
                        acc.SALES_Geographical_Location__c = region;
                    }
                }
            }
        }
    }*/
    
    //[RGaokar 04/29/2022 TP #119625] Account Data Enrichment using SimilarWeb
    // When Klaviyo account is created with website populated perform HTTP callout to SimilarWeb 'Lead Enrichment' endpoint to retrieve the information for account enrichment
    public static void getSimilarWebMetrics(List<Account> newAccList){
        List <Account> accList = new List <Account>();
        Set<Id> accIds = new Set<Id>();
        for(Account a:newAccList){
            if(a.Clean_Website__c <> Null && acountRTMap.get(a.recordtypeid).developername == 'Klaviyo_Account'){
                accList.add(a);
                accIds.add(a.id);
            }
        }
        
        system.debug('similarWebaccList size--'+ accList.size());
        if(accList.size() > 0){
            //Passing single record to queueable to avoid filling batch flex queue
            //Passing multiple records to batch of size 10 as Similarweb supports 10 Rest API requests/second
            if(accList.size() == 1){
                system.enqueueJob(new SimilarWebMetricsProcessor(accList, true));
            }else{
                string query = 'Select id, Clean_Website__c from Account where id in ';
                SimilarWebBatch swBatch = new SimilarWebBatch(query, accIds, true);
                System.scheduleBatch(swBatch, 'AccountTriggerSWBatch'+System.now(), 20, 1);//Scheduling after 20 mins to avoid record locking issues,[RGaokar 08/24/2022 SFDC-697 Changing batch size from 10 to 1]
            }
        } 
    }
    
    //[RGaokar 09/06/2022 SFDC-515] Charm Enhancement- Logic extended for website update, when website is updated, update the Charm metrics
    //[RGaokar 04/27/2022 TP #119370] Account Data Enrichment using Charm io api
    // When Klaviyo account is created with website populated perform HTTP callout to Charm io 'Enrichment' endpoint to retrieve the information for account enrichment
    public static void charmDataEnrichment(List<Account> newAccList, Map <id, Account> oldMap){
        List<Account> accList = new List<Account>();
        Set<Id> accIds = new Set<Id>();
        for(Account a:newAccList){
            if(a.Clean_Website__c <> Null && acountRTMap.get(a.recordtypeid).developername == 'Klaviyo_Account'
               && (Trigger.isInsert || (Trigger.isUpdate && a.Website != oldMap.get(a.id).Website))){
                   accList.add(a);
                   accIds.add(a.id);
               }
        }
        system.debug('charmDataAccList.size()--'+ accList.size());
        if(accList.size() > 0){
            //Passing single record to queueable to avoid filling batch flex queue
            //Passing multiple records to batch of size 100. Charm io api request supports 250 websites/request.
            if(accList.size() == 1){
                system.enqueueJob(new CharmDataEnrichmentProcessor(accList));
            }else{
                string query = 'Select id, Clean_Website__c from Account where id in ';
                CharmDataEnrichmentBatch charmBatch = new CharmDataEnrichmentBatch(query, accIds);
                System.scheduleBatch(charmBatch, 'AccountTriggerCharmBatch'+System.now(), 10, 100);//Scheduling after 10 mins to avoid record locking issues
            }
        } 
    }
    
    //[RGaokar 08/18/2022 SFDC-524 Charm Revenue Rollup - Logic to handle parent change & delete/undelete]
    //If account's charm revenue or parent changes or account in hierarchy is deleted / undeleted
    //Then set the Id on parent account that needs re-calculation of Charm Revenue Roll Up Update
    //(Not checking Charm revenue is not null condition for parent change and delete/undelete as logic also needs to calculate total children irrespective of null charm revenue on account)
    public static void charmRollupUpdate(List<Account> newAccList, Map<Id, Account> oldAccMap){
        List<Account>updateCharmRollupAccList = new List<Account>();
        if (Trigger.isInsert || Trigger.isUndelete){
            for(Account a:newAccList){
                if(a.ParentId != null){
                    updateCharmRollupAccList.add(new Account(Id = a.ParentId, ParentId_Charm_Revenue_Roll_Up_Update__c = a.ParentId));
                }
            }
        }else if(Trigger.isUpdate){
            map<id, account> accountparentMap = new map<id, account>([Select id, parent.ParentId_Charm_Revenue_Roll_Up_Update__c from Account where id in:oldAccMap.keyset()]);
            for(Account a:newAccList){
                Boolean parentRollupUpdate = accountparentMap.get(a.id).parent.ParentId_Charm_Revenue_Roll_Up_Update__c == null;//Check for parent id already populated during insert to avoid record locking
                if(a.ParentId != null && parentRollupUpdate &&
                   (a.Charm_Revenue__c != oldAccMap.get(a.Id).Charm_Revenue__c || a.ParentId != oldAccMap.get(a.Id).ParentId)){
                       updateCharmRollupAccList.add(new Account(Id = a.ParentId, ParentId_Charm_Revenue_Roll_Up_Update__c = a.ParentId));  
                   }
                if(a.ParentId != oldAccMap.get(a.Id).ParentId && oldAccMap.get(a.Id).ParentId != null){
                    updateCharmRollupAccList.add(new Account(Id = oldAccMap.get(a.Id).ParentId, ParentId_Charm_Revenue_Roll_Up_Update__c = oldAccMap.get(a.Id).ParentId));
                }
            }
        }else if (Trigger.isDelete){
            for(Account a:oldAccMap.values()){
                if(a.ParentId != null){
                    updateCharmRollupAccList.add(new Account(Id = a.ParentId, ParentId_Charm_Revenue_Roll_Up_Update__c = a.ParentId));
                }
            }  
        }
        
        system.debug('updateCharmRollupAccList size--'+updateCharmRollupAccList.size());
        
        if(!updateCharmRollupAccList.isEmpty()){
            try{
                update updateCharmRollupAccList;
            }catch(Exception e){
                System.debug('Exception: "' + e.getMessage() +'" of type "' + e.getTypeName() +'" caused by "' + e.getCause() +
                             '" on line number ' + e.getLineNumber() + '\n' +'Stack Trace: ' + e.getStackTraceString());
            }
        }
    } 

}
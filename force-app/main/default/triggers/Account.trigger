/*
** Trigger:  Account
** SObject:  Account
** Created by OpFocus 
** Description: Trigger for Account.  Details in AccountTriggerHandler
**              
*/
trigger Account on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    
    new AccountTriggerHandler().run();
    
    //[RGaokar 09/14/2022] SFDC-207 Automation Cleanup - Moving calcRegionForCountryCode & calcRegionForCountry in Account before save flow
    /* [VRajapatruni 01/11/2021] AccountTransferToPlaceholder for Transfer To Placeholder - Transfer Account and its Uncoverted Leads to corresponding placeholder */
    /* [VRajapatruni 05/21/2021] AccountRegionForCountryUpdate for updating the Geo Location based on the country */
    /* [VRajapatruni 12/02/2021 TP #91911] Moved the methods UpdateAccountTransferToPlaceholder, calcRegionForCountryCode, KlaviyoAccountSync, updateAssociatedAccounts, UpdateTargetAccountLeadStatus and updateAccountRollUp to AccountTriggerHandlerWithoutSharing  */
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            AccountTriggerHandlerWithoutSharing.UpdateAccountTransferToPlaceholder(Trigger.new, new Map<Id,Account>());
            //AccountTriggerHandlerWithoutSharing.calcRegionForCountryCode(Trigger.new, Trigger.oldMap); 
        }    
        if(Trigger.isUpdate){
            AccountTriggerHandlerWithoutSharing.UpdateAccountTransferToPlaceholder(Trigger.new, Trigger.oldMap);
            //AccountTriggerHandlerWithoutSharing.calcRegionForCountry(Trigger.new, Trigger.oldMap); 
        }
        // [VRajapatruni 02/03/2022 TP #89144] Associated Accounts Calculation Update - Need to be in before scenario   
        if(Trigger.isDelete){   
            AccountTriggerHandlerWithoutSharing.updateAssociatedAccounts(Trigger.old, new Map<Id,Account>());       
        }
    }
    
    /* [VRajapatruni 12/15/2020] AssociatedAccountsCalculation for calculating the number of Associated Accounts for an user */
    /* [VRajapatruni 09/09/2021] KlaviyoAccountSync for Account and KlaviyoAccountSync merger */
    /* [RGaokar 10/5/2022 TP #89085] updateMasterPartnerManagedMRR:updates the "Total MRR of Managed Accounts" on the Referral Master Partner Account.*/
    /* [VRajapatruni 12/02/2021 TP #91911] Moved the methods UpdateAccountTransferToPlaceholder, calcRegionForCountryCode, KlaviyoAccountSync, updateAssociatedAccounts, UpdateTargetAccountLeadStatus and updateAccountRollUp to AccountTriggerHandlerWithoutSharing */
    //[RGaokar 04/29/2022 TP #119625] Account Data Enrichment using SimilarWeb
    //[RGaokar 08/18/2022 SFDC-524] Charm Revenue Rollup
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            AccountTriggerHandlerWithoutSharing.KlaviyoAccountSync(Trigger.new, new Map<Id,Account>());
            AccountTriggerHandlerWithoutSharing.updateAssociatedAccounts(Trigger.new, new Map<Id,Account>());
            AccountTriggerHandlerWithoutSharing.getSimilarWebMetrics(Trigger.new);//[RGaokar 04/29/2022 TP #119625] Account Data Enrichment using SimilarWeb
            AccountTriggerHandlerWithoutSharing.charmDataEnrichment(Trigger.new, null);//[RGaokar 04/27/2022 TP #119370] Account Data Enrichment using Charm io
            AccountTriggerHandlerWithoutSharing.charmRollupUpdate(Trigger.new, null);//[RGaokar 08/18/2022 SFDC-524] Charm Revenue Rollup
        }
        if(Trigger.isUpdate){
            AccountTriggerHandlerWithoutSharing.KlaviyoAccountSync(Trigger.new, Trigger.oldMap);
            AccountTriggerHandlerWithoutSharing.updateAssociatedAccounts(Trigger.new, Trigger.oldMap);
            AccountTriggerHandlerWithoutSharing.UpdateTargetAccountLeadStatus(Trigger.new, Trigger.oldMap); // [05/20/2021]
            AccountTriggerHandlerWithoutSharing.updateMasterPartnerManagedMRR(Trigger.new, Trigger.oldMap);
            AccountTriggerHandlerWithoutSharing.charmRollupUpdate(Trigger.new, Trigger.oldMap);//[RGaokar 08/18/2022 SFDC-524] Charm Revenue Rollup
            AccountTriggerHandlerWithoutSharing.charmDataEnrichment(Trigger.new, Trigger.oldMap);//[RGaokar 09/06/2022 SFDC-515] Charm Enhancement
        }
        // [VRajapatruni 02/03/2022 TP #89144] Associated Accounts Calculation Update - Need to be in before scenario
        // if(Trigger.isDelete)
        //    AccountTriggerHandlerWithoutSharing.updateAssociatedAccounts(Trigger.old, new Map<Id,Account>());
        
        if(Trigger.isDelete){
            AccountTriggerHandlerWithoutSharing.charmRollupUpdate(null, Trigger.oldMap);//[RGaokar 08/18/2022 SFDC-524] Charm Revenue Rollup
        }
        if(Trigger.isUnDelete){
            AccountTriggerHandlerWithoutSharing.updateAssociatedAccounts(Trigger.new, new Map<Id,Account>());
            AccountTriggerHandlerWithoutSharing.charmRollupUpdate(Trigger.new, null);//[RGaokar 08/18/2022 SFDC-524] Charm Revenue Rollup
        }
    }
 
    /* [VRajapatruni 07/14/2021] updateAccountRollUp for Account Roll Up for Parent-Child (MRR) */ 
    /* [VRajapatruni 09/09/2021] updateAccountMaxActivity for Account Roll Up for Parent-Child (Calculated Last Activity Date) */
    /* [VRajapatruni 12/02/2021 TP #91911] Moved the methods UpdateAccountTransferToPlaceholder, calcRegionForCountryCode, KlaviyoAccountSync, updateAssociatedAccounts, UpdateTargetAccountLeadStatus and updateAccountRollUp to AccountTriggerHandlerWithoutSharing */
    if(Trigger.isAfter){
        if(System.isBatch() == false){ 
            if(Trigger.isInsert){
                AccountTriggerHandlerWithoutSharing.updateAccountRollUp(Trigger.new, new Map<Id,Account>());
                //AccountTriggerHandler.updateAccountMaxActivity(Trigger.new, new Map<Id,Account>());
            }
            if(Trigger.isUpdate){
                AccountTriggerHandlerWithoutSharing.updateAccountRollUp(Trigger.new, Trigger.oldMap);
                //AccountTriggerHandler.updateAccountMaxActivity(Trigger.new, Trigger.oldMap);
            }
            if(Trigger.isDelete){
                AccountTriggerHandlerWithoutSharing.updateAccountRollUp(Trigger.old, new Map<Id,Account>());
                //AccountTriggerHandler.updateAccountMaxActivity(Trigger.old, new Map<Id,Account>());
            }
            if(Trigger.isUndelete){
                AccountTriggerHandlerWithoutSharing.updateAccountRollUp(Trigger.new, new Map<Id,Account>());
                //AccountTriggerHandler.updateAccountMaxActivity(Trigger.new, new Map<Id,Account>());
            }
        }
    }        
  
}
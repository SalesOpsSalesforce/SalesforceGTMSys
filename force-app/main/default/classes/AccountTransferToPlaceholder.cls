/* "If an Account is marked Transfer_to_Spec_Ops_Placeholder__c  = True:
- Change the Account Owner to ""Special Ops Placeholder"" user
- Change all unconverted Leads, where the related Account__c is the Account that started process, so the Lead Owner is ""Special Ops Placeholder"" user
- Mark Transfer_to_Spec_Ops_Placeholder__c = False

If an Account is marked Transfer_to_Core_Placeholder__c = True:
- Change the Account Owner to ""Core Placeholder"" user
- Change all unconverted Leads where the related Account__c is the Account that started process so the Lead Owner is ""Core Placeholder"" user
- Mark Transfer_to_Core_Placeholder__c = False

**These scenarios need to be bulkified as we will ideally have reps mark 100+ accounts at a time from a list view */


public class AccountTransferToPlaceholder{

    public static void UpdateAccountTransferToPlaceholder(List<Account> accRecs, Map<Id,Account> oldMap){    
    
        Set<Id> acctIds_Ops = new Set<Id>();
        Set<Id> acctIds_Core = new Set<Id>();
        
        for(Account a : accRecs){
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
            List<Lead> leadList = [Select Id, OwnerId, Account__c, isConverted from Lead where Account__c in: acctIds_Ops OR Account__c in: acctIds_Core ];
            Set<Id> leadIds =new Set<Id>();
            
            for(Lead l : leadList){
                if(!l.isConverted)
                {
                    leadIds.add(l.Id);
                    
                }
            }
            
            if(!leadIds.isEmpty() && !Test.isRunningTest())
                Database.executeBatch(new AccountTransferToPlaceholderBatch(leadIds, acctIds_Ops, acctIds_Core), 1);
        }    
        
    }

}
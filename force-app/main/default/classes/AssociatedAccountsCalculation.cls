public class AssociatedAccountsCalculation{

        
    public static void updateAssociatedAccounts(List<Account> accRecs, Map<Id,Account> oldMap){
        
        Set<Id> userIds = new Set<id>();  
 
        /* Gathering all the users that are involved in the update i.e new owner and/or old owner of account into the userIds set. */ 
        if(Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate){     
             
            for(Account a : accRecs){            
                 
                if(a.OwnerId <> '0050V000006jiOvQAI'){
          
                    Account oldAcc = oldMap.get(a.Id);
                     
                    if(Trigger.isInsert || Trigger.isUnDelete || 
                        (Trigger.isUpdate && 
                            (a.OwnerId <> oldAcc.OwnerId || a.RecordTypeId <> oldAcc.RecordTypeId || a.FINANCE_Payment_Method__c <> oldAcc.FINANCE_Payment_Method__c || a.MRRCalc__c <> oldAcc.MRRCalc__c || a.RU_of_Open_Opportunities__c <> oldAcc.RU_of_Open_Opportunities__c )
                        )
                    ){  
                        userIds.add(a.OwnerId);
                        if(Trigger.isUpdate && oldAcc.OwnerId <> '0050V000006jiOvQAI')
                            userIds.add(oldAcc.OwnerId);
                     }                                          
                }
            }  
        } 
        
        if(Trigger.isDelete){
             for(Account a : accRecs){
                 if(a.OwnerId <> '0050V000006jiOvQAI'){ userIds.add(a.OwnerId); }
             }
         }  
 
        /* By this point, we have gathered all the users that are involved in the update i.e new owner and old owner of account into the userIds set. */
        if(!userIds.isEmpty() && !System.isBatch() && !System.isFuture()){
        
            Database.executeBatch(new UpdateAssociatedAccountsBatch(userIds), 1);
                    
        } 
    }
    
}
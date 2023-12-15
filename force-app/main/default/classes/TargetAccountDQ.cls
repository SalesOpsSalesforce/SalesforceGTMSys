/* 
When Target Account Status is changed to "DQ - Do not Contact", find all related leads (via Account__c field on Lead) that are not Converted and update the following Lead fields:
Lead Status = Disqualified,
Disqualification Reason = "Said No - Do Not Contact",
HasOptedOutOfEmail = TRUE
*/

public class TargetAccountDQ{

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
                    List<Lead> leadList = [Select Id, OwnerId, Account__c, isConverted from Lead where Account__c in: acctIds];
                    Set<Id> leadIds =new Set<Id>();
                    
                    for(Lead l : leadList){
                        if(!l.isConverted)
                        {
                            leadIds.add(l.Id);
                            
                        }
                    }
                    
                    if(!leadIds.isEmpty())
                        Database.executeBatch(new TargetAccountDQBatch(leadIds, acctIds), 1);
                }    
                
            }
        }
    }

}
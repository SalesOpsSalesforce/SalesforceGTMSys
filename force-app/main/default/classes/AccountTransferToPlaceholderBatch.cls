/* [vrajapatruni 12/14/2020] This is a batch class to process Place Holder assignments */

public class AccountTransferToPlaceholderBatch implements Database.Batchable<sObject> {
        
       public Set<Id> leadIds;
       public Set<Id> acctIds1;
       public Set<Id> acctIds2;
        
        public AccountTransferToPlaceholderBatch(Set<Id> leadIds, Set<Id> acctIds1, Set<Id> acctIds2){
        
            this.leadIds = leadIds;
            this.acctIds1 = acctIds1;
            this.acctIds2 = acctids2;
        }

    public Database.QueryLocator start(Database.BatchableContext bc) {
    
        return Database.getQueryLocator('Select Id, Account__c, OwnerId from Lead where Id in: leadIds');
        
    }
    public void execute(Database.BatchableContext bc, List<Lead> leadList){
        
        // [VRajapatruni update 11/21/2021 TP #91911] Using custom labels instead of SOQL queries    
        // List<User> opsUser = [Select Id from User where Name = 'Special Ops Placeholder'];
        // List<User> coreUser = [Select Id from User where Name = 'Core Placeholder'];
        
        for(Lead l : leadList){ 
        
                if(acctIds1.contains(l.Account__c))     
                   l.ownerId = System.label.Special_Ops_Placeholder_Id;
                if(acctIds2.contains(l.Account__c))     
                   l.ownerId = System.label.Core_Placeholder_Id;
            
        }
        
        update leadList;
    }
    public void finish(Database.BatchableContext bc){
        
        
    }
}
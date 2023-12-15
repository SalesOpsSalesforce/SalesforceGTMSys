public class AccountMaxActivityRollUpBatch implements Database.Batchable<sObject>{
    
    public Set<Id> acctIds = new Set<Id>();
    
    public AccountMaxActivityRollUpBatch(Set<Id> recIds){
        acctIds = recIds;
        System.debug('AccountMaxActivityRollUpBatch: Inside batch constructor acct List ' +acctIds);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        System.debug('AccountMaxActivityRollUpBatch: Inside batch QueryLocator acct List ' +acctIds);
        return Database.getQueryLocator([Select Id, Parent_Last_Activity_Date__c, Calculated_Last_Activity_Date__c from Account where Id in: acctIds order by ParentId]);
    }
 
    public void execute(Database.BatchableContext BC, List<Account> accList){
        
               
        System.debug('AccountMaxActivityRollUpBatch: Inside batch execute acct List ' +accList);
        Map<Id,Account> acctMap = new Map<Id,Account>(accList); 
        Set<Id> acctIds = acctMap.keySet();
        list<date> allDates = new list<date>();
        
        // Retrieve the IDs and Activity Dates of all the Child Accounts of the account
        List<Account> childAcctData = [Select Id, Parent_Last_Activity_Date__c, Calculated_Last_Activity_Date__c, 
                                             ParentId, 
                                             Parent.ParentId,
                                             Parent.Parent.ParentId,
                                             Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.ParentId,
                                             Parent.Parent.Parent.Parent.Parent.ParentId
                                                 from Account where 
                                                     (ParentId in: acctIds OR 
                                                     Parent.ParentId in: acctIds OR
                                                     Parent.Parent.ParentId in: acctIds OR
                                                     Parent.Parent.Parent.ParentId in: acctIds OR
                                                     Parent.Parent.Parent.Parent.ParentId in: acctIds OR
                                                     Parent.Parent.Parent.Parent.Parent.ParentId in: acctIds)];
        
        system.debug('AccountMaxActivityRollUpBatch: Child Account Data '+childAcctData);
        
        for(Account p : accList){
            
            p.Parent_Last_Activity_Date__c = null;
            allDates = new list<date>();
                        
            // Add all the activity dates of the accounts to a list
            for(Account a : childAcctData){
                
                System.debug('AccountMaxActivityRollUpBatch: Inside for loop for gathering ChildAccountData');
                
                if(
                    p.Id == a.ParentId || 
                    p.Id == a.Parent.ParentId || 
                    p.Id == a.Parent.Parent.ParentId ||    
                    p.Id == a.Parent.Parent.Parent.ParentId ||
                    p.Id == a.Parent.Parent.Parent.Parent.ParentId ||
                    p.Id == a.Parent.Parent.Parent.Parent.Parent.ParentId
                ){ 
                     System.debug('Id of the account ' +a.Id);
                     if(a.Calculated_Last_Activity_Date__c != null){   
                        allDates.add(a.Calculated_Last_Activity_Date__c);
                        System.debug('Date added for account ' +a.Id);
                     }
                }
            } 
            
            // Sort the dates such that the max date is the last one in the list and assign it to the parent last activity date
            if(allDates.size() > 0){
                
                allDates.sort(); 
                p.Parent_Last_Activity_Date__c = allDates[Alldates.size()-1]; 
                System.debug('AccountMaxActivityRollUpBatch: Updated parent last activity date ' +p.Id);
                
            }  
        }
        
        update accList;
        
    }
 
    public void finish(Database.BatchableContext BC){
    }

}
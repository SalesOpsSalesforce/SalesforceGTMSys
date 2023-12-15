public class AccountMRRRollUpBulkUpdateBatch implements Database.Batchable<sObject>{
          
    public Database.QueryLocator start(Database.BatchableContext BC){
    
        return Database.getQueryLocator([Select Id, Total_MRR_of_Child_Accounts__c, MRRCalc__c from Account where ParentId != null or RecordType.Name = 'Parent Account'  order by ParentId]);
        
    }
 
    public void execute(Database.BatchableContext BC, List<Account> accList){
    
        Map<Id,Account> acctMap = new Map<Id,Account>(accList); 
        Set<Id> acctIds = acctMap.keySet();
        
        List<Account> childAcctData = [Select Id, Total_MRR_of_Child_Accounts__c, MRRCalc__c, 
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
        
        for(Account p : accList){
            
            p.Total_MRR_of_Child_Accounts__c = 0;
            
            for(Account a : childAcctData){
                if(p.Id == a.ParentId || 
                    p.Id == a.Parent.ParentId || 
                    p.Id == a.Parent.Parent.ParentId ||    
                    p.Id == a.Parent.Parent.Parent.ParentId ||
                    p.Id == a.Parent.Parent.Parent.Parent.ParentId ||
                    p.Id == a.Parent.Parent.Parent.Parent.Parent.ParentId
                ){
                    p.Total_MRR_of_Child_Accounts__c += a.MRRCalc__c;
                    System.debug('Account has been proceessed');
                }
            }  
                 
        }   
        
        update accList;
        
    }
 
    public void finish(Database.BatchableContext BC){
    }

}
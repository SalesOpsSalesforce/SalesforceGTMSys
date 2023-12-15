// [VRajapatruni 06/27/2023 SFDC-3017] Converting Batch jobs to dual mode - Batch and Queueable based on list size
public class AccountMRRRollUpUpdateQueueable implements System.Queueable {
    Set<Id> acctIds = new Set<Id>();
    List<Account> accList = new List<Account>();
    
    public AccountMRRRollUpUpdateQueueable(Set<Id> recIds, List<Account> recList){
        this.acctIds = recIds;
        this.accList = recList;
    }
    
    public void execute(QueueableContext context) {
        //accList = [Select Id, Total_MRR_of_Child_Accounts__c, MRRCalc__c from Account where Id in: acctIds order by ParentId];
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
                  }
            } 
        }
        // update accList;
        Database.update(accList, false); //[SFDC-1524 VR] Updated to allow partial processing due to row locking issue
    }
}
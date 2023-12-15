//[RGaokar 07/10/2023 SFDC-3038 Extensive logic in PartnerAccountTotalMRRBatch finish method is causing Apex CPU time out error]
//First step is to move partner parent update DML to this chained batch apex instead of re-architecting entire finish method logic for PartnerAccountTotalMRRBatch
public class PartnerParentMRRRollup implements Database.Batchable<sObject>{
    Map<Id, Account> mapOfParentAccount = new Map<Id, Account>();
    public PartnerParentMRRRollup(Map<Id, Account> mapOfParentAccount){
        this.mapOfParentAccount = mapOfParentAccount;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        set<id>parentIds = new set<id>();
        parentIds.addAll(mapOfParentAccount.keyset());
        String query = 'Select id from account where id in :parentIds';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        List<account>updateAccList = new List<account>();
        for(Account a:(List<account>)scope){
            updateAccList.add(mapOfParentAccount.get(a.id));
        }
        
        if(!updateAccList.isEmpty()){
            Database.update(updateAccList, false);
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        
    }

}
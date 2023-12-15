public class CharmRevenueRollupBatch implements Database.Batchable<sObject> {
    set<id> parentaccountIds = new set<id>();//parent accounts for those need to update the rollup
    string runQuery = null; 
    public CharmRevenueRollupBatch(Set<id>parentaccountIds, string runQuery){
        this.parentaccountIds = parentaccountIds;
        this.runQuery = runQuery;
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        string query;
        if(runQuery == null){
            //Get 6 level of account hierarchy. Parent ids are already available so skipping where clause for parentid in:parentaccountIds
            //while higher parent clause are addeded (parent.parentid in:parentaccountIds OR ....) to capture the lower level children if intermediate parent account changed for charm revenue
            query = 'Select id, parentid, parent.parentid, parent.parent.parentid, parent.parent.parent.parentid, parent.parent.parent.parent.parentid, Total_Charm_Revenue_of_Child_Accounts__c, ParentId_Charm_Revenue_Roll_Up_Update__c from account';
            query += ' where id in:parentaccountIds OR parent.parentid in:parentaccountIds OR parent.parent.parentid in:parentaccountIds OR parent.parent.parent.parentid in:parentaccountIds OR parent.parent.parent.parent.parentid in:parentaccountIds';
            query += ' Order by parentid, parent.parentid, parent.parent.parentid, parent.parent.parent.parentid, parent.parent.parent.parent.parentid'; 
        }else{
            //Run the query passed from Execute Anonymous Window
            //runQuery = 'Select id, parentid, parent.parentid, parent.parent.parentid, parent.parent.parent.parentid, parent.parent.parent.parent.parentid, Total_Charm_Revenue_of_Child_Accounts__c, ParentId_Charm_Revenue_Roll_Up_Update__c from account'
            //runQuery += ' where parentId != null'
            //runQuery += ' Order by parentid, parent.parentid, parent.parent.parentid, parent.parent.parent.parentid, parent.parent.parent.parent.parentid'; 
            query = runQuery;
        }
        
        return Database.getQueryLocator(query);
        
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        set<id> parentIds = new set<id>();
        map<id, id> parentGrandParentMap = new map<id, id>();
        map<id, rollupWrapper> levelOneRevenueRollupMap = new map<id, rollupWrapper>();
        map<id, rollupWrapper> levelTwoRevenueRollupMap = new map<id, rollupWrapper>();
        map<id, rollupWrapper> levelThreeRevenueRollupMap = new map<id, rollupWrapper>();
        map<id, rollupWrapper> levelFourRevenueRollupMap = new map<id, rollupWrapper>();
        map<id, rollupWrapper> levelFiveRevenueRollupMap = new map<id, rollupWrapper>();
        map<id, rollupWrapper> updateRollupMap = new map<id, rollupWrapper>();
        List<account> updateAccountList = new List<account>();
        
        for(account a:(List<Account>)scope){
            parentIds.add(a.Id);
            if(a.parentid != null)parentIds.add(a.parentid);
            if(a.parent.parentid != null)parentIds.add(a.parent.parentid);
            if(a.parent.parent.parentid != null)parentIds.add(a.parent.parent.parentid);
            if(a.parent.parent.parent.parentid != null)parentIds.add(a.parent.parent.parent.parentid);
            if(a.parent.parent.parent.parent.parentid != null)parentIds.add(a.parent.parent.parent.parent.parentid);
        }
        
        //Get rollup for immediate parent
        List<AggregateResult> immediateParentRollups = [Select parentid Parent, parent.parentid grandParent, parent.parent.parentid greatGrandParent, 
                                                        parent.parent.parent.parentid superParent, parent.parent.parent.parent.parentid topSuperParent,
                                                        Count(Id)totalChildren, SUM(Charm_Revenue__c)sumCharmRevenue from account 
                                                        where parentid in :parentIds Group By parentid, parent.parentid, parent.parent.parentid, 
                                                        parent.parent.parent.parentid, parent.parent.parent.parent.parentid];
        
        
        for(AggregateResult ar:immediateParentRollups){
            //segregate accounts as per hierarchy levels and pair parent and grandparent
            double revenueSum = ((double)ar.get('sumCharmRevenue') == null)?0:(double)ar.get('sumCharmRevenue');
            rollupWrapper rollupWrp = new rollupWrapper(revenueSum, (integer)ar.get('totalChildren'));
            if(ar.get('grandParent') == null){
                levelOneRevenueRollupMap.put((id)ar.get('Parent'), rollupWrp);
            }else if(ar.get('greatGrandParent') == null){
                levelTwoRevenueRollupMap.put((id)ar.get('Parent'), rollupWrp);
                parentGrandParentMap.put((id)ar.get('Parent'), (id)ar.get('grandParent'));
            }else if(ar.get('superParent') == null){
                levelThreeRevenueRollupMap.put((id)ar.get('Parent'), rollupWrp);
                parentGrandParentMap.put((id)ar.get('Parent'), (id)ar.get('grandParent'));
            }else if(ar.get('topSuperParent') == null){
                levelFourRevenueRollupMap.put((id)ar.get('Parent'), rollupWrp);
                parentGrandParentMap.put((id)ar.get('Parent'), (id)ar.get('grandParent'));
            }else{
                levelFiveRevenueRollupMap.put((id)ar.get('Parent'), rollupWrp);
                parentGrandParentMap.put((id)ar.get('Parent'), (id)ar.get('grandParent'));
            }
        }
        
        //Roll up the values (revenue and childern) in account hierarchy
        if(!levelFiveRevenueRollupMap.isEmpty()){
            levelFourRevenueRollupMap = rollupCalculation(levelFiveRevenueRollupMap,levelFourRevenueRollupMap,parentGrandParentMap);//Level 5(parent) roll ups to 4(grand parent)
            updateRollupMap.putAll(levelFiveRevenueRollupMap);
        }
        
        if(!levelFourRevenueRollupMap.isEmpty()){
            levelThreeRevenueRollupMap = rollupCalculation(levelFourRevenueRollupMap,levelThreeRevenueRollupMap,parentGrandParentMap);//Level 4(grand parent) roll ups to 3(great grand parent)
            updateRollupMap.putAll(levelFourRevenueRollupMap);
        }
        
        if(!levelThreeRevenueRollupMap.isEmpty()){
            levelTwoRevenueRollupMap = rollupCalculation(levelThreeRevenueRollupMap,levelTwoRevenueRollupMap,parentGrandParentMap);//Level 3 (great grand parent) roll ups to 2 (super parent)
            updateRollupMap.putAll(levelThreeRevenueRollupMap);
        }
        
        if(!levelTwoRevenueRollupMap.isEmpty()){
            levelOneRevenueRollupMap = rollupCalculation(levelTwoRevenueRollupMap,levelOneRevenueRollupMap,parentGrandParentMap);//Level 2 (super parent) roll ups to 1 (top super parent)
            updateRollupMap.putAll(levelTwoRevenueRollupMap);
        }
        
        
        //Update the child rollup on first level parent accounts
        updateRollupMap.putAll(levelOneRevenueRollupMap);
        
        //system.debug('updateRollupMap.size--'+updateRollupMap.size());
        
        //Add accounts for update in a list
        for(Id accId: updateRollupMap.keyset()){
            Account a = new Account();
            a.Id = accId;
            a.Total_Charm_Revenue_of_Child_Accounts__c = updateRollupMap.get(accId).sumCharmRevenue;
            a.Average_Charm_Revenue_of_Child_Accounts__c = updateRollupMap.get(accId).sumCharmRevenue/updateRollupMap.get(accId).totalChildern;
            a.ParentId_Charm_Revenue_Roll_Up_Update__c = null;//Clear the flag on parent accounts
            updateAccountList.add(a); 
        }
        
        //If accounts do not have a child then clear rollup for those accounts.
        for(account acc:(List<Account>)scope){
            if((updateRollupMap.isEmpty()||!updateRollupMap.containsKey(acc.Id)) && 
               (acc.Total_Charm_Revenue_of_Child_Accounts__c != null || acc.ParentId_Charm_Revenue_Roll_Up_Update__c != null)){
                Account a = new Account();
                a.Id = acc.Id;
                a.Total_Charm_Revenue_of_Child_Accounts__c = null;
                a.Average_Charm_Revenue_of_Child_Accounts__c = null;
                a.ParentId_Charm_Revenue_Roll_Up_Update__c = null;//Clear the flag on parent accounts
                updateAccountList.add(a); 
            }  
        }
        
        //Update records
        if(!updateAccountList.isEmpty()){
            String errorString = '';
            List<Database.SaveResult> srList = Database.update(updateAccountList, false);
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    errorString += '\n'+'Record Id: '+ result.getId();
                    for(Database.Error err : result.getErrors()) {
                        errorString += ' Error Message: ' +err.getMessage()+'\n';
                    } 
                }
            }
            
            //Create expection record for errors
            if(String.isNotBlank(errorString)){
                List <String> executionFlow = new List <String> ();
                executionFlow.add('Errors occured when updating Charm revenue rollup for following records:');
                executionFlow.add(errorString);
                ExceptionHandling.performExceptionHandling(null, 'CharmRevenueRollupBatch', executionFlow);
            }
        }     
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
    //Helper method for roll up calculation
    public map<id, rollupWrapper> rollupCalculation(map<id, rollupWrapper> childRollup, map<id, rollupWrapper> parentRollup, map<id, id> parentGrandParentMap){
        for(id child:childRollup.keyset()){
            if(parentGrandParentMap.containskey(child) && parentRollup.containskey(parentGrandParentMap.get(child))){//Checking child is available with immediate parent and immediate parent is available in parentRollup 
                //Adding all childern total charm revenue to parent to rollup for next level in hierarchy
                parentRollup.get(parentGrandParentMap.get(child)).sumCharmRevenue += childRollup.get(child).sumCharmRevenue;
                parentRollup.get(parentGrandParentMap.get(child)).totalChildern += childRollup.get(child).totalChildern;
            }   
        }
        return parentRollup;   
    }
    
    //Wrapper to hold Charm revenue and childern rollup for a parent
    public class rollupWrapper{
        public double sumCharmRevenue{get;set;}
        public integer totalChildern{get;set;}
        public rollupWrapper(double sumCharmRevenue, integer totalChildern){
            this.sumCharmRevenue = sumCharmRevenue;
            this.totalChildern = totalChildern;
        }
    }
    
}
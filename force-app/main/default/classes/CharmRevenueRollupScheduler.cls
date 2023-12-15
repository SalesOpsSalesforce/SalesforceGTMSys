//[RGaokar 08/18/2022 SFDC-524 Charm Revenue Rollup Scheduler]
public class CharmRevenueRollupScheduler implements system.Schedulable {
    public void execute (System.SchedulableContext sc){
        manualRun();  
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    public static void manualRun(){
        set<id> parentAccIds = new set<id>();//parent accounts for those rollup need to be updated 
        List<Account> accList = [Select ParentId_Charm_Revenue_Roll_Up_Update__c from account where ParentId_Charm_Revenue_Roll_Up_Update__c != null order by ParentId_Charm_Revenue_Roll_Up_Update__c];
        for(Account a:accList){
           parentAccIds.add(a.ParentId_Charm_Revenue_Roll_Up_Update__c);
        }
        //Send Ids to Batch Job
        CharmRevenueRollupBatch rollupBatch = new CharmRevenueRollupBatch(parentAccIds, null);
        Database.executeBatch(rollupBatch, 25);
    }

}
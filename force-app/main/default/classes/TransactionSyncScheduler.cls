//[RGaokar 06/27/2023 SFDC-2895 Failed Real time sync transactions retry scheduler]
//The Real time sync send the failed transactions (failed & never retried or retries exhausted)
//This job perform scheduling to sync the transaction information to Opportunity
public class TransactionSyncScheduler implements System.Schedulable {
    public void execute(system.SchedulableContext sc){
        manualRun();
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    public static void manualRun(){
        TransactionSyncBatch trBatch = new TransactionSyncBatch();
        Database.executeBatch(trBatch, 10);//Keeping small batch size to avoid errors due to heavy MPO processes//10
    }
}
//[RGaokar 11/25/2022 SFDC-1161 Schduler to handle Failed Redpoint Sync records (SF --> Redpoint)]
public class RedpointFailedRecordSyncScheduler implements system.Schedulable{
    public void execute(system.SchedulableContext sc){
        manualRun();
        
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    // This method passes first parameter whereClause = null as it is set in start method of RedpointFailedContactAccountSyncBatch batch
    // This method passes 2nd parameter runCasacadedBatch = true that will call batches one after the other as follows: account & contact batch, lead batch
    // To run each account & contact batch, lead batch independently for custom query, call respective batches directly from an Execute Anonymous Window & set the parameters as mentioned in those batch classes.
    
    public static void manualRun(){
        RedpointFailedContactAccountSyncBatch redpointFailedConAccBatch = new RedpointFailedContactAccountSyncBatch(null, true);
        Database.executeBatch(redpointFailedConAccBatch,100);
    }

}
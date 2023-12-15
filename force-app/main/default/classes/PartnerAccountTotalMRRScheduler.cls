//[RGaokar 03/21/2022 112401 Scheduler for Partner Splits Totals Calulation on Related Partner Accounts]
//Runs every day on eligible Partner Account records
public class PartnerAccountTotalMRRScheduler implements Schedulable{
    
    public void execute(SchedulableContext sc) {
        manualRun();
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    public static void manualRun(){  
        // All Eligible partner accounts have a large number of partner split records associated with them.
        // So to avoid hitting 'Too many query rows: 50001' error, batch apex is used to split partner accounts into small chunks. 
        PartnerAccountTotalMRRBatch partnerMRRTotalBatch = new PartnerAccountTotalMRRBatch();
        Database.executeBatch(partnerMRRTotalBatch, 10);
    }
    
}
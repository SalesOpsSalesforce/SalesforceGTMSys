//[RGaokar 12/28/2022 SFDC-1546 Offload Redpoint Formula Widget update process for KPU nightly sync job]
public class RedpointKPUSyncWidgetScheduler implements system.Schedulable{
    public void execute(system.SchedulableContext sc){
        manualRun();  
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    
    public static void manualRun(){
        RedpointKPUNightlySyncWidgetBatch redpointKPUNightlyUpdates = new RedpointKPUNightlySyncWidgetBatch();
        Database.executeBatch(redpointKPUNightlyUpdates, 100);
    }

}
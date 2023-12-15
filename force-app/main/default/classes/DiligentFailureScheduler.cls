//[RGaokar 3/10/2023 SFDC-2132 Failed Diligent Callout Processing Weekly Job Scheduler]
public class DiligentFailureScheduler implements system.Schedulable{
    
    public void execute(system.SchedulableContext sc){
        manualRun();
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    public static void manualRun(){
        Database.executeBatch(new DiligentFailureHandlingBatch(null), 100);
    }
}
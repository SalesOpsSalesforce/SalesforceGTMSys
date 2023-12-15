//[RGaokar 04/29/2022 TP # 119631] Similarweb scheduler class for processing monthly bulk account records
public class SimilarWebScheduler implements System.Schedulable {
    
    public void execute(System.SchedulableContext sc){
        manualRun();
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    public static void manualRun(){
        string query = 'Select id, Clean_Website__c from Account where Clean_Website__c <> Null AND recordtype.developername = \'Klaviyo_Account\'';
        SimilarWebBatch swBatch = new SimilarWebBatch(query, null, false);
        Database.executeBatch(swBatch, 10);
    }  
}
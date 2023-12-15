//[RGaokar 04/27/2022 TP #119800] Charm io scheduler class for processing weekly bulk account records
public class CharmDataEnrichmentScheduler implements system.Schedulable{
    
    public void execute(System.SchedulableContext sc){
        manualRun();
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    public static void manualRun(){
        string query = 'Select id, Clean_Website__c from Account where Clean_Website__c <> Null AND recordtype.developername = \'Klaviyo_Account\'';
        CharmDataEnrichmentBatch charmBatch = new CharmDataEnrichmentBatch(query, null);
        Database.executeBatch(charmBatch, 100);
    }

}
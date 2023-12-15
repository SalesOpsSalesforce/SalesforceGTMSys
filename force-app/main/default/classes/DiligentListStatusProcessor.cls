//[RGaokar 3/24/2023 SFDC-2030 Diligent <> SFDC Activate/Deactivate Diligent List for Annual Refresh]
//API: Monitor list api: update list https://search.transparint.com/api/v1/monitor_list
public class DiligentListStatusProcessor implements system.Queueable, Database.AllowsCallouts{
    private string status;
    public DiligentListStatusProcessor(string status){
        this.status = status;
    }
    
    public void execute(system.QueueableContext ctx){
        manualRun(this.status);
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    public static void manualRun(string status){      
        //Activate/Deactivate List
        //If there are multiple Diligent lists per type then fetch all active as well as inactive lists for annual results refresh
        List<Diligent_Monitored_List__mdt> monitorList = [Select Id, List_Id__c, Type__c From Diligent_Monitored_List__mdt];
        
        //Iterate over each list record to activate/deactivate the list
        for(Diligent_Monitored_List__mdt listRecord:monitorList){
            DiligentCalloutHelper.processListStatus(listRecord.List_Id__c, status);
        }  
    } 
}
//[RGaokar 3/24/2023 SFDC-2030 Diligent <> SFDC Deactivate Diligent List for Annual Refresh]
//API: Monitor list api: update list https://search.transparint.com/api/v1/monitor_list
public class DiligentDeactivateListScheduler implements system.Schedulable {
    
    public void execute(system.SchedulableContext sc){
        DiligentListStatusProcessor statusProcessor = new DiligentListStatusProcessor('Pause');
        system.enqueueJob(statusProcessor);
    }
}
//[RGaokar 3/24/2023 SFDC-2030 Diligent <> SFDC Retrieved Monitor Term Results for Annual Refresh]
//API: Retrieve Monitor Results for a Term https://search.transparint.com/api/v1/monitor_term_results
    
public class DiligentMonitorResultsScheduler implements system.Schedulable{
    
    public void execute(system.SchedulableContext sc){
        DiligentMonitorPartnerResultBatch partnerRIDBatch = new DiligentMonitorPartnerResultBatch(null,true);
        Database.executeBatch(partnerRIDBatch, 100);//Diligent api rate limit is 100 api calls/minute
    }
}
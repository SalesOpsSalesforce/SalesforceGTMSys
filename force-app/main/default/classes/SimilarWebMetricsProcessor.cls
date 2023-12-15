//[RGaokar 04/29/2022 TP #119625] Similarweb helper class for processing single record in trigger
public class SimilarWebMetricsProcessor implements System.Queueable, Database.AllowsCallouts{
    private List<sObject> recordList = new List<sObject>();
    private Boolean setTotalVisitsAtOwnerChange = false;
    
    public SimilarWebMetricsProcessor(List<sObject> recordList, Boolean setTotalVisitsAtOwnerChange){
        this.recordList = recordList;
        this.setTotalVisitsAtOwnerChange = setTotalVisitsAtOwnerChange;
    }
    
    public void execute (system.QueueableContext ctx){
        SimilarWebCallouts.processSimilarWebCallouts(recordList, setTotalVisitsAtOwnerChange);
    }

}
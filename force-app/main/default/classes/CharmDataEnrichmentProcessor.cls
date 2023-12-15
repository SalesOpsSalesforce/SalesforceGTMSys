//[RGaokar 04/27/2022 TP #119370] Charm io helper class for processing single record in trigger
public class CharmDataEnrichmentProcessor implements System.Queueable, Database.AllowsCallouts{
    private List<sObject> recordList = new List<sObject>(); 
    
    public CharmDataEnrichmentProcessor(List<sObject> recordList){
        this.recordList = recordList;
    }
    
    public void execute (system.QueueableContext ctx){
        CharmDataEnrichmentCallouts.processCharmCallouts(recordList);
    }
    
}
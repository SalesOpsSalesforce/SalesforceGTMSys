//[RGaokar 04/29/2022 TP #119625, 119631] Similarweb batch class for processing bulk account & lead records in trigger / monthly account updates
//Receives query from trigger/scheduler and sends the records to SimilarWebCallouts helper class
public class SimilarWebBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
    private string recordQuery;
    private set <id>recordIds;
    private Boolean setTotalVisitsAtOwnerChange = false;
    public SimilarWebBatch(String query, set <id>recordIds, Boolean setTotalVisitsAtOwnerChange){
        this.recordQuery = query;
        this.recordIds= recordIds;
        this.setTotalVisitsAtOwnerChange = setTotalVisitsAtOwnerChange;
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        if(recordIds != null){
           recordQuery += ':recordIds';
        }
        system.debug('recordQuery--'+recordQuery);
        return Database.getQueryLocator(recordQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        SimilarWebCallouts.processSimilarWebCallouts(scope, setTotalVisitsAtOwnerChange);   
    }
    
    public void finish(Database.BatchableContext bc){
        
    }

}
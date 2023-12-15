//[RGaokar 05/06/2022 TP #119370, 119800] Charm io batch class for processing bulk account & lead records in trigger / weekly account updates
//Receives query from trigger/scheduler and sends the records to CharmDataEnrichmentCallouts helper class
public class CharmDataEnrichmentBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    private string recordQuery;
    private set <id>recordIds;
    public CharmDataEnrichmentBatch(string recordQuery, set <id>recordIds){
        this.recordQuery = recordQuery;
        this.recordIds= recordIds;
    }
    public Database.QueryLocator start (Database.BatchableContext bc){
        if(recordIds != null){
           recordQuery += ':recordIds';
        }
        system.debug('recordQuery--'+recordQuery);
        return Database.getQueryLocator(recordQuery); 
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        CharmDataEnrichmentCallouts.processCharmCallouts(scope); 
    }
    
    public void finish(Database.BatchableContext bc){
        
    }

}
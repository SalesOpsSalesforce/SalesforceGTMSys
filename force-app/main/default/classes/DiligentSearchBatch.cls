//[RGaokar 2/27/2023 SFDC-1881 Diligent Search Batch Class]
//API: Start Search https://search.transparint.com/api/v1/search
public class DiligentSearchBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful {
    private List<DiligentSearchProcessor.DiligentPayload>diligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
    private List<DiligentSearchProcessor.DiligentPayload>updatedDiligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
    private map<id, DiligentSearchProcessor.DiligentPayload> accIdDiligentPayloadMap = new map<id, DiligentSearchProcessor.DiligentPayload>();
    //Constructor
    public DiligentSearchBatch(List<DiligentSearchProcessor.DiligentPayload>diligentPayloads){
        this.diligentPayloadList = diligentPayloads;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Create map for account id & payload to send the payload in batch
        for(DiligentSearchProcessor.DiligentPayload payload:diligentPayloadList){
            accIdDiligentPayloadMap.put(payload.accountId, payload); 
        }
        Set<id> accountIds = accIdDiligentPayloadMap.keyset();
        String query = 'Select id from account where id in :accountIds';
        return Database.getQueryLocator(query);  
    }
    
    public void execute (Database.BatchableContext bc, List<sObject>scope){
        List<DiligentSearchProcessor.DiligentPayload>diligentPayloadBatch = new List<DiligentSearchProcessor.DiligentPayload>();
        for(sObject a:scope){
            diligentPayloadBatch.add(accIdDiligentPayloadMap.get(a.id)); 
        }
        
        //Send batch of payload for processing
        updatedDiligentPayloadList.addAll(DiligentCalloutHelper.processDiligentSearchPayload(diligentPayloadBatch, 'search'));
    }
    
    public void finish(Database.BatchableContext bc){
        if(!updatedDiligentPayloadList.isEmpty() && !Test.isRunningTest()){
            system.scheduleBatch(new DiligentSearchStatusBatch(updatedDiligentPayloadList), 'DiligentSearchStatusBatch'+System.now(), 1, 100);//Call another batch job after 1 minute to get search status
        }
    }
}
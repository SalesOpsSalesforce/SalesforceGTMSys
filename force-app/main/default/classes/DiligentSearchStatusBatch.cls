//[RGaokar 2/27/2023 SFDC-1881 Diligent Search Status Batch Class]
//API: Get Search Status https://search.transparint.com/api/v1/status
public class DiligentSearchStatusBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    private List<DiligentSearchProcessor.DiligentPayload>diligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
    private List<DiligentSearchProcessor.DiligentPayload>updatedDiligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
    private map<id, DiligentSearchProcessor.DiligentPayload> accIdDiligentPayloadMap = new map<id, DiligentSearchProcessor.DiligentPayload>();
    
    public DiligentSearchStatusBatch (List<DiligentSearchProcessor.DiligentPayload>diligentPayloads){
        this.diligentPayloadList = diligentPayloads;
    }
    
    //Chained batch apex job called from DiligentSearchBatch after delay of 1 Minute
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
        updatedDiligentPayloadList.addAll(DiligentCalloutHelper.processDiligentSearchPayload(diligentPayloadBatch,'status'));
    }
    
    public void finish(Database.BatchableContext bc){
        if(!updatedDiligentPayloadList.isEmpty() && !Test.isRunningTest() ){
            Database.executeBatch(new DiligentSearchResultBatch(updatedDiligentPayloadList), 100);//Call another Batch job to retrieve results
        }
    }  
}
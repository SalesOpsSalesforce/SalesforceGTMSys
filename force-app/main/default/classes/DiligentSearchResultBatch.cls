//[RGaokar 2/27/2023 SFDC-1881 Diligent Search Result Batch]
//API: Retrieve Results https://search.transparint.com/api/v1/results
public class DiligentSearchResultBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    private List<DiligentSearchProcessor.DiligentPayload>diligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
    private List<DiligentSearchProcessor.DiligentPayload>succeededRecords = new List<DiligentSearchProcessor.DiligentPayload>();
    private map<id, DiligentSearchProcessor.DiligentPayload> accIdDiligentPayloadMap = new map<id, DiligentSearchProcessor.DiligentPayload>();
    
    public DiligentSearchResultBatch (List<DiligentSearchProcessor.DiligentPayload>diligentPayloads){
        this.diligentPayloadList = diligentPayloads;
    }
    
    //Chained Batch apex job called from DiligentSearchStatusBatch
    public Database.QueryLocator start (Database.BatchableContext bc){
        //Create map for account id & payload to send the payload in batch
        for(DiligentSearchProcessor.DiligentPayload payload:diligentPayloadList){
            accIdDiligentPayloadMap.put(payload.accountId, payload); 
        }
        Set<id> accountIds = accIdDiligentPayloadMap.keyset();
        String query = 'Select id from account where id in :accountIds';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        List<DiligentSearchProcessor.DiligentPayload>diligentPayloadBatch = new List<DiligentSearchProcessor.DiligentPayload>();
        for(sObject a:scope){
            diligentPayloadBatch.add(accIdDiligentPayloadMap.get(a.id)); 
        }
        
        //Send batch of payload for processing
        List<DiligentSearchProcessor.DiligentPayload>updatedDiligentPayloadList = DiligentCalloutHelper.processDiligentSearchPayload(diligentPayloadBatch,'results');
        if(!updatedDiligentPayloadList.isEmpty()){
            succeededRecords.addAll(DiligentCalloutHelper.processDiligentResults(updatedDiligentPayloadList));
        }
    }
    
    public void finish(Database.BatchableContext bc){
        //Convert Search to Monitor Term
        if(!succeededRecords.isEmpty() && !Test.isRunningTest()){
            Database.executeBatch(new DiligentMonitorTermBatch(succeededRecords), 100);
        }
    }  
}
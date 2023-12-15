//[RGaokar 2/27/2023 SFDC-1881 Diligent Monitor Term Processor]
//API: Convert Search to Monitor Term http://search.transparint.com/api/v1/convert_to_monitor
public class DiligentMonitorTermBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    private List<DiligentSearchProcessor.DiligentPayload>succeededRecords = new List<DiligentSearchProcessor.DiligentPayload>();
    private map<id, DiligentSearchProcessor.DiligentPayload> accIdDiligentPayloadMap = new map<id, DiligentSearchProcessor.DiligentPayload>();
    
    public DiligentMonitorTermBatch (List<DiligentSearchProcessor.DiligentPayload>succeededRecordPayloads){
        this.succeededRecords = succeededRecordPayloads;
    }
  
    //Chained Batch apex job called from DiligentSearchResultBatch
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Create map for account id & payload to send the payload in batch
        for(DiligentSearchProcessor.DiligentPayload payload:succeededRecords){
            accIdDiligentPayloadMap.put(payload.accountId, payload); 
        }
        Set<id> accountIds = accIdDiligentPayloadMap.keyset();
        String query = 'Select id from account where id in :accountIds';
        return Database.getQueryLocator(query); 
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        List<DiligentSearchProcessor.DiligentPayload>diligentPayloadBatch = new List<DiligentSearchProcessor.DiligentPayload>();
        List<DiligentSearchProcessor.DiligentPayload>updatedDiligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
        for(sObject a:scope){
            diligentPayloadBatch.add(accIdDiligentPayloadMap.get(a.id)); 
        }
        
        //Send batch of payload for processing
        updatedDiligentPayloadList.addAll(DiligentCalloutHelper.processDiligentSearchPayload(diligentPayloadBatch,'convert_to_monitor'));
        if(!updatedDiligentPayloadList.isEmpty()){
            DiligentCalloutHelper.processMonitorTermInfo(updatedDiligentPayloadList);
        } 
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}
//[RGaokar 2/27/2023 SFDC-1881 Diligent Monitor Term Processor]
//API: Convert Search to Monitor Term http://search.transparint.com/api/v1/convert_to_monitor
public class DiligentMonitorTermProcessor implements system.Queueable,Database.AllowsCallouts{
    private List<DiligentSearchProcessor.DiligentPayload>succeededRecords = new List<DiligentSearchProcessor.DiligentPayload>();
    public DiligentMonitorTermProcessor (List<DiligentSearchProcessor.DiligentPayload>succeededRecordPayloads){
        this.succeededRecords = succeededRecordPayloads;
    }
    
    //Chained Queueable job called from DiligentSearchResultProcessor
    public void execute(system.QueueableContext ctx){
        List<DiligentSearchProcessor.DiligentPayload>updatedDiligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
        updatedDiligentPayloadList.addAll(DiligentCalloutHelper.processDiligentSearchPayload(succeededRecords,'convert_to_monitor'));
        if(!updatedDiligentPayloadList.isEmpty()){
            DiligentCalloutHelper.processMonitorTermInfo(updatedDiligentPayloadList);
        }
    }
}
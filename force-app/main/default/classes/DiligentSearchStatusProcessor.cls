//[RGaokar 2/27/2023 SFDC-1881 Diligent Search Status Processor]
//API: Get Search Status https://search.transparint.com/api/v1/status
public class DiligentSearchStatusProcessor implements system.Queueable,Database.AllowsCallouts{
    private List<DiligentSearchProcessor.DiligentPayload>diligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
    private List<DiligentSearchProcessor.DiligentPayload>updatedDiligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
    public DiligentSearchStatusProcessor (List<DiligentSearchProcessor.DiligentPayload>diligentPayloads){
        this.diligentPayloadList = diligentPayloads;
    }
    
    //Chained queueable job called from DiligentSearchProcessor after delay of 1 Minute
    public void execute(system.QueueableContext ctx){
        updatedDiligentPayloadList.addAll(DiligentCalloutHelper.processDiligentSearchPayload(diligentPayloadList,'status'));
        if(!updatedDiligentPayloadList.isEmpty() && !Test.isRunningTest() ){
            system.enqueueJob(new DiligentSearchResultProcessor(updatedDiligentPayloadList));//Call another Queueable job to retrieve results
        }
    }
}
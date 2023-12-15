//[RGaokar 2/27/2023 SFDC-1881 Diligent Search Result Processor]
//API: Retrieve Results https://search.transparint.com/api/v1/results
public class DiligentSearchResultProcessor implements system.Queueable,Database.AllowsCallouts{
    private List<DiligentSearchProcessor.DiligentPayload>diligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();
    private List<DiligentSearchProcessor.DiligentPayload>succeededRecords = new List<DiligentSearchProcessor.DiligentPayload>();
    
    public DiligentSearchResultProcessor (List<DiligentSearchProcessor.DiligentPayload>diligentPayloads){
        this.diligentPayloadList = diligentPayloads;
    }
    
    //Chained Queueable job called from DiligentSearchStatusProcessor
    public void execute(system.QueueableContext ctx){
        List<DiligentSearchProcessor.DiligentPayload>updatedDiligentPayloadList = DiligentCalloutHelper.processDiligentSearchPayload(diligentPayloadList,'results');
        if(!updatedDiligentPayloadList.isEmpty()){
            succeededRecords.addAll(DiligentCalloutHelper.processDiligentResults(updatedDiligentPayloadList));
        }
        //Convert Search to Monitor Term
        if(!succeededRecords.isEmpty() && !Test.isRunningTest() ){
            system.enqueueJob(new DiligentMonitorTermProcessor(succeededRecords));
        } 
    }  
}
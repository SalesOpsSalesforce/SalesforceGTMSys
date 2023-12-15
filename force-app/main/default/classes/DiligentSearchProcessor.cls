//[RGaokar 2/27/2023 SFDC-1881 Diligent Search Processor]
//API: Start Search https://search.transparint.com/api/v1/search
public class DiligentSearchProcessor implements System.Queueable,Database.AllowsCallouts{
    private List<DiligentPayload>diligentPayloadList = new List<DiligentPayload>();
    private List<DiligentPayload>updatedDiligentPayloadList = new List<DiligentPayload>();
    //Constructor
    public DiligentSearchProcessor(List<DiligentPayload>diligentPayloads){
        this.diligentPayloadList = diligentPayloads;
    }
    
    //Invocable method called from account after save flow
    @invocableMethod (label = 'Get Diligent Search Terms')
    public static void getDiligentSearchTerms(List<DiligentPayload>diligentPayloads){
        Diligent_Search_Disablement_Switch__mdt diligentDisablementSwitch = Diligent_Search_Disablement_Switch__mdt.getInstance('Diligent_Search');
        if(!diligentDisablementSwitch.Diligent_Search_Disabled__c){//If Diligent Search is NOT disabled
            if(diligentPayloads.size() <= 100){//Use Queueable for records <= 100
                system.enqueueJob(new DiligentSearchProcessor(diligentPayloads));
            }else{//otherwise use batch apex to avoid hitting callout governor limit of 100
                Database.executeBatch(new DiligentSearchBatch(diligentPayloads), 100);
            }
        }        
    }
    
    //Queueable method
    public void execute(system.QueueableContext ctx){
        updatedDiligentPayloadList.addAll(DiligentCalloutHelper.processDiligentSearchPayload(diligentPayloadList, 'search'));
        if(!updatedDiligentPayloadList.isEmpty() && !Test.isRunningTest() ){
            system.enqueueJob(new DiligentSearchStatusProcessor(updatedDiligentPayloadList), 1);//Call another Queueable job after 1 minute to get search status
        }
    }
   
    //Helper Diligent Payload Class
    public class DiligentPayload{
        @InvocableVariable(required=true)
        public string term;
        
        @InvocableVariable(required=true)
        public string accountId;
        
        @InvocableVariable(required=true)
        public string recordType;
        
        @InvocableVariable
        public string country;
        
        public integer search_id;
        
        public string status;
        
        public string responseBody;
        
        public integer term_id;
        
        public integer list_id;
    }
    
}
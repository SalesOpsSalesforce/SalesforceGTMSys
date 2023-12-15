public class OpportunityProductDeleteController {
    public static OpportunityLineItem oli{get; set;}
    public static String opportunityId{get; set;}
    public OpportunityProductDeleteController(ApexPages.StandardController stdController){
        oli = (OpportunityLineItem)stdController.getRecord();
        OpportunityLineItem oLIRecord = [Select Id, OpportunityId From OpportunityLineItem Where Id =: oli.Id];
        if(oLIRecord != null)
            opportunityId = oLIRecord.OpportunityId;
    }
    
    public static void checkUserProfile(){
        List<String> listOfProfiles = System.Label.Profile_Allowed_For_OLI_Deletion.split(',');
        Map<Id, Profile> mapOfProfileRecord = new Map<Id, Profile>([Select Id From Profile Where Name In: listOfProfiles]); //Primary Salesforce Admin
        OpportunityLineItem oLIRecord = [Select Id, OpportunityId From OpportunityLineItem Where Id =: oli.Id];
        opportunityId = oLIRecord.OpportunityId;
        if(mapOfProfileRecord.containsKey(UserInfo.getProfileId())){
            delete oli;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Opportunity Product has been deleted successfully.'));
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Your profile does not have the access to delete OLIs. Reach out to Salesforce Administrator.'));
        }
    }
    
    public static PageReference Close(){
        opportunityId = Apexpages.currentPage().getParameters().get('id');
        OpportunityLineItem oLIRecord = [Select Id, OpportunityId From OpportunityLineItem Where Id =: opportunityId All Rows];
        opportunityId = oLIRecord.OpportunityId;
        PageReference pr = new PageReference('/lightning/r/Opportunity/' + opportunityId + '/view');
        pr.setRedirect(true);
        return pr;
    }
}
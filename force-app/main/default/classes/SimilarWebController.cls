public class SimilarWebController {
    Id accountId;
    public SimilarWebController(ApexPages.StandardController stdController) {
        this.accountId = ApexPages.CurrentPage().getparameters().get('id');
    }
    
    public PageReference fetchSimilarWebMetrics(){
        List<sObject>recordList = (List<sObject>)[Select id, Clean_Website__c from Account where id =:accountId];
        SimilarWebCallouts.processSimilarWebCallouts(recordList, false);
        return new PageReference('/'+accountId);
    }
}
//[RGaokar 3/10/2023 SFDC-2132 Failed Diligent Callout Processing Weekly Job]
public class DiligentFailureHandlingBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    private String query;
    public DiligentFailureHandlingBatch(String query){//Pass the custom query from Anonymous window to run this batch Example: Select id,name,Clean_Website__c,BillingCountry,recordtype.DeveloperName,Legal_Business_Name__c from account where .....
        this.query = query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        if(this.query == null){
            this.query = 'Select id,name,Clean_Website__c,BillingCountry,recordtype.DeveloperName,Legal_Business_Name__c from account where Diligent_Search_Failed__c = true';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        List<Account> updatedAccList = new List<Account>();
        List<DiligentSearchProcessor.DiligentPayload>diligentPayloads = new List<DiligentSearchProcessor.DiligentPayload>();
        for(Account a:(List<account>)scope){
            updatedAccList.add(new account(id = a.id, Diligent_Search_Failed__c = false));//reset the failed flag to false
            DiligentSearchProcessor.DiligentPayload payload = new DiligentSearchProcessor.DiligentPayload();
            payload.accountId = a.id;
            payload.country = a.BillingCountry;
            payload.recordType = a.RecordType.DeveloperName;
            if(a.RecordType.DeveloperName == 'Klaviyo_Account'){
                payload.term = a.Clean_Website__c;
            }else if(a.RecordType.DeveloperName == 'Referral_Partner_Account' && string.isNotBlank(a.Legal_Business_Name__c)){
                payload.term = a.Legal_Business_Name__c;
            }else if(a.RecordType.DeveloperName == 'Referral_Partner_Account' && string.isBlank(a.Legal_Business_Name__c)){
                payload.term = a.name;
            }
            diligentPayloads.add(payload);
        }
        
        List<Database.SaveResult> srList = Database.update(updatedAccList, false);
        DiligentSearchProcessor.getDiligentSearchTerms(diligentPayloads);
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
}
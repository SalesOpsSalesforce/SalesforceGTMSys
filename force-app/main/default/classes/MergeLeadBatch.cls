public class MergeLeadBatch implements Database.Batchable<sObject>{
    
    private Set<Id> mergeLeadIds;
    public MergeLeadBatch(Set<Id> leadIds){
        this.mergeLeadIds = leadIds;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String fields = 'Id,OwnerId,Matched_Lead__c,LeadSource,MARKETING_Most_Recent_Lead_Source_Detail__c, MostRecentCampaignID__c,MARKETING_utm_Content_Last__c,';
        fields += 'MARKETING_utm_Medium_Last__c,MARKETING_utm_Source_Last__c,MARKETING_utm_Term_Last__c,PRODUCT_DateTime_Free_Account_Creation__c,';
        fields += 'PRODUCT_Date_Time_of_Last_Demo_Request__c,Lead_Assignment_Type__c,Klaviyo_Account_ID__c,Phone,MARKETING_utm_Campaign_Last__c,';
        fields += 'Matched_Lead__r.owner.IsActive, Matched_Lead__r.CreatedDate';
        String query = 'Select '+ fields +' from Lead where Id in :mergeLeadIds';
        return Database.getQueryLocator(query); 
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        for (Lead l:(List<Lead>)scope){
            Lead masterLead = new Lead();
            masterLead.id = l.Matched_Lead__c;            
            if(String.IsNotBlank(l.LeadSource))masterLead.LeadSource = l.LeadSource;
            if(String.IsNotBlank(l.MARKETING_Most_Recent_Lead_Source_Detail__c)) masterLead.MARKETING_Most_Recent_Lead_Source_Detail__c = l.MARKETING_Most_Recent_Lead_Source_Detail__c;
            if(l.MostRecentCampaignID__c != null) masterLead.MostRecentCampaignID__c = l.MostRecentCampaignID__c;
            if(String.IsNotBlank(l.MARKETING_utm_Campaign_Last__c)) masterLead.MARKETING_utm_Campaign_Last__c = l.MARKETING_utm_Campaign_Last__c;
            if(String.IsNotBlank(l.MARKETING_utm_Content_Last__c)) masterLead.MARKETING_utm_Content_Last__c = l.MARKETING_utm_Content_Last__c;
            if(String.IsNotBlank(l.MARKETING_utm_Medium_Last__c)) masterLead.MARKETING_utm_Medium_Last__c = l.MARKETING_utm_Medium_Last__c;
            if(String.IsNotBlank(l.MARKETING_utm_Source_Last__c)) masterLead.MARKETING_utm_Source_Last__c = l.MARKETING_utm_Source_Last__c;
            if(String.IsNotBlank(l.MARKETING_utm_Term_Last__c)) masterLead.MARKETING_utm_Term_Last__c = l.MARKETING_utm_Term_Last__c;
            if(l.PRODUCT_DateTime_Free_Account_Creation__c != null) masterLead.PRODUCT_DateTime_Free_Account_Creation__c = l.PRODUCT_DateTime_Free_Account_Creation__c;
            if(l.PRODUCT_Date_Time_of_Last_Demo_Request__c != null) masterLead.PRODUCT_Date_Time_of_Last_Demo_Request__c = l.PRODUCT_Date_Time_of_Last_Demo_Request__c;
            if(String.IsNotBlank(l.Lead_Assignment_Type__c)) masterLead.Lead_Assignment_Type__c = l.Lead_Assignment_Type__c;
            if(String.IsNotBlank(l.Klaviyo_Account_ID__c)) masterLead.Klaviyo_Account_ID__c = l.Klaviyo_Account_ID__c;
            if(l.Phone != null) masterLead.SALES_Secondary_Phone__c = l.Phone;
            if(l.Lead_Assignment_Type__c == 'Matching Lead'){
                //[RGaokar 04/19/2022 TP #118577] Recently created master lead withing 24 hours (1 day) of span should not re-route to another owner due to duplicate lead merging.
                if(l.Matched_Lead__r.CreatedDate < Datetime.now().addHours(-24)){
                   masterLead.Lead_Route__c = true; 
                }
                masterLead.status = 'Untouched';
                masterLead.SALES_Disqualification_Reason__c = '';
                masterLead.New_Agency__c = '';
            }
            if(l.Matched_Lead__r.owner.IsActive == false){
                masterLead.OwnerId = l.OwnerId;
            }
    
            //Merge Operation
            Database.MergeResult result = Database.merge(masterLead, l.Id, false);
            
            //Catch error if any
            if(!result.isSuccess()){
                List <String> executionFlow = new List <String> ();
                String errorString;
                for(Database.Error err : result.getErrors()) {
                    errorString =+ err.getMessage()+'\n';
                }
                system.debug('errorString--'+errorString);
                executionFlow.add('Following error occured when merging new lead '+l.Id+ ' with existing lead '+masterLead.Id+': '+errorString);
                ExceptionHandling.performExceptionHandling(null, 'MergeLeadBatch', executionFlow);
            }
        }     
    }
    
    public void finish (Database.BatchableContext bc){
        
    }
    
}
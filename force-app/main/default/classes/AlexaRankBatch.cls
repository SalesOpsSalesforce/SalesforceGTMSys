public class AlexaRankBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    //[RGaokar 11/23/2021 TP #94326, TP #90961] Alexa Rank Update
    // This class is for Alexa rank update by sending callout to FREE API ENDPOINT 
    // This class is used as helper class for any object trigger method for alexa rank update
    // Method is defined in batch context for asynchronous processing with batch size of 50 to avoid hitting the governor limits of 100 callouts
    // 50 batch size is used to avaoid IP blocking due large records (max 100 batch size) hitting continuously to free endpoint
    //Code Coverage classes: LeadTriggerHandlerTest and AccountTriggerHandlerTest
    public string sObjectType;
    public Set<Id> sObjectIds;
    public AlexaRankBatch(Set<Id> sObjectIds, String sObjectType){
        this.sObjectIds = sObjectIds;
        this.sObjectType = sObjectType;
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'Select Id, Website from '+ this.sObjectType +' where Id in :sObjectIds';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        try{
            List<sObject> sObjectUpdateList = new List<sObject>();
            for(sobject obj:scope){
                String url = string.valueOf(obj.get('Website'));
                if(GeneralUtils.isValidUrl(url)){
                    system.debug('URL is valid');
                    Double alexaRank = AlexaRankCallout.getAlexaRank(url);
                    if(this.sObjectType == 'Account'){
                        obj.put(Schema.Account.etailinsights_Alexa_Rank__c,alexaRank);
                        obj.put(Schema.Account.Alexa_Rank_at_Last_Owner_Change__c,alexaRank);
                    }else if (this.sObjectType == 'Lead'){
                        obj.put(Schema.Lead.Alexa_Rank__c,alexaRank);
                    }    
                }else if(!GeneralUtils.isValidUrl(url) && this.sObjectType == 'Account'){
                    obj.put(Schema.Account.etailinsights_Alexa_Rank__c,null);
                }else if(!GeneralUtils.isValidUrl(url) && this.sObjectType == 'Lead'){
                    obj.put(Schema.Lead.Alexa_Rank__c,null); 
                }
                sObjectUpdateList.add(obj);
            }
            if(sObjectUpdateList.size() > 0){
                update sObjectUpdateList;
            }   
        }
        catch(Exception ex){
            List <String> executionFlow = new List <String> ();
            executionFlow.add('Error occured for '+this.sObjectType+ ' records: '+scope);
            ExceptionHandling.performExceptionHandling(ex, 'AlexaRankBatch', executionFlow);       
        } 
        
    }
    
    public void finish(Database.BatchableContext bc){
        
        
    }
}
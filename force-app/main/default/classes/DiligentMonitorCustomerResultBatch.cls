//[RGaokar 3/24/2023 SFDC-2030 Diligent <> SFDC Retrieved Monitor Term Results for Annual Refresh]
//API: Retrieve Monitor Results for a Term https://search.transparint.com/api/v1/monitor_term_results
public class DiligentMonitorCustomerResultBatch implements Database.Batchable<sObject>, Database.allowscallouts{
    private string query;
    public DiligentMonitorCustomerResultBatch(string query){//Pass custom query if needed
        this.query = query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        if(query == null){
            this.query = 'Select id, Diligent_List_Id__c, Diligent_Term_Id__c from Account';
            this.query += ' where Diligent_Term_Id__c != null AND recordtype.developername = \'Klaviyo_Account\'';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        //Retrieve Term Result for Customer Monitored List
        DiligentCalloutHelper.processMonitorTermsResult((List<Account>)scope); 
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
}
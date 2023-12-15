//[RGaokar 3/24/2023 SFDC-2030 Diligent <> SFDC Retrieved Monitor Term Results for Annual Refresh]
//API: Retrieve Monitor Results for a Term https://search.transparint.com/api/v1/monitor_term_results
public class DiligentMonitorPartnerResultBatch implements Database.Batchable<sObject>, Database.allowscallouts{
    private string query;
    private Boolean runCustomerSearch;
    public DiligentMonitorPartnerResultBatch(string query, Boolean runCustomerSearch){//Pass custom query if needed, set runCustomerSearch = false if dont want to run customer result batch. Also where Diligent_Term_Id__c != null condition is must for custom query
        this.query = query;
        this.runCustomerSearch = runCustomerSearch;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        if(query == null){
            this.query = 'Select id, Diligent_List_Id__c, Diligent_Term_Id__c from Account';
            this.query += ' where Diligent_Term_Id__c != null AND recordtype.developername = \'Referral_Partner_Account\'';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        //Retrieve Terms Results for Partner Monitored List
        DiligentCalloutHelper.processMonitorTermsResult((List<Account>)scope); 
    }
    
    public void finish(Database.BatchableContext bc){
        if(this.runCustomerSearch){
            //Retrieve Term Result for Customer Monitored List
            DiligentMonitorCustomerResultBatch customerRIDBatch = new DiligentMonitorCustomerResultBatch(null);
        	Database.executeBatch(customerRIDBatch, 100);//Diligent api rate limit is 100 api calls/minute  
        }
        
    }
    
    
}
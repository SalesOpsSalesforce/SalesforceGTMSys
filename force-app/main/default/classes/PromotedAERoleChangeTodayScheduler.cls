//[RGaokar 07/28/2023 SFDC-3216 Move Previous New Business Territory Accounts WITHOUT Open Opportunities 
//to previous manager on role change effective date]
public class PromotedAERoleChangeTodayScheduler implements Schedulable {
    public void execute(SchedulableContext sc){
        manualRun();   
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    public static void manualRun(){ 
        map<id, Sales_Ops_Request__c>repIdRoleChangeTodayRequestMap = new map<id, Sales_Ops_Request__c>();
        
        //Get all completed Role change requests with role change effective date today
        List<Sales_Ops_Request__c> roleChangeTodayrequests = [Select id, Sales_Rep__c,Previous_Manager__c, Role_Change_to__c from Sales_Ops_Request__c
                                                              where recordtype.DeveloperName = 'Role_Change' AND Request_Status__c = 'Completed'
                                                              AND Previous_Manager__c != null AND Role_Change_Effective_Date__c = Today
                                                              AND (Role_Change_to__c LIKE '%U SMB AE%' OR Role_Change_to__c LIKE '%MM AE%')];
        
        for(Sales_Ops_Request__c req:roleChangeTodayrequests){
            repIdRoleChangeTodayRequestMap.put(req.Sales_Rep__c, req); 
        }
        
        //Call batch job to get accounts (w/o opportunities)owned by promoted rep
        PromotedAERoleChangeTodayOwnerUpdate roleChangeTodayAccountOwnerUpdateBatch = new PromotedAERoleChangeTodayOwnerUpdate(repIdRoleChangeTodayRequestMap);
        Database.executeBatch(roleChangeTodayAccountOwnerUpdateBatch, 50);//Update 50 Accounts at a time 
    } 
}
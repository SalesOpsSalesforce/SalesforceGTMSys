//[RGaokar 07/11/2023 SFDC-2836 Move Previous New Business Territory Accounts with Open Opportunities 
//and the related Open Opportunities after promotion period to previous manager]
public class PromotedAEAccountOppOwnerUpdateScheduler implements Schedulable {
    public void execute(SchedulableContext sc){
        manualRun();   
    }
    
    // ========== Manually runnable functions
    // use this method to run this from an Execute Anonymous Window
    public static void manualRun(){
        map<id, Sales_Ops_Request__c>salesRepIdRequestMap = new map<id, Sales_Ops_Request__c>();
        Date USMBHoldOver = date.today().adddays(-90);
        Date MMHoldOver = date.today().adddays(-120);
        List<Sales_Ops_Request__c> requests = [Select id, Sales_Rep__c,Previous_Manager__c, Role_Change_to__c from Sales_Ops_Request__c
                                               where recordtype.DeveloperName = 'Role_Change' AND Request_Status__c = 'Completed'
                                               AND Previous_Manager__c != null
                                               AND ((Role_Change_to__c LIKE '%U SMB AE%' AND Role_Change_Effective_Date__c = :USMBHoldOver) OR (Role_Change_to__c LIKE '%MM AE%' AND Role_Change_Effective_Date__c = :MMHoldOver))];
        
        for(Sales_Ops_Request__c req:requests){
            salesRepIdRequestMap.put(req.Sales_Rep__c, req); 
        }
        
        //Call batch job to get accounts owned by promoted rep
        PromotedAEAccountOwnerUpdateBatch accountOwnerUpdateBatch = new PromotedAEAccountOwnerUpdateBatch(salesRepIdRequestMap);
        Database.executeBatch(accountOwnerUpdateBatch, 50);//Update 50 Accounts at a time
    }
}
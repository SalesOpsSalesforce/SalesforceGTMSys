public class PartnerApplicationTriggerHandler extends TriggerHandler{
    @TestVisible private static Boolean isFirstTimeInsert = true;
    @TestVisible private static Boolean isFirstTimeUpdate = true;
    
    @TestVisible private List<Partner_Application__c> triggerNew = (List<Partner_Application__c>) Trigger.new;
    @TestVisible private List<Partner_Application__c> triggerOld = (List<Partner_Application__c>) Trigger.old;
    @TestVisible private Map<Id, Partner_Application__c> triggerNewmap = (Map<Id, Partner_Application__c>) Trigger.newMap;
    @TestVisible private Map<Id, Partner_Application__c> triggerOldmap = (Map<Id, Partner_Application__c>) Trigger.oldMap;
    
    // ----------- OVERRIDE METHODS ----------------
    
    public override void beforeInsert() {
        
                
     } 
    
    public override void beforeUpdate() {
        
                
    }
     public override void afterInsert() {
        LeanData.LeanDataAPI.triggerRouting();
                
    }
     public override void afterUpdate() {
        LeanData.LeanDataAPI.triggerRouting();
                
    }
}
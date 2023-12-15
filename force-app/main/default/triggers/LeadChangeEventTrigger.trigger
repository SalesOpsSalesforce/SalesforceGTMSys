//[RGaokar 11/03/2022 SFDC - 1157 SF to Redpoint Lead Changes Trigger]
trigger LeadChangeEventTrigger on LeadChangeEvent (after insert) {
    Boolean isTriggerDisabled = Redpoint_K4K_Disablement_Switch__mdt.getInstance('Redpoint_K4K').Lead_Sync_Disabled__c;
    
    //If Redpoint K4K sync for Lead is not disabled then send changes to handler class for further processing
    if(!isTriggerDisabled){
        LeadChangeEventTriggerHandler.redpointLeadSync(Trigger.new);
    }
}
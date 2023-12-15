//[RGaokar 11/03/2022 SFDC - 1157 SF to Redpoint Contact Changes Trigger]
trigger ContactChangeEventTrigger on ContactChangeEvent (after insert) {
    Boolean isTriggerDisabled = Redpoint_K4K_Disablement_Switch__mdt.getInstance('Redpoint_K4K').Contact_Sync_Disabled__c;
    
    //If Redpoint K4K sync for contact is not disabled then send changes to handler class for further processing
    if(!isTriggerDisabled){
        ContactChangeEventTriggerHandler.redpointContactSync(Trigger.new);
    } 
}
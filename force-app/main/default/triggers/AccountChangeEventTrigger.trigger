//[RGaokar 11/03/2022 SFDC - 1157 SF to Redpoint Account Changes Trigger]
trigger AccountChangeEventTrigger on AccountChangeEvent (after insert) {
    Boolean isTriggerDisabled = Redpoint_K4K_Disablement_Switch__mdt.getInstance('Redpoint_K4K').Account_Sync_Disabled__c;
    
    //If Redpoint K4K sync for account is not disabled then send changes to handler class for further processing
    if(!isTriggerDisabled){
       AccountChangeEventTriggerHandler.redpointAccountSync(Trigger.new); 
    }
}
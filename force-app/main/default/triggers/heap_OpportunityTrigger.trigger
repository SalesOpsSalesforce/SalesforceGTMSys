trigger heap_OpportunityTrigger on Opportunity (after insert, after update) {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    /*if (System.isBatch()) return;
    heap_Opportunities opportunities = new heap_Opportunities((List<SObject>)Trigger.new);
    heap_Calls calls = opportunities.handleTrigger(new heap_Calls(), Trigger.isInsert, Trigger.isUpdate, Trigger.oldMap);
    if (!Test.isRunningTest()) calls.call();*/
}
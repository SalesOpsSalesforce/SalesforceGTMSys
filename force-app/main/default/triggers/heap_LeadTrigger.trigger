trigger heap_LeadTrigger on Lead (after insert, after update) {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    /*if (System.isBatch()) return;
    heap_Leads leads = new heap_Leads((List<SObject>)Trigger.new);
    heap_Calls calls = leads.handleTrigger(new heap_Calls(), Trigger.isInsert, Trigger.isUpdate, Trigger.oldMap);
    if (!Test.isRunningTest()) calls.call();*/
}
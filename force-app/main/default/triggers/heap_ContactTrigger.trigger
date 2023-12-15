trigger heap_ContactTrigger on Contact (after insert, after update) {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
   /* if (System.isBatch()) return;
    heap_Contacts contacts = new heap_Contacts((List<SObject>)Trigger.new);
    heap_Calls calls = contacts.handleTrigger(new heap_Calls(), Trigger.isInsert, Trigger.isUpdate, Trigger.oldMap);
    if (!Test.isRunningTest()) calls.call();*/
}
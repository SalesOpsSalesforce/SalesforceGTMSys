global class heap_scheduledBackload implements Schedulable {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    global void execute(SchedulableContext ctx) {
       /* Database.executeBatch(new heap_schedulableBackload('Contact'), 10);
        Database.executeBatch(new heap_schedulableBackload('Account'), 10);
        Database.executeBatch(new heap_schedulableBackload('Opportunity'), 10);
        Database.executeBatch(new heap_schedulableBackload('Lead'), 10);*/
    }
}
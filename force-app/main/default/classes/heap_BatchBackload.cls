global class heap_BatchBackload implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration 
    String query;
   /* Type backfillType;

    public heap_Base classForBackfill;

    public class HeapBackloadException extends Exception {}

    public heap_BatchBackload(String objectStr) {
        try {
            backfillType = Type.forName(objectStr);
            classForBackfill = (heap_Base)backfillType.newInstance();
            DescribeSObjectResult describeResult = ((SObject)classForBackfill.getObjectType().newInstance()).getSObjectType().getDescribe();
            List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
            // TODO query stuff should be found in the class
            query =
              ' SELECT ' +
                  String.join( fieldNames, ', ' ) +
              ' FROM ' +
                  describeResult.getName();
        } catch (Exception e) {
            throw new HeapBackloadException(objectStr + ' is not a valid backload type.');
        }
    }*/

    global Database.QueryLocator start(Database.BatchableContext ctx) {
        //return Database.getQueryLocator(query);
        return Database.getQueryLocator('Select id, name from account where name = \'Test-SOWCatherine\'');//passing test account to avoid null error
    }

    global void execute(Database.BatchableContext BC, List<sObject>scope) {
       /* classForBackfill = (heap_Base)backfillType.newInstance();
        classForBackfill.records = scope;
        classForBackfill.bulkBackload().backloadCall();*/
    }

    global void finish(Database.BatchableContext ctx) {}
}
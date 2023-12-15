global class heap_BatchUserProperties implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration 
    String query;
    /*Type propertyClass;
    List<String> identities;
    heap_Calls calls;

    public heap_IUserPropertySource propertySource;

    public class HeapUserPropertyException extends Exception {}

    public void setCalls(heap_Calls c) {
        this.calls = c;
    }

    public heap_BatchUserProperties(List<String> identitiesParam, Type propertyClassParam) {
            identities = identitiesParam;
            propertyClass = propertyClassParam;

            heap_IUserPropertySource userPropertySource = (heap_IUserPropertySource)propertyClass.newInstance();
            query = userPropertySource.hydrationQuery(identities);
            calls = new heap_Calls();
    }*/

    global Database.QueryLocator start(Database.BatchableContext ctx) {
        //return Database.getQueryLocator(query);
        return Database.getQueryLocator('Select id, name from account where name = \'Test-SOWCatherine\'');//passing test account to avoid null error
    }

    global void execute(Database.BatchableContext BC, List<sObject>scope) {
       /* propertySource = (heap_IUserPropertySource)propertyClass.newInstance();
        propertySource.hydrateFromQueryResults(scope);
        propertySource.addUserProperties(calls);
        calls.call();*/
    }

    global void finish(Database.BatchableContext ctx) {}
}
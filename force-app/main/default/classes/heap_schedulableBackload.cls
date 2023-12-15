global class heap_schedulableBackload implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    String query;
    /*Type backfillType;
    public heap_Base classForBackfill;*/

    /*public heap_schedulableBackload(String objectName) {
        Map<String, String> classToDomain = new Map<String, String>{
               'Account' => 'heap_Accounts',
               'Contact' => 'heap_Contacts',
               'Opportunity' => 'heap_Opportunities',
               'Lead' => 'heap_Leads'
        };
        backfillType = Type.forName(classToDomain.get(objectName));
        classForBackfill = (heap_Base)backfillType.newInstance();
        ObjectFieldMappings ofMappings = new ObjectFieldMappings();
        String objectQueryString = ofMappings.queryString(objectName);
        if (objectName == 'Contact' && !ofMappings.containsField(objectName, 'Email')){
            objectQueryString += ', Email';
        }
        if (objectName != 'Account' && objectName != 'Lead' && !ofMappings.containsField(objectName, 'AccountId')){
            objectQueryString += ', AccountId';
        }
        if (objectName == 'Lead' && !ofMappings.containsField(objectName, 'Email')){
            objectQueryString += ', Email';
        }
        if (!ofMappings.containsField(objectName, 'OwnerId')){
            objectQueryString += ', OwnerId';
        }
        query = 'SELECT ' + objectQueryString +
                ' FROM ' + objectName +
                ' WHERE SystemModstamp >= Yesterday';
    }*/

    global Database.QueryLocator start(Database.BatchableContext ctx) {
        //return Database.getQueryLocator(query);
        return Database.getQueryLocator('Select id, name from account where name = \'Test-SOWCatherine\'');//passing test account to avoid null error
    }

    global void execute(Database.BatchableContext BC, List<sObject>scope) {
       /* heap_Calls calls = new heap_Calls();
        classForBackfill = (heap_Base)backfillType.newInstance();
        classForBackfill.records = scope;
        classForBackfill.addUserProperties(calls);
        calls.backloadCall();*/
    }

    global void finish(Database.BatchableContext ctx) {}
}
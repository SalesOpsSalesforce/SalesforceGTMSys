public with sharing class heap_Leads extends heap_Base implements heap_IUserPropertySource {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_Leads(){}
    public override void addUserProperties(){
    }
    /*public List<SObjectField> leadFields;

    public heap_Leads(List<SObject> leads) {
        records = leads;
    }

    public heap_Leads() {
        records = new List<SObject>();
    }

    public override Type getObjectType(){
        return Lead.class;
    }

    public override void addUserProperties(heap_Calls calls){
        for (Lead newLead: (List<Lead>)records) {
            String identity = getIdentity(newLead);
            if (null != identity) {
                Map<String, Object> userProperties = getPropertyValues(newLead, new Lead());
                calls.addProperties(identity, userProperties);
            }
        }
    }

    public void hydrateFromIdentities(List<String> identities){
        hydrateFromQueryResults(Database.query(hydrationQuery(identities)));
    }

    public void hydrateFromQueryResults(List<SObject> results) {
        records.addAll((List<SObject>)results);
    }

    public String hydrationQuery(List<String> identities) {
        ObjectFieldMappings tempOfMappings = new ObjectFieldMappings();
        List<String> requiredQueryColumns = new List<String>{
            heap_Configuration.heapSettings.LeadIdentity__c,
            'LastModifiedDate',
            'OwnerId'
        };

        for (String queryColumn: requiredQueryColumns) {
            if (!tempOfMappings.containsField(getObjectType().getName(), queryColumn)){
                tempOfMappings.objectToFieldMapping.get(getObjectType().getName()).add(
                        new ObjectFieldMapping(new heap_ObjectFieldMapping__c(Field__c=queryColumn, IsReference__c=False))
                );
            }
        }

        return 'SELECT ' + tempOfMappings.queryString(getObjectType().getName()) +
                ' FROM Lead ' +
                ' WHERE ' + heap_Configuration.heapSettings.LeadIdentity__c + ' IN :identities';
    }

    public override List<String> getIdentities(){
        List<String> identities = new List<String>();
        for (Lead l : (List<Lead>)records) {
            String identity = getIdentity(l);
            if (null == identity) continue;
            identities.add(identity);
        }
        return identities;
    }

    public override List<String> getIdentities(SObject record){
        List<String> toRet = new List<String>();
        String identity = getIdentity(record);
        if (null != identity) {
            toRet.add(identity);
        }
        return toRet;
    }

    public List<List<LeadHistory>> groupHistoriesByDate(List<LeadHistory> leadHistories) {
        Map<String, List<LeadHistory>> historiesByDate = new Map<String, List<LeadHistory>>();
        for (LeadHistory history : leadHistories) {
            String key = String.valueOf(history.Id) + String.valueOf(history.CreatedDate);
            if (historiesByDate.containsKey(key)) {
                historiesByDate.get(key).add(history);
            } else {
                historiesByDate.put(key, new List<LeadHistory>{history});
            }
        }
        return historiesByDate.values();
    }

    public Map<Id, List<List<LeadHistory>>> historiesByLeadId {
        get {
            if (null == historiesByLeadId) {
                historiesByLeadId = new Map<Id, List<List<LeadHistory>>>();
                List<Id> recordIds = new List<id> (getIds());
                List<LeadHistory> histories = db.getSObjects(LeadHistory.getSObjectType(), 'LeadId', recordIds);
                for (SObject record: records) {
                    // TODO Stupid n^2 thing - asking for a FATAL_ERROR System.LimitException: Apex CPU time limit exceeded
                    List<LeadHistory> myHistories = new List<LeadHistory>();
                    for (LeadHistory history: histories) {
                        if (history.LeadId == record.get('Id')) {
                            myHistories.add(history);
                        }
                    }
                    historiesByLeadId.put(record.Id, groupHistoriesByDate(myHistories));
                }
            }
            return historiesByLeadId;
        } public set ;
    }

    public override heap_Calls bulkBackload() {
        heap_Calls calls = new heap_Calls();
        // :TODO: (talos): this appears to make one query for lead histories per lead record, but that query is for all lead histories each time
        for (SObject record: records) {
            List<List<LeadHistory>> historiesGroupedByTime = historiesByLeadId.get(record.Id);
            for (List<LeadHistory> histories : historiesGroupedByTime) {
                SObject oldRecord = new Lead(Id = (Id) record.get('Id'));
                SObject newRecord = oldRecord.clone(true, true, false, false);
                // Loop through the records that have the same CreatedDate and reconstruct the Lead changes at that time
                for (LeadHistory history: histories) {
                    String field = (String) history.get('Field');
                    // check that it's a valid field. Histories can have a field that isn't a valid Lead SObjectField
                    if (Lead.getSObjectType().getDescribe().fields.getMap().keySet().contains(field.toLowerCase())) {
                        try {
                            oldRecord.put(field, history.get('OldValue'));
                            newRecord.put(field, history.get('NewValue'));
                        } catch (Exception e) {
                            continue;
                        }
                    }
                }
                handleSingleChange(newRecord, oldRecord, (String) record.get('Email'), calls, (DateTime) histories.get(0).get('CreatedDate'));
            }
        }
        addUserProperties(calls);
        return calls;
    }*/
}
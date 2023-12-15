public with sharing class heap_Opportunities extends heap_Base implements heap_IUserPropertySource {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_Opportunities(){}
    public override void addUserProperties(){
    }
   /* public heap_Opportunities(List<SObject> opportunities) {
        records = opportunities;
    }

    public heap_Opportunities() {
        records = new List<SObject>();
    }

    public override Type getObjectType(){
        return Opportunity.class;
    }

    public Map<Id, List<Opportunity>> opportunitiesByAccountId {
        get {
            if (null == opportunitiesByAccountId) {
                opportunitiesByAccountId = new Map<Id, List<Opportunity>>();
                for(SObject opportunityEntry: records) {
                    Id opportunityAccountId = (Id)opportunityEntry.get(Opportunity.AccountId);
                    if (opportunitiesByAccountId.containsKey(opportunityAccountId)) {
                        opportunitiesByAccountId.get(opportunityAccountId).add((Opportunity)OpportunityEntry);
                    } else {
                        opportunitiesByAccountId.put(
                                opportunityAccountId,
                                new List<Opportunity>{(Opportunity)opportunityEntry}
                        );
                    }
                }
            }
            return opportunitiesByAccountId;
        }
        public set; // TODO only allow this in testing
    }

    public Map<Id, List<OpportunityHistory>> opportunityHistoriesByOpportunityId {
        get {
            if (null == opportunityHistoriesByOpportunityId) {
                opportunityHistoriesByOpportunityId = new Map<Id, List<OpportunityHistory>>();
                for(SObject opportunityHistoryEntry: db.getSObjects(OpportunityHistory.getSObjectType(), 'OpportunityId', new List<Id>(getIds()))) {
                    Id opportunityAccountId = (Id)opportunityHistoryEntry.get(OpportunityHistory.OpportunityId);
                    if (opportunityHistoriesByOpportunityId.containsKey(opportunityAccountId)) {
                        opportunityHistoriesByOpportunityId.get(opportunityAccountId).add((OpportunityHistory)opportunityHistoryEntry);
                    } else {
                        opportunityHistoriesByOpportunityId.put(
                                opportunityAccountId,
                                new List<OpportunityHistory>{(OpportunityHistory)opportunityHistoryEntry}
                        );
                    }
                }
            }
            return opportunityHistoriesByOpportunityId;
        }
        public set; // TODO only allow this in testing
    }

    public List<Contact> contacts {
        get {
            if (null == contacts) {
                contacts = [
                        SELECT Id, AccountId, Email, Name
                        FROM Contact
                        WHERE AccountId IN :getIds('AccountId')
                ];
            }
            return contacts;
        }
        public set; // TODO only allow this in testing
    }

    Opportunity getMaxOppByAggregator(List<Opportunity> opportunities) {
        String aggregatorField = heap_Configuration.heapSettings.OpportunityAggregator__c;
        Opportunity best = null;
        for (Opportunity possible: opportunities) {
            if ( (null == best) || SupportedFieldTypes.compareObjects(possible, best, aggregatorField) ) {
                best = possible;
            }
        }
        return best;
    }

    public override void addUserProperties(heap_Calls calls){
        for(Id accountId: opportunitiesByAccountId.keySet()) {
            Opportunity newestOpportunity = getMaxOppByAggregator(opportunitiesByAccountId.get(accountId));
            List<String> identities = new List<String>();
            for (Contact identityContact: contactsByAccountId.get(accountId)) {
                String identity = getIdentity(identityContact);
                if (null != identity) {
                    identities.add(String.valueOf(identity));
                }
            }
            if (newestOpportunity != null) {
                Map<String, Object> userProperties = new Map<String, Object>();
                if (objectFields.containsKey(getObjectType().getName())){
                    for (ObjectFieldMapping ofm : objectFields.get(getObjectType().getName()) ){
                        if (ofm.IsReference){
                            SObject referenceFieldsObject = relationFieldsById.get(newestOpportunity.Id);
                            SObject referenceObject = referenceFieldsObject.getSObject(ofm.record.ReferenceRelationshipName__c);
                            // if the reference object field is null, the reference object will also return null
                            if (null != referenceObject){
                                userProperties.put(ofm.getLabel(), String.valueOf(referenceObject.get(ofm.record.ReferenceObjectField__c)));
                            }
                        } else {
                            userProperties.put(ofm.getLabel(), String.valueOf(newestOpportunity.get(ofm.record.Field__c)));
                        }
                    }
                }
                calls.addProperties(identities, userProperties);
            }
        }
    }


    public void hydrateFromIdentities(List<String> identities) {
        String queryString = hydrationQuery(identities);
        hydrateFromQueryResults(Database.query(queryString));
    }

    public void hydrateFromQueryResults(List<SObject> results) {
        for (Account accountEntry: (List<Account>)results) {
            // using a SOQLfor loop because results >250 will throw an error
            for (SObject sObj : accountEntry.Opportunities) {
                records.add(sObj);
            }
            for (Contact c : accountEntry.Contacts){
                contacts.add(c);
            }
        }
    }

    public String hydrationQuery(List<String> identities) {
        ObjectFieldMappings tempOfMappings = new ObjectFieldMappings();
        if (!tempOfMappings.containsField(getObjectType().getName(), 'CloseDate')){
            tempOfMappings.objectToFieldMapping.get(getObjectType().getName()).add(
                    new ObjectFieldMapping(new heap_ObjectFieldMapping__c(Field__c='CloseDate', IsReference__c=False))
            );
        }

        if (!tempOfMappings.containsField(getObjectType().getName(), 'AccountId')){
            tempOfMappings.objectToFieldMapping.get(getObjectType().getName()).add(
                    new ObjectFieldMapping(new heap_ObjectFieldMapping__c(Field__c='AccountId', IsReference__c=False))
            );
        }

        if (!tempOfMappings.containsField(getObjectType().getName(), heap_Configuration.heapSettings.OpportunityAggregator__c)){
            tempOfMappings.objectToFieldMapping.get(getObjectType().getName()).add(
                    new ObjectFieldMapping(new heap_ObjectFieldMapping__c(Field__c=heap_Configuration.heapSettings.OpportunityAggregator__c, IsReference__c=False))
            );
        }

        String objectQueryString = tempOfMappings.queryString(getObjectType().getName());

        String queryString = 'SELECT Id, Name, ' +
                '(SELECT AccountId, ' + heap_Configuration.heapSettings.ContactIdentity__c + ' FROM Contacts), ' +
                '(SELECT ' + objectQueryString + ' FROM Opportunities) ' +
                'FROM Account ' +
                'WHERE Id in ' +
                '(Select AccountId from Contact WHERE ' + heap_Configuration.heapSettings.ContactIdentity__c + ' IN :identities)';
        return queryString;
    }

    public Map<Id, List<Contact>> contactsByAccountId {
        get {
            if (null == contactsByAccountId) {
                contactsByAccountId = new Map<Id, List<Contact>>();
                for(Contact contactEntry: contacts) {
                    Id contactAccountId = (Id)contactEntry.get(Contact.AccountId);
                    if (contactsByAccountId.containsKey(contactAccountId)) {
                        contactsByAccountId.get(contactAccountId).add(contactEntry);
                    } else {
                        contactsByAccountId.put(
                                contactAccountId,
                                new List<Contact>{contactEntry}
                        );
                    }
                }
            }
            return contactsByAccountId;
        }
        public set; // TODO only allow this in testing
    }

    public override List<String> getIdentities(SObject record) {
        if (contactsByAccountId.containsKey((Id)record.get('AccountId'))) {
            List<String> returns = new List<String>();
            for (Contact accountContact: contactsByAccountId.get((Id)record.get('AccountId'))) {
                String identity = getIdentity(accountContact);
                if (null != identity) {
                    returns.add(identity);
                }
            }
            return returns;
        } else {
            return new List<String>();
        }
    }

    public override List<String> getIdentities() {
        Set<String> identities = new Set<String>();
        for (List<Contact> contacts : contactsByAccountId.values()) {
            for(Contact contactEntry: contacts) {
                String identity = getIdentity(contactEntry);
                if (null != identity) {
                    identities.add(identity);
                }
            }
        }
        List<String> returns = new List<String>();
        returns.addAll(identities);
        return returns;
    }

    public List<List<OpportunityFieldHistory>> groupFieldHistoriesByDate(List<OpportunityFieldHistory> opportunityFieldHistories) {
        Map<String, List<OpportunityFieldHistory>> historiesByDate = new Map<String, List<OpportunityFieldHistory>>();
        for (OpportunityFieldHistory history : opportunityFieldHistories) {
            String key = String.valueOf(history.Id) + String.valueOf(history.CreatedDate);
            if (historiesByDate.containsKey(key)) {
                historiesByDate.get(key).add(history);
            } else {
                historiesByDate.put(key, new List<OpportunityFieldHistory>{history});
            }
        }
        return historiesByDate.values();
    }

    public Map<Id, List<List<OpportunityFieldHistory>>> fieldHistoriesByOpportunityId {
        get {
            if (null == fieldHistoriesByOpportunityId) {
                fieldHistoriesByOpportunityId = new Map<Id, List<List<OpportunityFieldHistory>>>();
                for (SObject record : records) {
                    Id recordId = (Id)record.get('Id');
                    List<OpportunityFieldHistory> oppFieldHists = db.getSObjects(
                        OpportunityFieldHistory.getSObjectType(), 'opportunityId', new List<String> { recordId });
                    fieldHistoriesByOpportunityId.put(record.Id, groupFieldHistoriesByDate(oppFieldHists));
                }
            }
            return fieldHistoriesByOpportunityId;
        }
        public set;
    }

    public void handleFieldHistoryChanges(SObject record, SObject oldRecord, String identity, heap_Calls calls ) {
        List<List<OpportunityFieldHistory>> historiesGroupedByTime = fieldHistoriesByOpportunityId.get((Id)record.get('Id'));

        // :TODO: talos: We should still generate field history changes when the record is generated on the fly (as is done when there is more than one history)
        if (historiesGroupedByTime == null) return;
        if (historiesGroupedByTime.size() == 0) return;

        SObject newRecord = new Opportunity(Id=(Id)record.get('Id'));
        for (List<OpportunityFieldHistory> histories : historiesGroupedByTime){
            for (OpportunityFieldHistory fieldhistory: histories){
                String field = (String)fieldhistory.get('Field');
                // check that it's a valid field. Histories can have a field that isn't a valid Lead SObjectField
                if (Opportunity.getSObjectType().getDescribe().fields.getMap().keySet().contains(field.toLowerCase())){
                    record.put(field, fieldhistory.get('NewValue'));
                }
            }
            handleSingleChange(record, oldRecord, identity, calls, histories.get(0).CreatedDate);
        }
    }

    public override heap_Calls bulkBackload() {
        heap_Calls calls = new heap_Calls();
        for (SObject record: records) {
            List<OpportunityHistory> histories;
            if (opportunityHistoriesByOpportunityId.containsKey(((Opportunity) record).Id)) {
              histories = opportunityHistoriesByOpportunityId.get(((Opportunity) record).Id);
            } else {
              histories = new List<OpportunityHistory>();
            }
            if (histories.size() == 0) {
                for (String identity: getIdentities(record)) {
                    handleFieldHistoryChanges(record, (Sobject) new Opportunity(), identity, calls);
                }
            } else if (histories.size() == 1) {
                for (String identity: getIdentities(record)) {
                    handleFieldHistoryChanges(record, (Sobject) new Opportunity(), identity, calls);
                }
            } else {
                SObject oldRecord = (Sobject)new Opportunity();
                for (OpportunityHistory history: histories){
                    SObject newRecord = new Opportunity(
                            Name = (String)record.get('Name'),
                            StageName = (String)history.get('StageName'),
                            CloseDate = (Date)history.get('CloseDate')
                    );
                    for (String identity: getIdentities(record)) {
                        handleFieldHistoryChanges(newRecord, oldRecord, identity, calls);
                    }
                    oldRecord = newRecord;
                }
            }
        }
        addUserProperties(calls);
        return calls;
    }*/
}
public abstract class heap_Base {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration 
    public abstract void addUserProperties();// For code coverage while deploying commented method 
    /*public List<SObject> records; // TODO this should be protected
    public List<SObject> oldRecords = new List<sObject>();
    public Type objectType;
    public ObjectFieldMappings ofMappings = new ObjectFieldMappings();

    public heap_DBHelper db {
        get {
            if (null == db) {
                db = new heap_DBHelper();
            }
            return db;
        }
        set;
    }

    public Set<Id> getIds() {
        return getIds(records);
    }

    public Set<Id> getIds(String field) {
        return getIds(records, field);
    }

    public Set<id> getIds(List<SObject> records_i){
        Set<Id> values = new Set<Id>();
        for (SObject record: records_i) {
            values.add((Id) record.get('Id'));
        }
        return values;
    }

    public Set<id> getIds(List<SObject> records_i, String field){
            Set<Id> values = new Set<Id>();
            for (SObject record: records_i) {
                values.add((Id) record.get(field));
            }
            return values;
    }

    public Map<String, List<ObjectFieldMapping>> objectFields {
        get {
            if (null == objectFields) {
                objectFields = ofMappings.objectToFieldMapping;
            }
            return objectFields;
        }
        private set;
    }

    public Map<Id, SObject> relationFieldsById {
        get {
            if (null == relationFieldsById) {
                Set<Id> ids = getIds();
                String queryString = 'SELECT ' + ofMappings.relationQuery(getObjectType().getName()) +
                        ' FROM ' + getObjectType().getName() +
                        ' WHERE Id IN :ids';
                relationFieldsById = new Map<Id, SObject>(Database.query(queryString));
            }
            return relationFieldsById;
        }
        private set;
    }

    public Map<String, Map<Id, SObject>> previousRelationFields {
        get {
            if (null == previousRelationFields){
                previousRelationFields = new Map<String, Map<Id, SObject>>();
                Map<String, String> referenceQueries = ofMappings.queryStringsByReferenceObject(this);
                for (String objectName : referenceQueries.keySet()){
                    String query = referenceQueries.get(objectName);
                    if (String.isNotBlank(query)){
                        previousRelationFields.put(
                            objectName,
                            new Map<Id, SObject>(Database.query(query))
                        );
                    } else {
                        previousRelationFields.put(objectName, null);
                    }
                }
            }
            return previousRelationFields;
        }
        public set;
    }

    public virtual Map<String, String> getEventProperties(SObject newRecord, SObject oldRecord) {
        return getPropertyValues(newRecord, oldRecord);
    }

    public Map<String, String> getPropertyValues(SObject newRecord, SObject oldRecord){
        Map<String, String> properties = new Map<String, String>();
        if (objectFields.containsKey(getObjectType().getName())){
            for (ObjectFieldMapping ofm : objectFields.get(getObjectType().getName()) ){
                if (ofm.IsReference){
                    SObject referenceFieldsObject = relationFieldsById.get(newRecord.Id);
                    SObject referenceObject = referenceFieldsObject.getSObject(ofm.record.ReferenceRelationshipName__c);
                    properties.putAll(SupportedFieldTypes.stringifyField(ofm, referenceObject));

                    if (null != oldRecord && null != oldRecord.get('Id')){
                        Map<Id, SObject> oldReferenceFieldsObjects = previousRelationFields.get(ofm.record.ReferenceObjectType__c);
                        if (null != oldReferenceFieldsObjects && ofm.fieldHasChanged(newRecord, oldRecord)){
                            SObject oldReferenceObject = oldReferenceFieldsObjects.get((Id)oldRecord.get(ofm.record.Field__c));
                            properties.putAll(SupportedFieldTypes.stringifyField(ofm, oldReferenceObject, True));
                        }
                    }

                } else {
                    properties.putAll(SupportedFieldTypes.stringifyField(ofm, newRecord));
                    if (ofm.fieldHasChanged(newRecord, oldRecord) && null != oldRecord){
                        properties.putAll(SupportedFieldTypes.stringifyField(ofm, oldRecord, True));
                    }
                }
            }
        }
        return properties;
    }

    public void handleSingleChange(SObject newRecord, SObject oldRecord, String identity, heap_Calls calls, DateTime timestamp) {
        // TODO should this only be called if a field we care about changes?
        calls.addEvent(
                newRecord,
                identity,
                'Salesforce ' + getObjectType().getName() + ' Event',
                getEventProperties(newRecord, oldRecord),
                timestamp
        );
    }

    public void handleSingleChange(SObject newRecord, SObject oldRecord, String identity, heap_Calls calls, Map<String, String> properties) {
        // TODO should this only be called if a field we care about changes?
        calls.addEvent(
                newRecord,
                identity,
                'Salesforce ' + getObjectType().getName() + ' Event',
                properties
        );
    }



    public String getIdentity(SObject record){
        String identityField = null;
        if (record instanceof Contact){
             identityField = heap_Configuration.heapSettings.ContactIdentity__c;
        } else if (record instanceof Lead){
             identityField = heap_Configuration.heapSettings.LeadIdentity__c;
        }
        if (null == identityField){
            return null;
        }
        return String.valueOf(record.get(identityField));
    }

    public abstract Type getObjectType();

    public abstract List<String> getIdentities();
    public abstract List<String> getIdentities(SObject record);

    public abstract void addUserProperties(heap_Calls calls);

    // :TODO: (talos): isInsert isn't actually used below
    public virtual heap_Calls handleTrigger(heap_Calls calls, Boolean isInsert, Boolean isUpdate, Map<Id, SObject> oldMap) {
        if (heap_Configuration.SkipTriggers ||
                null == heap_Configuration.heapSettings.ContactIdentity__c ||
                null == heap_Configuration.HeapAppId){
            return calls;
        }
        if (null != oldMap){
            oldRecords = oldMap.values();
        } else {
            oldRecords = new List<SObject>();
        }
        SObject oldRecord;
        for (SObject newRecord: records) {
            if (isUpdate) {
                oldRecord = oldMap.get(newRecord.Id);
            } else {
                oldRecord = (Sobject)getObjectType().newInstance();
            }

            if (trackedFieldHasChanged(newRecord, oldRecord)) {
                Map<String, String> properties = getEventProperties(newRecord, oldRecord);
                for (String identity: getIdentities(newRecord)) {
                    handleSingleChange(newRecord, oldRecord, identity, calls, properties);
                }
            }
        }

        Type classType = Type.forName(String.valueOf(this).split(':')[0]); // FUCK THIS.
        if (!System.isFuture() && !System.isBatch()) {
            if (ofMappings.objectToFieldMapping.containsKey(getObjectType().getName())){
                // :TODO: talos: The flex queue is an unreliable way to schedule these jobs.  We should place identities
                // that don't make it into the scheduler somewhere else for later retry.
                try {
                    Database.executeBatch(new heap_BatchUserProperties(getIdentities(), classType), 5);
                } catch(AsyncException err) {
                    System.debug('Could not batch user properties: ' + err);
                    System.debug('Stacktrace' + err.getStackTraceString());
                }
            }
        }
        return calls;
    }

    public virtual heap_Calls bulkBackload() {
        return new heap_Calls();
    } // TODO make abstract

    private virtual boolean trackedFieldHasChanged(SObject newRecord, SObject oldRecord) {
        String objectTypeName = getObjectType().getName();

        if (objectFields.containsKey(objectTypeName)) {
            for (ObjectFieldMapping ofm : objectFields.get(objectTypeName) ) {
                if (ofm.fieldHasChanged(newRecord, oldRecord)) {
                    return true;
                }
            }
        }
        return false;
    }*/
}
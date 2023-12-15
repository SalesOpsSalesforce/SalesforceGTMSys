public with sharing class ObjectFieldMappings{
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public ObjectFieldMappings(){}
   /* public ObjectFieldMappings(){}

    public Map<String, List<ObjectFieldMapping>> objectToFieldMapping {
        get {
            if (null == objectToFieldMapping) {
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Map<String, List<ObjectFieldMapping>> temp = new Map<String, List<ObjectFieldMapping>>();
                for (heap_ObjectFieldMapping__c fieldMapping : heap_ObjectFieldMapping__c.getAll().values()) {
                    // Confirm that our object field mapping exists on the object still.  Object field mappings can cease
                    // to exist if the customer set them up, then deleted the underlying field (for example if they
                    // removed a package that was generating the field)
                    if (schemaMap.get(fieldMapping.ObjectType__c).getDescribe().fields.getMap().containsKey(fieldMapping.Field__c)) {
                        if (temp.containsKey(fieldMapping.ObjectType__c)){
                            temp.get(fieldMapping.ObjectType__c).add(new ObjectFieldMapping(fieldMapping));
                        } else {
                            temp.put(fieldMapping.ObjectType__c, new List<ObjectFieldMapping>{new ObjectFieldMapping(fieldMapping)});
                        }
                    } else {
                        System.debug('Field mapping "' + fieldMapping.ObjectType__c + '.' + fieldMapping.Field__c
                        + '" can no longer be resolved for its underlying object.  Please remove it.');
                    }
                }
                objectToFieldMapping = temp;
            }
            return objectToFieldMapping;
        }
        public set;
    }

    public String queryString(String objectName) {
        List<String> toRet = new List<String>{fieldQuery(objectName), relationQuery(objectName)};
        if (String.isBlank(toRet[0]) && String.isBlank(toRet[1])) {
            return 'Id';
        } else if (String.isBlank(toRet[1])){
            return toRet[0].replaceAll(',$', '');
        }else {
            return String.join(toRet, ',').replaceAll(',$', '');
        }
    }

    public Map<String, String> queryStringsByReferenceObject(heap_Base heapObject){
        Map<String, String> toRet = new Map<String, String>();
        Map<String, Set<String>> tempMap = new Map<String, Set<String>>();
        Map<String, Set<Id>> referenceObjectToIds = new Map<String, Set<Id>>();
        for (ObjectFieldMapping fieldMapping : objectToFieldMapping.get(heapObject.getObjectType().getName())){
            if (fieldMapping.isReferenceId){
                if (tempMap.containsKey(fieldMapping.record.ReferenceObjectType__c)){
                    tempMap.get(fieldMapping.record.ReferenceObjectType__c).add(fieldMapping.record.ReferenceObjectField__c);
                    referenceObjectToIds.get(fieldMapping.record.ReferenceObjectType__c).addAll(heapObject.getIds(heapObject.oldRecords, fieldMapping.record.Field__c));
                } else {
                    tempMap.put(fieldMapping.record.ReferenceObjectType__c, new Set<String>{fieldMapping.record.ReferenceObjectField__c});
                    referenceObjectToIds.put(fieldMapping.record.ReferenceObjectType__c, heapObject.getIds(heapObject.oldRecords, fieldMapping.record.Field__c));
                }
            }
        }
        for (String referenceObjectName : tempMap.keySet()){
            if (referenceObjectToIds.get(referenceObjectName).size() == 0){
                continue;
            }
            List<String> idsList = new List<String>();
            for (Id objectId : referenceObjectToIds.get(referenceObjectName)){
                if (null != objectId){
                    idsList.add('\'' + String.valueOf(objectId) + '\'');
                }
            }
            if (idsList.size() > 0) {
                String ids = String.join(idsList, ',');

                String queryString =
                    'Select ' + String.join(new List<String>(tempMap.get(referenceObjectName)), ',') +
                    ' FROM ' + referenceObjectName +
                    ' WHERE Id IN (' + ids + ')';
                toRet.put(referenceObjectName, queryString);
            } else {
                toRet.put(referenceObjectName, null);
            }
        }
        return toRet;
    }


    public Boolean containsField(String objectName, String fieldName){
        if (null == objectToFieldMapping) return False;
        if (!objectToFieldMapping.containsKey(objectName)) return False;
        for (ObjectFieldMapping fieldMapping : objectToFieldMapping.get(objectName)){
            if (fieldMapping.record.Field__c == fieldName) {
                return True;
            }
        }
        return False;
    }

    public String fieldQuery(String objectName) {
        if (!objectToFieldMapping.containsKey(objectName)){
            return '';
        }
        List<String> toRet = new List<String>();
        for (ObjectFieldMapping fieldMapping : objectToFieldMapping.get(objectName)){
            if (!fieldMapping.isReference){
                toRet.add(fieldMapping.record.Field__c);
            }
        }
        return String.join(toRet, ',');
    }

    public String relationQuery(String objectName) {
        if (!objectToFieldMapping.containsKey(objectName)){
            return '';
        }
        List<String> toRet = new List<String>();
        for (ObjectFieldMapping fieldMapping : objectToFieldMapping.get(objectName)){
            if (fieldMapping.isReference){
                toRet.add(fieldMapping.record.ReferenceRelationshipName__c + '.' + fieldMapping.record.ReferenceObjectField__c);
            }
        }
        return String.join(toRet, ',');
    }*/
}
public with sharing class ObjectFieldMapping implements Comparable{
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public ObjectFieldMapping(){}
   /* public Map <String, Schema.SObjectType> schemaMap;

    public heap_ObjectFieldMapping__c record {get; set;}

    public ObjectFieldMapping(String objType, String field, String refObjType, String refField) {
        schemaMap = Schema.getGlobalDescribe();
        String name = objType + '_' + field + '_' + refObjType + '_' + refField;
        String relname = schemaMap.get(objType).getDescribe().fields.getMap().get(field).getDescribe().getRelationshipName();
        record = new heap_ObjectFieldMapping__c(
            name=heap_Util.base64encodedMD5(name),
            ObjectType__c=objType,
            Field__c=field,
            ReferenceObjectType__c=refObjType,
            ReferenceObjectField__c=refField,
            ReferenceRelationshipName__c=relname,
            IsReference__c=String.isBlank(refField) ? false : true
        );
    }

    public ObjectFieldMapping(heap_ObjectFieldMapping__c ofm_i){
        record = ofm_i;
        schemaMap = Schema.getGlobalDescribe();
    }

    public Boolean isReference {
        get {
            if (null == isReference){
                isReference = record.IsReference__c;
            }
            return isReference;
        }
        private set;
    }

    public Boolean isReferenceId {
        get {
            if (null == isReferenceId){
                isReferenceId = isReference && schemaMap.get(getObjectDisplay()).getDescribe().fields.getMap().get(record.Field__c).getDescribe().getType() == Schema.DisplayType.Reference;
            }
            return  isReferenceId;
        }
        private set;
    }

    public String label {
        get {
            if (null == label) {
                label = '';
                label += getObjectDisplay() + ' ';
                String referenceLabel = referenceObjectLabel;

                if (!String.isBlank(referenceLabel)){
                    label += referenceLabel + ' ';
                }

                if (isReference){
                    label += createFieldLabel(record.ReferenceObjectType__c, record.ReferenceObjectField__c);
                } else {
                    label += createFieldLabel(record.ObjectType__c, record.Field__c);
                }
            }
            return label;
        }
        public set;
    }

    public Boolean fieldHasChanged(SObject newRecord, SObject oldRecord){
        Boolean hasChanged;
        if (null == oldRecord || null == newRecord){
            hasChanged = True;
        }else if (newRecord.get(record.Field__c) != oldRecord.get(record.Field__c)){
            hasChanged = True;
        } else {
            hasChanged = False;
        }
        return hasChanged;
    }

    public String getLabel(){
        return getLabel(false);
    }

    public String getLabel(Boolean isPrevious) {
        String labelToRet;
        if (isPrevious){
            labelToRet = 'Previous SFDC ';
        } else {
            labelToRet = 'SFDC ';
        }
        return labelToRet + label;
    }

    public String getFieldDisplayLabel() {
        if (isReference) {
            return referenceObjectLabel + ' → ' + createFieldLabel(record.ReferenceObjectType__c, record.ReferenceObjectField__c);
        } else {
            return createFieldLabel(record.ObjectType__c, record.Field__c);
        }
    }

    public String getObjectDisplay() {
        return record.ObjectType__c;
    }

    public String getObjectName() {
        return record.name;
    }

    private String referenceObjectLabel {
        get {
            if (null == referenceObjectLabel) {
                referenceObjectLabel = '';

                if (isReference){
                    // References to custom objects have an ugly label. The field label on the original object is generally nicer
                    if (schemaMap.get(record.ReferenceObjectType__c).getDescribe().isCustom() || record.ReferenceRelationshipName__c.endsWith('__r')) {
                        referenceObjectLabel = schemaMap.get(record.ObjectType__c).getDescribe().fields.getMap().get(record.Field__c).getDescribe().getLabel();
                    } else {
                        referenceObjectLabel = record.ReferenceRelationshipName__c;
                    }
                }
            }
            return referenceObjectLabel;
        }
        private set;
    }

    private String createFieldLabel(String labelObject, String labelField){
        // Attempt to remove repetitive names (i.e. Opportunity Account Account Name)
        String label = schemaMap.get(labelObject).getDescribe().fields.getMap().get(labelField).getDescribe().getLabel();
        if (label.startsWith(labelObject)){
            label = label.replaceFirst(labelObject, '').trim();
        }
        return label;
    }*/

    public Integer compareTo(Object compareTo){
       /* ObjectFieldMapping compareToMapping = (ObjectFieldMapping)compareTo;
        if (getLabel() == compareToMapping.getLabel()) return 0;
        if (getLabel() > compareToMapping.getLabel()) return 1;*/
        return -1;
    }
}
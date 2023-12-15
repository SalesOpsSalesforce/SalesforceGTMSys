public with sharing class heap_ObjectFieldController {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_ObjectFieldController(){}
    /*public String selectedObject {get; set;}
    public String selectedField {get; set;}

    public String selectedReferenceObjectAndField {get; set;}

    public Map<String, Schema.SObjectType> schemaMap;

    public heap_ObjectFieldController() {
        resetSelectedValues();
        schemaMap = Schema.getGlobalDescribe();
    }

    public void resetSelectedValues(){
        selectedField = '';
        selectedReferenceObjectAndField = '';
    }

    public List<SelectOption> getObjectTypes(){
        // TODO these need to be stored somewhere else
        return new List<SelectOption>{
            new SelectOption('', '--Select--'),
            new SelectOption('Account', 'Account'),
            new SelectOption('Contact', 'Contact'),
            new SelectOption('Lead', 'Lead'),
            new SelectOption('Opportunity', 'Opportunity')
        };
    }

    public List<SelectOption> getObjectFields() {
        List<SelectOption> fieldNames = new List<SelectOption>();
        fieldNames.add(new SelectOption('', '--Select--'));
        if (!String.isBlank(selectedObject)){
            Schema.SObjectType ObjectSchema = schemaMap.get(selectedObject);
            Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();

            List<String> entities = new List<String>(fieldMap.keySet());
            entities.sort();
            for (String fieldName: entities){
                DescribeFieldResult describeResult = fieldMap.get(fieldName).getDescribe();

                String label = describeResult.getLabel();
                fieldNames.add(new SelectOption(fieldName, label));
            }
        }
        return fieldNames;
    }

    public Boolean getIsReferenceField(){
        Schema.SObjectType ObjectSchema = schemaMap.get(selectedObject);

        if (String.isBlank(selectedField) || !ObjectSchema.getDescribe().fields.getMap().containsKey(selectedField)) {
            return False;
        }
        Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();
        if (fieldMap.get(selectedField).getDescribe().getType() == Schema.DisplayType.Reference){
            return true;
        }
        return false;
    }

    public List<SelectOption> getReferenceObjectFields() {
        Schema.SObjectType ObjectSchema = schemaMap.get(selectedObject);
        Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();

        List<Schema.SObjectType> fieldReferences = fieldMap.get(selectedField).getDescribe().getReferenceTo();

        List<SelectOption> fieldNames = new List<SelectOption>();
        fieldNames.add(new SelectOption('', '--Select--'));

        for (Schema.SObjectType fieldReference : fieldReferences) {
            Map<String, Schema.SObjectField> referenceFieldMap = fieldReference.getDescribe().fields.getMap();
            List<String> entities = new List<String>(referenceFieldMap.keySet());
            entities.sort();
            for (String fieldName: entities){
                DescribeFieldResult describeResult = referenceFieldMap.get(fieldName).getDescribe();
                String label = describeResult.getLabel() + ' (' + fieldReference.getDescribe().getName() + ')';
                String value = fieldReference.getDescribe().getName() + '-' + fieldName;
                fieldNames.add(new SelectOption(value, label));
            }
        }
        return fieldNames;
    }

    public class ObjectFieldWrapper {
        Map<String, Schema.SObjectType> schemaMap;
        public ObjectFieldMapping ofMapping { get; set; }
        public Integer rowNum { get; set; }

        public ObjectFieldWrapper(ObjectFieldMapping ofm, Integer num) {
            ofMapping = ofm;
            rowNum = num;
        }
    }

    public Map<String, List<ObjectFieldWrapper>> getCurrentObjectFieldMappings(){
        Map<String, List<ObjectFieldWrapper>> tempMap = new Map<String, List<ObjectFieldWrapper>>();
        Integer rowNum = 0;
        ObjectFieldMappings fieldMappings = new ObjectFieldMappings();
        for (String objectName : fieldMappings.objectToFieldMapping.keySet()){
            List<ObjectFieldMapping> ofms = fieldMappings.objectToFieldMapping.get(objectName);
            ofms.sort();
            for (ObjectFieldMapping ofm : ofms){
                if (tempMap.containsKey(ofm.getObjectDisplay())){
                    tempMap.get(ofm.getObjectDisplay()).add(new ObjectFieldWrapper(ofm, rowNum));
                }
                else {
                    tempMap.put(ofm.getObjectDisplay(), new List<ObjectFieldWrapper>{new ObjectFieldWrapper(ofm, rowNum)});
                }
                rowNum += 1;
            }
        }
        return tempMap;
    }

    public PageReference add() {
        if (null == selectedObject || null == selectedField ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Please select an object and field.'));
            return null;
        }
        String selectedRefObject = null;
        String selectedRefField = null;
        if ('' != selectedReferenceObjectAndField) {
            selectedRefObject = selectedReferenceObjectAndField.split('-', 2)[0];
            selectedRefField = selectedReferenceObjectAndField.split('-', 2)[1];
        }
        ObjectFieldMapping ofm = new ObjectFieldMapping(
            selectedObject, selectedField, selectedRefObject, selectedRefField
        );
        if ([SELECT count() from heap_ObjectFieldMapping__c WHERE Name = :ofm.getObjectName()] > 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Field mapping already exists.'));
            return null;
        }
        insert ofm.record;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Field mapping added!'));
        resetSelectedValues();
        return null;
    }

    public void removeRow() {
        Id rowId = (Id)ApexPages.currentPage().getParameters().get('rowId');
        delete [Select Id from heap_ObjectFieldMapping__c where Id = :rowId];
    }*/

}
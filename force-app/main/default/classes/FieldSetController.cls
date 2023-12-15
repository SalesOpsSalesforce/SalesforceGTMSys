//[vrajapatruni 02/16/2023 SFDC-1742/1880] Built to dynamically take in Field Set (OpportunityMPOFieldSet for Opp's Add/Update products wizard)
//Code coverage in FieldSetControllerTest class

public with sharing class FieldSetController{
    
    @AuraEnabled(cacheable=true)
    public static List<FieldSetWrapper> getFieldSet(String objectName, String fieldSetName){
        List<Map<String, Object>> fields = new List<Map<String, Object>>();
        List<FieldSetWrapper> listofFieldSetWrapper = new List<FieldSetWrapper>();
         try{
            SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null){
                throw new AuraHandledException(objectName + ' object not found');
            }
            Map<String, Schema.SObjectField> objFields = objType.getDescribe().fields.getMap();
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            List<Schema.FieldSet> objFieldSets = objDescribe.FieldSets.getMap().values();
            Schema.FieldSet fs = null;
            for (Schema.FieldSet fieldSet : objFieldSets){
                if(fieldSet.getLabel() == fieldSetName){
                    fs = fieldSet;
                    break;
                }
            }
            if(fs == null){
                throw new AuraHandledException(fieldSetName + ' field set not found on ' + objectName + ' object');
            }
            for(Schema.FieldSetMember fsm : fs.getFields()){
                if(!objFields.containsKey(fsm.getFieldPath())){
                    throw new AuraHandledException(fsm.getFieldPath() + ' field not found on ' + objectName + ' object');
                }
                Map<String, Object> field = new Map<String, Object>();
                field.put('fieldApiName', fsm.getFieldPath());
                field.put('fieldLabel', objFields.get(fsm.getFieldPath()).getDescribe().getLabel());
                field.put('fieldType', objFields.get(fsm.getFieldPath()).getDescribe().getType());
                fields.add(field);
                listofFieldSetWrapper.add(new FieldSetWrapper(String.valueOf(fsm.getFieldPath()), String.valueOf(objFields.get(fsm.getFieldPath()).getDescribe().getLabel()) , String.valueOf(objFields.get(fsm.getFieldPath()).getDescribe().getType()) , TRUE));
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return listofFieldSetWrapper;
    }
    
    public with sharing class FieldSetWrapper{
        public String fieldApiName {get; set;}
        public String fieldLabel {get; set;}
        public String fieldType {get; set;}
        public Boolean isRequired {get; set;}
    
        public FieldSetWrapper(String fieldApiName, String fieldLabel, String fieldType, Boolean isRequired){
            this.fieldApiName = fieldApiName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.isRequired = isRequired;
        }
    }

}
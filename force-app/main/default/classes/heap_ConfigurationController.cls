public with sharing class heap_ConfigurationController {
	//[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
	// For code coverage while deploying commented methods
    public heap_ConfigurationController(){}
    /*public final heap_Settings__c heapSettings {get; set;}
    public String backfillClass {get; set;}

    public Map <String, Schema.SObjectType> schemaMap;

    public heap_ConfigurationController() {
        heapSettings = heap_Settings__c.getOrgDefaults();
        schemaMap = Schema.getGlobalDescribe();
    }

    public List<SelectOption> getBackfillClasses (){
        List<SelectOption> toRet = new List<SelectOption>();
        for (Type classType : heap_Configuration.backfillClasses) {
            toRet.add(new SelectOption(classType.getName(), classType.getName()));
        }
        return toRet;
    }


    public List<SelectOption> getContactFields() {
        return getObjectFields('Contact');
    }

    public List<SelectOption> getLeadFields(){
        return getObjectFields('Lead');
    }

    public List<SelectOption> getOpportunityFields(){
        List<SelectOption> fieldNames = new List<SelectOption>();
        fieldNames.add(new SelectOption('', '--Select--'));
        Schema.SObjectType ObjectSchema = schemaMap.get('Opportunity');
        Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();

        List<String> entities = new List<String>(fieldMap.keySet());
        entities.sort();
        for (String fieldName: entities){
            if (SupportedFieldTypes.opportunityAggregateTypes.contains(fieldMap.get(fieldName).getDescribe().getType())){
                DescribeFieldResult describeResult = fieldMap.get(fieldName).getDescribe();
                String label = describeResult.getLabel();
                fieldNames.add(new SelectOption(fieldName, label));
            }
        }
        return fieldNames;
    }

    public List<SelectOption> getObjectFields(String objectName) {
        List<SelectOption> fieldNames = new List<SelectOption>();
        fieldNames.add(new SelectOption('', '--Select--'));
        Schema.SObjectType ObjectSchema = schemaMap.get(objectName);
        Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();

        List<String> entities = new List<String>(fieldMap.keySet());
        entities.sort();
        for (String fieldName: entities){
            if (fieldMap.get(fieldName).getDescribe().getType() != Schema.DisplayType.Reference){
                DescribeFieldResult describeResult = fieldMap.get(fieldName).getDescribe();
                String label = describeResult.getLabel();
                fieldNames.add(new SelectOption(fieldName, label));
            }
        }
        return fieldNames;
    }

    public void startBackfill() {
        try {
            heap_BatchBackload backLoad = new heap_BatchBackload(backfillClass);
            Id batchProcessId = database.executeBatch(backload, 150); // TODO, this should be config param
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.Confirm,
                                     'Backfill started for ' + backfillClass
                )
            );
        } catch (heap_BatchBackload.HeapBackloadException e){
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.Error,
                                     'Backfill failed for ' + backfillClass
                )
            );
        }
    }

    public void saveSettings() {
        try {
            upsert heapSettings;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Settings Updated!'));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Failed to update settings' ));
        }
    }*/

}
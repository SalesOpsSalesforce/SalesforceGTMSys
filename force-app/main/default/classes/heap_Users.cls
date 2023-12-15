public with sharing class heap_Users {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_Users(){}
    /*public static Set<Id> getuserIds(List<SObject> records, Set<SObjectField> recordFields) {
        Set<Id> userIds = new Set<Id>();
        for (SObject record : records) {
            for (SObjectField field : recordFields) {
                userIds.add(
                    (Id)record.get(field)
                );
            }
        }
        return userIds;
    }

    public static Map<Id, User> getUsersbyFields(List<SObject> records, Set<SObjectField> recordFields) {
        Set<Id> userIds = getuserIds(records, recordFields);
        return new Map<Id, User>([SELECT Id, Name, Email FROM USER WHERE Id IN :userIds]);
    }*/

}
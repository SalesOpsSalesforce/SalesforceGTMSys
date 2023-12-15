@isTest
public with sharing class heap_TestFixtures {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // It would be nice to be able to insert the SObject within the methods
    // HttpCalloutMock doesn't increment the number of calls when it's called within these methods

    /*static Integer s_num = 1;

    public static String getFakeId(Schema.SObjectType sot){
          String result = String.valueOf(s_num++);
          return sot.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    }

    public static User fakeUserCreator(String LastName){
        Datetime dt = Datetime.now();
        Long l = dt.getTime();

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User myUser = new User(
            EmailEncodingKey='UTF-8',
            LastName= LastName,
            LanguageLocaleKey='en_US',
            Alias = LastName.abbreviate(8),
            Email= LastName + 'standarduser@testorg.com',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName= LastName + 'standarduserTestUser@testorg.com'
        );
        //myUser.Id = getFakeId(myUser.getSObjectType());
        return myUser;
    }

    public static Account accountCreator(String Name){
        User fakeUser = heap_TestFixtures.fakeUserCreator('Johnson');
        Account myAccount = new Account(
            Name=Name
        );
        //myAccount.Id = getFakeId(myAccount.getSObjectType());
        return myAccount;
    }

    // Future improvement - builder pattern
    public static Contact contactCreator(Id AccountId, String firstName, String lastName, Boolean includeId){
        Contact myContact = new Contact(
            FirstName=firstName,
            LastName=lastName,
            AccountId=AccountId
        );
        if (includeID){
            myContact.Email = firstName + '@test.org';
        }
        //myContact.Id = getFakeId(myContact.getSObjectType());

       return myContact;
    }

    public static Lead leadCreator(String LastName, String Company, String LeadStatus) {
        Lead myLead = new Lead(
            LastName = LastName,
            Company = Company,
            Status = LeadStatus
        );
        //myLead.Id = getFakeId(myLead.getSObjectType());
        return myLead;
    }

    public static Opportunity opportunityCreator(String Name, String StageName) {
        Opportunity myOpportunity = new Opportunity(
            Name = Name,
            StageName = StageName
        );
        //myOpportunity.Id = getFakeId(myOpportunity.getSObjectType());
        return myOpportunity;
    }

    public static Task taskCreator(String Subject, String Status){
        Task myTask = new Task(
            Subject = Subject,
            Status = Status
            );
        //myTask.Id = getFakeId(myTask.getSObjectType());

        return myTask;
    }

    public static SObject sObjectCreator(String jsonStr, Type apexType) {
        return (SObject) json.deserialize(jsonStr, apexType);
    }

    public static SObject sObjectCreator(Map<String, Object> data, Type apexType) {
        return sObjectCreator(JSON.serialize(data), apexType);
    }

    public static OpportunityHistory opportunityHistoryCreator(
            Opportunity opp, String stageName, Date closeDate
    ) {
        return (OpportunityHistory) sObjectCreator(new Map<String, Object> {
                'OpportunityId' => opp.Id,
                'StageName' => stageName,
                'CloseDate' => String.valueOf(closeDate)
        }, OpportunityHistory.class);
    }

    public static OpportunityFieldHistory opportunityFieldHistoryCreator(
        Opportunity opp, String field, String newValue, String oldValue
    ) {
        return (OpportunityFieldHistory) sObjectCreator(new Map<String, Object> {
            // If values below are included, Salesforce will crash with
            // System.UnexpectedException: Salesforce System Error: 622387406-266951 (-932436621) (-932436621)
            //'NewValue' => newValue,
            //'OldValue' => oldValue,
            'OpportunityId' => opp.Id,
            'Field' => field
        }, OpportunityFieldHistory.class);
    }

    public static LeadHistory leadHistoryCreator(
            Lead lead, String field, String newValue, String oldValue
    ) {
        return (LeadHistory) sObjectCreator(new Map<String, Object> {
            // If values below are included, Salesforce will crash.
            //'NewValue' => newValue,
            //'OldValue' => oldValue,
            'LeadId' => lead.Id,
            'Field' => field
        }, LeadHistory.class);
    }*/
}
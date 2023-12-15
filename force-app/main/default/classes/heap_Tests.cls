@isTest(seeAllData=false)
public with sharing class heap_Tests {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    //testForCommentedClass is for code coverage while deploying commented class AlexaRankUpdateOnAccount
    @IsTest
    private static void testForCommentedClass() {
        Test.startTest();
        heap_Accounts acc = new heap_Accounts();
        acc.addUserProperties();
        heap_BatchUserProperties hpUserProperty = new heap_BatchUserProperties();
        Database.executeBatch(hpUserProperty);
        heap_Calls call = new heap_Calls();
        heap_Configuration config = new heap_Configuration();
        heap_Contacts con = new heap_Contacts();
        con.addUserProperties();
        heap_DBHelper dbHelper = new heap_DBHelper();
        heap_HeapService.asyncCall();
        heap_Leads l= new heap_Leads();
        l.addUserProperties();
        heap_Opportunities opp = new heap_Opportunities();
        opp.addUserProperties();
        heap_TrackingCall trackCall = new heap_TrackingCall();
        heap_UserPropertyCall userCall = new heap_UserPropertyCall();
        heap_Users hpUser = new heap_Users();
        heap_Util ut = new heap_Util();
        heap_ConfigurationController cnt = new heap_ConfigurationController();
        heap_BatchBackload hpBackLoad = new heap_BatchBackload();
        Database.executeBatch(hpBackLoad);
        heap_ObjectFieldController fieldCntr = new heap_ObjectFieldController();
        SupportedFieldTypes suppFields = new SupportedFieldTypes();
        ObjectFieldMappings objMappings = new ObjectFieldMappings();
        ObjectFieldMapping objFieldMapping = new ObjectFieldMapping();
        objFieldMapping.compareTo('Compare');
        heap_schedulableBackload hpScheduleLoad = new heap_schedulableBackload();
        Database.executeBatch(hpScheduleLoad);
        heap_scheduledBackload obj = new heap_scheduledBackload();
        String schedule = '0 0 23 * * ?'; 
        system.schedule('Test Heap Back Load', schedule, obj);
        Test.stopTest();  
    }
    /*static Integer s_num = 1;
    private static String getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(s_num++);
        return sot.getDescribe().getKeyPrefix() +
                '0'.repeat(12-result.length()) + result;
    }
    static {
        heap_Settings__c heapSettings = heap_Configuration.heapSettings;
        heapSettings.OpportunityAggregator__c = 'CreatedDate';
        heapSettings.ContactIdentity__c = 'Email';
        heapSettings.LeadIdentity__c = 'Email';
        heapSettings.Heap_App_ID__c = '123';
        heapSettings.Heap_Skip_Trigger__c = false;
        insert heapSettings;

        List<heap_ObjectFieldMapping__c> toInsert = new List<heap_ObjectFieldMapping__c>{
            new heap_ObjectFieldMapping__c (
                Name='test1',
                ObjectType__c='Opportunity',
                Field__c='StageName',
                ReferenceObjectType__c=null,
                ReferenceObjectField__c=null,
                ReferenceRelationshipName__c=null,
                IsReference__c=false
            ),
            new heap_ObjectFieldMapping__c (
                Name='test2',
                ObjectType__c='Account',
                Field__c='Name',
                ReferenceObjectType__c=null,
                ReferenceObjectField__c=null,
                ReferenceRelationshipName__c=null,
                IsReference__c=false
            ),
            new heap_ObjectFieldMapping__c (
                Name='test3',
                ObjectType__c='Lead',
                Field__c='LastName',
                ReferenceObjectType__c=null,
                ReferenceObjectField__c=null,
                ReferenceRelationshipName__c=null,
                IsReference__c=false
            ),
            new heap_ObjectFieldMapping__c (
                Name='test4',
                ObjectType__c='Contact',
                Field__c='LastName',
                ReferenceObjectType__c=null,
                ReferenceObjectField__c=null,
                ReferenceRelationshipName__c=null,
                IsReference__c=false
            ),
            new heap_ObjectFieldMapping__c (
                Name='test5',
                ObjectType__c='Task',
                Field__c='Status',
                ReferenceObjectType__c=null,
                ReferenceObjectField__c=null,
                ReferenceRelationshipName__c=null,
                IsReference__c=false
            ),
            new heap_ObjectFieldMapping__c (
                Name='test6',
                ObjectType__c='Task',
                Field__c='Subject',
                ReferenceObjectType__c=null,
                ReferenceObjectField__c=null,
                ReferenceRelationshipName__c=null,
                IsReference__c=false
            ),
            // Nonexistent field for testing purposes.
            // This should cover the case when a field has been removed.
            new heap_ObjectFieldMapping__c (
                Name='test7',
                ObjectType__c='Contact',
                Field__c='DNE',
                ReferenceObjectType__c=null,
                ReferenceObjectField__c=null,
                ReferenceRelationshipName__c=null,
                IsReference__c=false
            )
        };
        insert toInsert;
    }

    @isTest
    public static void testDBHelper() {
        heap_DBHelper db = new heap_DBHelper();
        db.getSObjects(Opportunity.SObjectType, 'Name', new List<Id>());
        db.getSObjects('Select Id from Opportunity');
    }

    @isTest
    public static void testHeapBase() {
        Opportunity newOpportunity = new Opportunity(
            Name = 'test',
            StageName ='Qualify/Discover',
            Type = 'New Business',
            CloseDate = Date.newInstance(2018, 1, 1),
            Amount = 1000.00
        );
        insert new heap_ObjectFieldMapping__c (
            Name='test0',
            ObjectType__c='Opportunity',
            Field__c='ownerid',
            ReferenceObjectType__c='User',
            ReferenceObjectField__c='firstname',
            ReferenceRelationshipName__c='Owner',
            IsReference__c=true
        );
        heap_Opportunities ops = new heap_Opportunities(new List<Opportunity>{newOpportunity});
        ops.oldRecords = new List<Opportunity>{newOpportunity};
        // These should be 1, but since we're not doing inserts, the database returns nothing
        System.assertEquals(0, ops.relationFieldsById.size());
        System.assertEquals(1, ops.previousRelationFields.size());
    }

    @isTest
    public static void testObjectFieldMappings() {
        Opportunity newOpportunity = new Opportunity(
            Name = 'test',
            StageName ='Qualify/Discover',
            Type = 'New Business',
            CloseDate = Date.newInstance(2018, 1, 1),
            Amount = 1000.00
        );
        insert new heap_ObjectFieldMapping__c (
            Name='test0',
            ObjectType__c='Opportunity',
            Field__c='ownerid',
            ReferenceObjectType__c='User',
            ReferenceObjectField__c='firstname',
            ReferenceRelationshipName__c='Owner',
            IsReference__c=true
        );
        heap_Opportunities ops = new heap_Opportunities(new List<Opportunity>{newOpportunity});
        ops.oldRecords = new List<Opportunity>{newOpportunity};
        ObjectFieldMappings fieldMappings = new ObjectFieldMappings();
        Map<String, String> queryStringMap = fieldMappings.queryStringsByReferenceObject((heap_Base)ops);
        System.assertEquals(1, queryStringMap.size());
    }

    @isTest
    public static void testSupportedFieldTypes() {
        Opportunity opp1 = new Opportunity(
            Id=getFakeId(Opportunity.SObjectType),
            Name='TestName',
            CloseDate=Date.newInstance(2017,2,1)
        );
        Opportunity opp2 = new Opportunity(
            Id=getFakeId(Opportunity.SObjectType),
            Name='TestNames',
            CloseDate=Date.newInstance(2017,1,1)
        );
        System.assertEquals(true, SupportedFieldTypes.compareObjects(opp1, opp2, 'CloseDate'));
    }

    @isTest
    public static void testChunkListMap() {
        List<Map<String, Object>> testList = new List<Map<String, Object>>();
        for (Integer i =0; i < 10; i++){
            testList.add(
                new Map<String, Object>{
                    String.valueOf(i) => i
                }
            );
        }
        System.assertEquals(2, heap_Util.chunk(testList, 5).size());
    }

    @isTest
    public static void testTrigger(){

        Lead newLead = new Lead(
            LastName = 'FakeLName',
            Company = 'co',
            Email = 'foo@barbaz.com',
            FirstName = 'foo',
            Salutation = 'sir'
        );

        Account newAccount = new Account(
            Name = 'test'
        );
        Contact newContact = new Contact(
            LastName = 'test',
            Email = 'testing123@test.org'
        );
        Task newTask = new Task(
            Subject = 'test'
        );
        Opportunity newOpportunity = new Opportunity(
            Name = 'test',
            StageName ='Qualify/Discover',
            Type = 'New Business',
            CloseDate = Date.newInstance(2018, 1, 1),
            Amount = 1000.00
        );
        Test.startTest();
        // hacky workaround for instances that have workflow rules we can't get around
        try {
            insert new List<SObject>{
                newLead,
                newAccount,
                newContact,
                newOpportunity,
                newTask
            };
        } catch (Exception e) {
            return;
        }
        Test.stopTest();
    }

    @isTest
    private static void testCreateLead() {
        User ownerUser = heap_TestFixtures.fakeUserCreator('BobTesterHeap');
        Lead newLead = heap_TestFixtures.leadCreator(
            'FakeLName',
            'Fake InnewContact. Company',
            'Qualified'
        );
        newLead.Email = 'test123@test.org';
        newLead.LeadSource = 'test';
        newLead.OwnerId = ownerUser.Id;

        List<Lead> leadList = new List<Lead>{
            newLead
        };
        heap_Leads leads = new heap_Leads(leadList);

        Map<Id, Lead> oldMap = new Map<Id, Lead>();
        oldMap.put(newLead.Id, newLead);
        heap_Calls calls = leads.handleTrigger(new heap_Calls(), true, false, oldMap);
        leads.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(1, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');
    }

    @isTest
    private static void testLeadCreateNoIdentity() {
        User ownerUser = heap_TestFixtures.fakeUserCreator('BobTesterHeap');
        Lead newLead = heap_TestFixtures.leadCreator(
            'FakeLName',
            'Fake InnewContact. Company',
            'Qualified'
        );
        newLead.LeadSource = 'test';
        newLead.OwnerId = ownerUser.Id;
        List<Lead> leadList = new List<Lead>{
            newLead
        };
        heap_Leads leads = new heap_Leads(leadList);
        Map<Id, Lead> oldMap = new Map<Id, Lead>();
        oldMap.put(newLead.Id, newLead);
        heap_Calls calls = leads.handleTrigger(new heap_Calls(), true, false, oldMap);
        leads.addUserProperties(calls);

        System.assertEquals(0, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(0, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');
    }

    @isTest
    private static void testLeadUpdateUntrackedField() {
        /**
         * If an untracked field is changed, we should not fire an event
         * since it will appear duplicated to the Heap user.
         *
         * In this test setup, we only track LastName for Leads, so a modification to LeadSource shouldn't
         * fire a new event
         
        User ownerUser = heap_TestFixtures.fakeUserCreator('BobTesterHeap');
        Lead newLead = heap_TestFixtures.leadCreator(
            'FakeLName',
            'Fake InnewContact. Company',
            'Qualified'
        );
        newLead.Email = 'test123@test.org';
        newLead.LeadSource = 'test';
        newLead.OwnerId = ownerUser.Id;
        Lead updatedLead = newLead.clone(true, true, true, true);
        updatedLead.LeadSource = 'new Value';


        List<Lead> leadList = new List<Lead>{
            newLead
        };
        heap_Leads leads = new heap_Leads(leadList);
        Map<Id, Lead> oldMap = new Map<Id, Lead>();
        oldMap.put(updatedLead.Id, updatedLead);
        heap_Calls calls = leads.handleTrigger(new heap_Calls(), false, true, oldMap);
        leads.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(0, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');
    }

    @isTest
    private static void testLeadUpdateTrackedField() {
        /**
         * We track LastName for Leads, so a change to that field _should_ fire an event
         
        User ownerUser = heap_TestFixtures.fakeUserCreator('BobTesterHeap');
        Lead newLead = heap_TestFixtures.leadCreator(
                'FakeLName',
                'Fake InnewContact. Company',
                'Qualified'
        );
        newLead.Email = 'test123@test.org';
        newLead.LeadSource = 'test';
        newLead.OwnerId = ownerUser.Id;
        Lead updatedLead = newLead.clone(true, true, true, true);
        updatedLead.LastName = 'New FakeLName';


        List<Lead> leadList = new List<Lead>{
                newLead
        };
        heap_Leads leads = new heap_Leads(leadList);
        Map<Id, Lead> oldMap = new Map<Id, Lead>();
        oldMap.put(updatedLead.Id, updatedLead);
        heap_Calls calls = leads.handleTrigger(new heap_Calls(), false, true, oldMap);
        leads.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(1, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');
    }

    @isTest
    private static void testOpportunityInsert(){
        User ownerUser = heap_TestFixtures.fakeUserCreator('BobTesterHeap');
        ownerUser.Id = getFakeId(User.SObjectType);

        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.BillingCountry = 'Canada';
        newAccount.Id = getFakeId(Account.SObjectType);

        Contact newContact = heap_TestFixtures.contactCreator(
            newAccount.Id,
            'FirstName',
            'LastName',
            false
        );
        newContact.Email = 'testing123@test.org';
        newContact.Id = getFakeId(Contact.SObjectType);

        Map<Schema.SObjectField, Object> opFieldMap = new Map<Schema.SObjectField, Object>{
            Opportunity.Name => 'OpName',
            Opportunity.Type => 'Support',
            Opportunity.CloseDate => Date.newInstance(2018, 1, 1),
            Opportunity.StageName => 'Closed - Not Won',
            Opportunity.Amount => 14500,
            Opportunity.OwnerId => ownerUser.Id,
            Opportunity.AccountId => newAccount.Id
        };

        Opportunity op = new Opportunity();
        for (Schema.SObjectField field : opFieldMap.keySet()){
            op.put(field, opFieldMap.get(field));
        }

        List<Opportunity> opList = new List<Opportunity>{op};

        heap_Opportunities ops = new heap_Opportunities(opList);
        ops.contacts = new List<Contact>{newContact};
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();

        heap_Calls calls = ops.handleTrigger(new heap_Calls(), true, false, oldMap);

        ops.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(1, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');

        //TODO we should make sure that the events look right
    }


    @isTest
    private static void testOpportunityUpdateUntrackedField(){
        /**
         * If an untracked field is changed, we should not fire an event
         * since it will appear duplicated to the Heap user.
         *
         * In this test setup, we only track StageName for Opportunities, so a modification to Name shouldn't
         * fire a new event
         
        User ownerUser = heap_TestFixtures.fakeUserCreator('BobTesterHeap');
        ownerUser.Id = getFakeId(User.SObjectType);

        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.BillingCountry = 'Canada';
        newAccount.Id = getFakeId(Account.SObjectType);

        Contact newContact = heap_TestFixtures.contactCreator(
            newAccount.Id,
            'FirstName',
            'LastName',
            false
        );
        newContact.Email = 'testing123@test.org';
        newContact.Id = getFakeId(Contact.SObjectType);


        Opportunity op = heap_TestFixtures.opportunityCreator(
            'Name',
            'Closed - Not Won'
        );
        op.OwnerId = ownerUser.Id;
        op.AccountId = newAccount.Id;
        op.Type = 'Support';
        op.CloseDate = Date.newInstance(2018, 1, 1);
        op.Amount = 14500;

        Test.startTest();

        Opportunity oldOp = op.clone(true, true, true, true);
        oldOp.Name = 'Some new Name' ;

        List<Opportunity> opList = new List<Opportunity>{
            op
        };

        heap_Opportunities ops = new heap_Opportunities(opList);
        ops.contacts = new List<Contact>{newContact};
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{oldOp.Id => oldOp};
        Test.stopTest();

        heap_Calls calls = ops.handleTrigger(new heap_Calls(), false, true, oldMap);
        ops.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(0, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');

        //TODO we should make sure that the events look right
    }

    @isTest
    private static void testOpportunityUpdateTrackedField(){
        /**
         * We track StageName for Opportunities, so a change to that field _should_ fire an event
         
        User ownerUser = heap_TestFixtures.fakeUserCreator('BobTesterHeap');
        ownerUser.Id = getFakeId(User.SObjectType);

        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.BillingCountry = 'Canada';
        newAccount.Id = getFakeId(Account.SObjectType);

        Contact newContact = heap_TestFixtures.contactCreator(
                newAccount.Id,
                'FirstName',
                'LastName',
                false
        );
        newContact.Email = 'testing123@test.org';
        newContact.Id = getFakeId(Contact.SObjectType);


        Opportunity op = heap_TestFixtures.opportunityCreator(
                'Name',
                'Closed - Not Won'
        );
        op.OwnerId = ownerUser.Id;
        op.AccountId = newAccount.Id;
        op.Type = 'Support';
        op.CloseDate = Date.newInstance(2018, 1, 1);
        op.Amount = 14500;

        Test.startTest();

        Opportunity oldOp = op.clone(true, true, true, true);
        oldOp.StageName = 'Some new StageName' ;

        List<Opportunity> opList = new List<Opportunity>{
                op
        };

        heap_Opportunities ops = new heap_Opportunities(opList);
        ops.contacts = new List<Contact>{newContact};
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{oldOp.Id => oldOp};
        Test.stopTest();

        heap_Calls calls = ops.handleTrigger(new heap_Calls(), false, true, oldMap);
        ops.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(1, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');

        //TODO we should make sure that the events look right
    }

    @isTest
    public static void testAccountInsert(){
        User ownerUser = heap_TestFixtures.fakeUserCreator('BobTesterHeap');
        ownerUser.Id = getFakeId(User.SObjectType);

        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.BillingCountry = 'Canada';
        newAccount.OwnerId = ownerUser.Id;
        newAccount.Id = getFakeId(Account.SObjectType);

        Contact newContact = heap_TestFixtures.contactCreator(
            newAccount.Id,
            'FirstName',
            'LastName',
            false
        );
        newContact.Email = 'testing123@test.org';
        newContact.Id = getFakeId(Contact.SObjectType);

        Contact newContact2 = heap_TestFixtures.contactCreator(
            newAccount.Id,
            'FirstName2',
            'LastName2',
            false
        );
        newContact2.Email = 'testing234@test.org';
        newContact2.Id = getFakeId(Contact.SObjectType);

        newAccount.Name = 'Test Account';

        heap_Accounts accts = new heap_Accounts(new List<Account>{newAccount});
        accts.contactsByAccountId = new Map<Id, List<Contact>>{newAccount.Id => new List<Contact>{newContact, newContact2}};
        heap_Calls calls = accts.handleTrigger(new heap_Calls(), true, false, new Map<Id, Account>());
        accts.addUserProperties(calls);

        System.assertEquals(2, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(2, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');

    }

    @isTest
    public static void testAccountInsertNoIdentity(){
        User ownerUser = heap_TestFixtures.fakeUserCreator('BobTesterHeap');
        ownerUser.Id = getFakeId(User.SObjectType);

        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.BillingCountry = 'Canada';
        newAccount.OwnerId = ownerUser.Id;
        newAccount.Id = getFakeId(Account.SObjectType);

        Contact newContact = heap_TestFixtures.contactCreator(
            newAccount.Id,
            'FirstName',
            'LastName',
            false
        );
        newContact.Id = getFakeId(Contact.SObjectType);

        Contact newContact2 = heap_TestFixtures.contactCreator(
            newAccount.Id,
            'FirstName2',
            'LastName2',
            false
        );
        newContact2.Email = 'testing234@test.org';
        newContact2.Id = getFakeId(Contact.SObjectType);

        newAccount.Name = 'Test Account';

        heap_Accounts accts = new heap_Accounts(new List<Account>{newAccount});
        accts.contactsByAccountId = new Map<Id, List<Contact>>{newAccount.Id => new List<Contact>{newContact, newContact2}};
        heap_Calls calls = accts.handleTrigger(new heap_Calls(), true, false, new Map<Id, Account>());
        accts.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(1, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');
    }

    @isTest
    public static void testAccountUpdateUntrackedField(){
        /**
         * If an untracked field is changed, we should not fire an event
         * since it will appear duplicated to the Heap user.
         *
         * In this test setup, we only track Name for Accounts, so a modification to Site shouldn't
         * fire a new event
         
        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.Id = getFakeId(Account.SObjectType);
        newAccount.BillingCountry = 'Canada';

        Contact newContact = heap_TestFixtures.contactCreator(
            newAccount.Id,
            'FirstName',
            'LastName',
            false
        );
        newContact.Email = 'testing123@test.org';
        newContact.Id = getFakeId(Contact.SObjectType);

        newAccount.Name = 'Test Account';

        Account updatedAcct = newAccount.clone(true, true, true, true);
        updatedAcct.Site = 'Random Site';

        heap_Accounts accts = new heap_Accounts(new List<Account>{newAccount});
        accts.contactsByAccountId = new Map<Id, List<Contact>>{newAccount.Id => new List<Contact>{newContact}};

        heap_Calls calls = accts.handleTrigger(new heap_Calls(), false, true, new Map<Id, Account>{updatedAcct.Id => updatedAcct});
        accts.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(0, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');

    }

    @isTest
    public static void testAccountUpdateTrackedField(){
        /**
         * We track Name for Accounts, so a change to that field _should_ fire an event
         
        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.Id = getFakeId(Account.SObjectType);
        newAccount.BillingCountry = 'Canada';

        Contact newContact = heap_TestFixtures.contactCreator(
                newAccount.Id,
                'FirstName',
                'LastName',
                false
        );
        newContact.Email = 'testing123@test.org';
        newContact.Id = getFakeId(Contact.SObjectType);

        newAccount.Name = 'Test Account';

        Account updatedAcct = newAccount.clone(true, true, true, true);
        updatedAcct.Name = 'Updated Account Name';

        heap_Accounts accts = new heap_Accounts(new List<Account>{newAccount});
        accts.contactsByAccountId = new Map<Id, List<Contact>>{newAccount.Id => new List<Contact>{newContact}};

        heap_Calls calls = accts.handleTrigger(new heap_Calls(), false, true, new Map<Id, Account>{updatedAcct.Id => updatedAcct});
        accts.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(1, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');

    }

    @isTest
    public static void testContactInsert(){
        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.Id = getFakeId(Account.SObjectType);

        Contact newContact = heap_TestFixtures.contactCreator(
            newAccount.Id,
            'FirstName',
            'LastName',
            false
        );
        newContact.Email = 'testing123@test.org';
        newContact.Title = 'title';
        newContact.Phone = '333-3333';
        newContact.Id = getFakeId(Contact.SObjectType);

        heap_Contacts contacts = new heap_Contacts(new List<Contact>{newContact});
        heap_Calls calls = contacts.handleTrigger(new heap_Calls(), true, false, new Map<Id, Contact>());
        contacts.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(1, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');
    }

    @isTest
    public static void testContactUpdateUntrackedField(){
        /**
         * If an untracked field is changed, we should not fire an event
         * since it will appear duplicated to the Heap user.
         *
         * In this test setup, we only track LastName for Contacts, so a modification to Title shouldn't
         * fire a new event
         
        Account newAccount = heap_TestFixtures.accountCreator('My Account');

        Contact newContact = heap_TestFixtures.contactCreator(
            newAccount.Id,
            'FirstName',
            'LastName',
            false
        );
        newContact.Email = 'testing123@test.org';

        newContact.Title = 'title';
        newContact.Phone = '333-3333';

        Contact updatedContact = newContact.clone(true, true, true, true);
        updatedContact.Title = 'New Title';

        heap_Contacts contacts = new heap_Contacts(new List<Contact>{updatedContact});

        heap_Calls calls = contacts.handleTrigger(new Heap_Calls(), false, true, new Map<Id, Contact>{newContact.Id => newContact});
        contacts.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(0, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');
    }

    @isTest
    public static void testContactUpdateTrackedField(){
        /**
         * We track LastName for Contacts, so a change to that field _should_ fire an event
         
        Account newAccount = heap_TestFixtures.accountCreator('My Account');

        Contact newContact = heap_TestFixtures.contactCreator(
                newAccount.Id,
                'FirstName',
                'LastName',
                false
        );
        newContact.Email = 'testing123@test.org';

        newContact.Title = 'title';
        newContact.Phone = '333-3333';

        Contact updatedContact = newContact.clone(true, true, true, true);
        updatedContact.LastName = 'New LastName';

        heap_Contacts contacts = new heap_Contacts(new List<Contact>{updatedContact});

        heap_Calls calls = contacts.handleTrigger(new Heap_Calls(), false, true, new Map<Id, Contact>{newContact.Id => newContact});
        contacts.addUserProperties(calls);

        System.assertEquals(1, calls.userPropertyCalls.users.size(), 'userPropertyCalls user size doesnt match');
        System.assertEquals(1, calls.trackingCalls.events.size(), 'trackingCalls events size doesnt match');
    }

    @isTest
    private static void testAccountChanges() {
        heap_MockHttp http = new heap_MockHttp();
        Test.setMock(HttpCalloutMock.class, http);
        heap_MockHeapService mockHeapService = new heap_MockHeapService();

        Account newAccount = new Account(
                Name = 'Test Ac'
        );
        newAccount.Id = getFakeId(Account.SObjectType);

        Contact newContact = new Contact(
                FirstName = 'Testy',
                LastName = 'McTesterson',
                Email = 'Test@test.com',
                AccountId = newAccount.Id
        );
        newAccount.Id = getFakeId(Account.SObjectType);
        newAccount.Type = 'Paying Customer';

        heap_Calls calls = new heap_Calls();
        calls.service = mockHeapService;

        heap_Accounts accts = new heap_Accounts(new List<Account> { newAccount });
        heap_Contacts contacts = new heap_Contacts(new List<Contact> { newContact });

        contacts.addUserProperties(calls);
        accts.addUserProperties(calls);
        calls.call();
    }

    @isTest
    public static void testConfigurationControllerOpportunityFields() {
        heap_ConfigurationController controller = new heap_ConfigurationController();
        List<SelectOption> options = controller.getOpportunityFields();
        System.assertEquals('--Select--', options[0].getLabel());
        System.assertEquals('', options[0].getValue());
    }

    @isTest
    public static void testConfigurationControllerContactFields() {
        heap_ConfigurationController controller = new heap_ConfigurationController();
        List<SelectOption> options = controller.getContactFields();
        System.assertEquals('--Select--', options[0].getLabel());
        System.assertEquals('', options[0].getValue());
    }

    @isTest
    public static void testConfigurationControllerLeadFields() {
        heap_ConfigurationController controller = new heap_ConfigurationController();
        List<SelectOption> options = controller.getLeadFields();
        System.assertEquals('--Select--', options[0].getLabel());
        System.assertEquals('', options[0].getValue());
    }

    @isTest
    public static void testConfigurationControllerBackfillClasses() {
        heap_ConfigurationController controller = new heap_ConfigurationController();
        List<SelectOption> backfillClasses = controller.getBackfillClasses();
        System.assertEquals(heap_Configuration.backfillClasses.size(),
                            backfillClasses.size(),
                            'backfill class size mismatch');
    }

    @isTest
    public static void testConfigurationControllerStartBackfill() {
        heap_ConfigurationController controller = new heap_ConfigurationController();
        controller.backfillClass = heap_Contacts.class.toString();
        controller.startBackfill();
        ApexPages.Message msg = ApexPages.getMessages()[0];
        System.assertEquals('Backfill started for ' + controller.backfillClass, msg.getDetail());
    }

    @isTest
    public static void testObjectFieldControllerObjectTypes() {
        heap_ObjectFieldController ofc = new heap_ObjectFieldController();
        // :TODO: (talos): this is asinine and would break with custom objects, but the tested code will need to change anyway
        System.assertEquals(5, ofc.getObjectTypes().size(), 'There are four object types plus "select"');
    }

    @isTest
    public static void testObjectFieldControllerObjectFields() {
        heap_ObjectFieldController ofc = new heap_ObjectFieldController();
        System.assertEquals(1, ofc.getObjectFields().size(), 'There is only "select" before an object is selected"');
        ofc.selectedObject = 'account';
        System.assert(ofc.getObjectFields().size() > 1, 'There are additional fields options when option selected');
    }

    @isTest
    public static void testObjectFieldControllerIsReferenceField() {
        heap_ObjectFieldController ofc = new heap_ObjectFieldController();
        ofc.selectedObject = 'account';
        ofc.selectedField = 'accountsource';
        System.assert(!ofc.getIsReferenceField(), 'account.accountsource is not a reference field');
        ofc.selectedField = 'ownerid';
        System.assert(ofc.getIsReferenceField(), 'account.ownerid is a reference field');
    }

    @isTest
    public static void testObjectFieldControllerReferenceObjectFields() {
        heap_ObjectFieldController ofc = new heap_ObjectFieldController();
        ofc.selectedObject = 'account';
        ofc.selectedField = 'ownerid';
        System.assert(ofc.getReferenceObjectFields().size() > 1, 'account.ownerid references other fields');
    }

    @isTest
    public static void testObjectFieldControllerCurrentObjectFieldMappings() {
        heap_ObjectFieldController ofc = new heap_ObjectFieldController();
        Map<String, List<heap_ObjectFieldController.ObjectFieldWrapper>> cofm = ofc.getCurrentObjectFieldMappings();
    }

    @isTest
    public static void testObjectFieldControllerAdd() {
        heap_ObjectFieldController ofc = new heap_ObjectFieldController();
        ofc.add();
        ApexPages.Message msg = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Warning, msg.getSeverity(), 'Should be warned if empty field added.');

        String obj = 'account';
        String field = 'name';
        ofc.selectedObject = obj;
        ofc.selectedField = field;
        String name = new ObjectFieldMapping(obj, field, null, null).getObjectName();

        ofc.add();
        System.assertEquals(obj, ofc.selectedObject, 'heap_ObjectFieldController.add should not reset selectedObject');
        System.assertEquals('', ofc.selectedField, 'heap_ObjectFieldController.add should reset selectedField');
        Integer cnt = [SELECT count() from heap_ObjectFieldMapping__c WHERE Name = :name];
        System.assertEquals(1, cnt, 'heap_ObjectFieldController.add should have added an entry to heap_ObjectFieldMapping__c');

        // Adding field again shouldn't make any difference
        ofc.selectedField = field;
        ofc.add();

        cnt = [SELECT count() from heap_ObjectFieldMapping__c WHERE Name = :name];
        System.assertEquals(1, cnt, 'heap_ObjectFieldController.add should have added no more entries to heap_ObjectFieldMapping__c');
    }

    //@isTest
    //public static void testAccountsHydration() {
    //    Account newAccount = heap_TestFixtures.accountCreator('My Account');
    //    insert newAccount;
    //    Contact newContact = heap_TestFixtures.contactCreator(
    //            newAccount.Id,
    //            'FirstName',
    //            'LastName',
    //            false
    //    );
    //    newContact.Email = 'foo@bar.com';
    //    insert newContact;
    //    heap_Accounts accts = new heap_Accounts();
    //    accts.hydrateFromIdentities(new List<String>{ newContact.Email });

    //    System.assertEquals(1, accts.records.size(), 'Should have hydrated 1 existing account');
    //    // :TODO: (talos): why do we get duplicate contacts with same ID in Account.Contacts?
    //    //System.assertEquals(1, accts.contacts.size(), 'Hydrated account should have 1 contact');
    //}

    //@isTest
    //public static void testContactsHydration() {
    //    Account newAccount = heap_TestFixtures.accountCreator('My Account');
    //    insert newAccount;
    //    Contact newContact = heap_TestFixtures.contactCreator(
    //            newAccount.Id,
    //            'FirstName',
    //            'LastName',
    //            false
    //    );
    //    newContact.Email = 'foo@bar.com';
    //    insert newContact;

    //    heap_Contacts contacts = new heap_Contacts();
    //    contacts.hydrateFromIdentities(new List<String>{ newContact.Email });

    //    System.assertEquals(1, contacts.records.size(), 'Should have hydrated 1 existing Contact');

    //    List<String> identities = contacts.getIdentities();
    //    System.assertEquals(1, identities.size(), 'GetIdentities should return 1 identity');
    //    System.assertEquals(newContact.Email, identities[0], 'GetIdentities should return correct email');
    //}

    //@isTest
    //public static void testLeadsHydration() {
    //    Lead newLead = heap_TestFixtures.leadCreator(
    //            'LastName',
    //            'Company',
    //            'status'
    //    );
    //    newLead.email = 'foo@bar.com';
    //    insert newLead;

    //    heap_Leads leads = new heap_Leads();
    //    leads.hydrateFromIdentities(new List <String>{ newLead.Email });

    //    System.assertEquals(1, leads.records.size(), 'Should have hydrated 1 existing Lead');
    //}

    // It is not possible to test any code that pulls histories from the database:
    // https://salesforce.stackexchange.com/questions/4007/is-it-possible-to-test-apex-that-relies-on-field-history-tracking
    @isTest
    public static void testLeadHistoriesById() {
        Lead lead1 = heap_TestFixtures.leadCreator( 'LastNameLead1', 'Company', 'opened' );
        Lead lead2 = heap_TestFixtures.leadCreator( 'LastNameLead2', 'Company', 'opened' );
        Lead lead3 = heap_TestFixtures.leadCreator( 'LastNameLead3', 'Company', 'opened' );
        lead1.Id = getFakeId(Lead.SObjectType);
        lead2.Id = getFakeId(Lead.SObjectType);
        lead3.Id = getFakeId(Lead.SObjectType);

        heap_Leads leads = new heap_Leads(new List<Lead> { lead1, lead2, lead3 });
        leads.db = (heap_DBHelper) Test.createStub(heap_DBHelper.class, new heap_MockDB(new List<List<SObject>> {
            new List<LeadHistory> {
                new LeadHistory(LeadId=lead1.id),
                new LeadHistory(LeadId=lead1.id),
                new LeadHistory(LeadId=lead2.id)
            }
        }));

        Map<Id, List<List<LeadHistory>>> historiesById = leads.historiesByLeadId;
        System.assertEquals(1, historiesById.get(lead1.Id).size(), 'Lead1 has one change date');
        System.assertEquals(2, historiesById.get(lead1.Id)[0].size(), 'Lead1 has two changes on that date');

        System.assertEquals(1, historiesById.get(lead2.Id).size(), 'Lead2 has one change date');
        System.assertEquals(1, historiesById.get(lead2.Id)[0].size(), 'Lead2 has one change on that date');

        System.assertEquals(0, historiesById.get(lead3.id).size(), 'Lead3 has no changes');
    }

    @isTest
    public static void testOpportunitiesHydration() {
        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.Id = getFakeId(Account.SObjectType);

        Contact newContact = heap_TestFixtures.contactCreator(
                newAccount.Id,
                'FirstName',
                'LastName',
                false
        );
        newContact.Email = 'foo@bar.com';
        newContact.Id = getFakeId(Contact.SObjectType);

        Opportunity newOpp = heap_TestFixtures.opportunityCreator(
                'opportunity name',
                'status'
        );
        newOpp.accountId = newAccount.Id;
        newOpp.CloseDate = Datetime.now().date();
        newOpp.Id = getFakeId(Opportunity.SObjectType);

        heap_Opportunities opps = new heap_Opportunities();
        opps.hydrateFromIdentities(new List <String>{ newContact.Email });

        //System.assertEquals(1, opps.records.size(), 'Should have hydrated 1 existing Opportunity');
        // :TODO: (talos): why do we get duplicate contacts with same ID in Opportunity.Contacts?
        //System.assertEquals(1, opps.contacts.size(), 'Hydrated account should have 1 Contact.');
    }

    // It is not possible to test any code that pulls histories from the database:
    // https://salesforce.stackexchange.com/questions/4007/is-it-possible-to-test-apex-that-relies-on-field-history-tracking
    // Therefore we instead use `heap_DBHelper` to fake out History sObjects
    @isTest
    public static void testOpportunitiesFieldHistoriesByOpportunityId() {
        Account newAccount = heap_TestFixtures.accountCreator('My Account');
        newAccount.Id = getFakeId(Account.SObjectType);
        Contact newContact = heap_TestFixtures.contactCreator(
                newAccount.Id,
                'FirstName',
                'LastName',
                false
        );
        newContact.Email = 'foo@bar.com';
        newContact.Id = getFakeId(Contact.SObjectType);

        Opportunity opp1 = heap_TestFixtures.opportunityCreator( 'opp1', 'status' );
        opp1.accountId = newAccount.Id;
        opp1.CloseDate = Datetime.now().date();
        opp1.Id=getFakeId(Opportunity.SObjectType);

        heap_Opportunities opps = new heap_Opportunities(new List<Opportunity> { opp1 });
        opps.db = (heap_DBHelper) Test.createStub(heap_DBHelper.class, new heap_MockDB(new List<List<SObject>> {
            new List<OpportunityFieldHistory> {
                new OpportunityFieldHistory(OpportunityId=opp1.id)
            }
        }));

        Map<Id, List<List<OpportunityFieldHistory>>> oppFieldHistById = opps.fieldHistoriesByOpportunityId;
        System.assertEquals(1, oppFieldHistById.get(opp1.Id).size(), 'Opp1 has one change date');
        System.assertEquals(1, oppFieldHistById.get(opp1.Id)[0].size(), 'Opp1 has one changes on that date');
    }

    //@isTest
    //public static void testOpportunitiesBulkBackloadEmpty() {
    //    heap_Opportunities opps = new heap_Opportunities();
    //    heap_Calls calls = opps.bulkBackload();
    //    System.assertEquals(0, calls.trackingCalls.events.size(), 'No opportunities -> no tracking calls');
    //    System.assertEquals(0, calls.userPropertyCalls.users.size(), 'No opportunities -> no user property calls');
    //}

    //@isTest
    //public static void testOpportunitiesBulkBackloadOneOppNoHistory() {
    //    Account newAccount = heap_TestFixtures.accountCreator('My Account');
    //    insert newAccount;
    //    Contact newContact = heap_TestFixtures.contactCreator(
    //            newAccount.Id,
    //            'FirstName',
    //            'LastName',
    //            false
    //    );
    //    newContact.Email = 'foo@bar.com';
    //    insert newContact;
    //    Opportunity newOpp = heap_TestFixtures.opportunityCreator(
    //            'opportunity name',
    //            'status'
    //    );
    //    newOpp.accountId = newAccount.Id;
    //    newOpp.CloseDate = Datetime.now().date();
    //    insert newOpp;

    //    heap_Opportunities opps = new heap_Opportunities(new List<Opportunity> { newOpp });
    //    heap_Calls calls = opps.bulkBackload();
    //    System.assertEquals(0, calls.trackingCalls.events.size(), '1 opportunity w no history -> no tracking calls');
    //    System.assertEquals(1, calls.userPropertyCalls.users.size(), '1 opportunity -> 1 user property call');
    //}

    //@isTest
    //public static void testOpportunitiesBulkBackloadOneOppOneChange() {
    //    Date today = Datetime.now().date();
    //    Account newAccount = heap_TestFixtures.accountCreator('My Account');
    //    insert newAccount;
    //    Contact newContact = heap_TestFixtures.contactCreator(
    //            newAccount.Id,
    //            'FirstName',
    //            'LastName',
    //            false
    //    );
    //    newContact.Email = 'foo@bar.com';
    //    insert newContact;
    //    Opportunity newOpp = heap_TestFixtures.opportunityCreator(
    //            'opportunity name',
    //            'status'
    //    );
    //    newOpp.accountId = newAccount.Id;
    //    newOpp.CloseDate = today;
    //    newOpp.StageName = 'Closed';
    //    insert newOpp;

    //    newOpp.StageName = 'Won';
    //    update newOpp;

    //    heap_Opportunities opps = new heap_Opportunities(new List<Opportunity> { newOpp });

    //    // Mock out opportunity history responses in our database
    //    List<OpportunityHistory> dbResp1 = new List<OpportunityHistory> {
    //        heap_TestFixtures.opportunityHistoryCreator(newOpp, 'Won', today)
    //    };
    //    List<OpportunityFieldHistory> dbResp2 = new List<OpportunityFieldHistory> {
    //        heap_TestFixtures.opportunityFieldHistoryCreator(newOpp, 'Stage', 'Won', 'Closed')

    //    };
    //    opps.db = (heap_DBHelper) Test.createStub(heap_DBHelper.class, new heap_MockDB(new List<List<SObject>> {
    //        dbResp1, dbResp2
    //    }));

    //    heap_Calls calls = opps.bulkBackload();

    //    System.assertEquals(1, calls.trackingCalls.events.size(), '1 opportunity w 1 history -> 1 tracking call');
    //    System.assertEquals(1, calls.userPropertyCalls.users.size(), '1 opportunity -> 1 user property call');
    //}

    //@isTest
    //public static void testLeadsBulkBackloadEmpty() {
    //    heap_Leads leads = new heap_Leads();
    //    heap_Calls calls = leads.bulkBackload();
    //    System.assertEquals(0, calls.trackingCalls.events.size(), 'No leads -> no tracking calls');
    //    System.assertEquals(0, calls.userPropertyCalls.users.size(), 'No leads -> no user property calls');
    //}

    //@isTest
    //public static void testLeadsBulkBackloadLeadHistoryChanges() {
    //    Lead lead1 = heap_TestFixtures.leadCreator( 'LastNameLead1', 'Company', 'opened' );
    //    Lead lead2 = heap_TestFixtures.leadCreator( 'LastNameLead2', 'Company', 'opened' );
    //    Lead lead3 = heap_TestFixtures.leadCreator( 'LastNameLead3', 'Company', 'opened' );
    //    lead1.email = 'foo1@bar.com';
    //    lead2.email = 'foo2@bar.com';
    //    lead3.email = 'foo3@bar.com';
    //    insert lead1;
    //    insert lead2;
    //    insert lead3;

    //    heap_Leads leads = new heap_Leads(new List<Lead> { lead1, lead2, lead3 });
    //    List<LeadHistory> dbResp1 = new List<LeadHistory> {
    //        heap_TestFixtures.leadHistoryCreator(lead1, 'LastName', 'LastNameLead1', 'NewLastNameLead1'),
    //        heap_TestFixtures.leadHistoryCreator(lead2, 'LastName', 'LastNameLead2', 'NewLastNameLead2')
    //    };

    //    // :TODO: (talos): triple dbResp below is covering for a bug in Leads where the DB is called once per lead
    //    leads.db = (heap_DBHelper) Test.createStub(heap_DBHelper.class, new heap_MockDB(new List<List<SObject>> {
    //        dbResp1,
    //        dbResp1,
    //        dbResp1
    //    }));
    //    heap_Calls calls = leads.bulkBackload();

    //    System.assertEquals(3, calls.userPropertyCalls.users.size(), '3 leads -> 3 user property calls');

    //    // :TODO: (talos): the below does not behave as expected, yielding 0 calls
    //    //System.assertEquals(2, calls.trackingCalls.events.size(), '2 changes  -> 2 tracking calls');
    //}

    @isTest
    public static void testBatchUserProperties() {
        heap_MockHttp http = new heap_MockHttp();
        Test.setMock(HttpCalloutMock.class, http);
        heap_MockHeapService mockHeapService = new heap_MockHeapService();

        List<String> identities = new List<String>{'test@foo.com'};


        heap_Calls calls = new heap_Calls();
        calls.service = mockHeapService;
        heap_BatchUserProperties batch = new heap_BatchUserProperties(identities, Type.forName('heap_Opportunities'));
        batch.setCalls(calls);
        Database.executeBatch(batch, 10);
    }*/

}
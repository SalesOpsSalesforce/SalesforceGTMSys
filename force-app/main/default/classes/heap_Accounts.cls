public with sharing class heap_Accounts extends heap_Base implements heap_IUserPropertySource{
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_Accounts(){}
    public override void addUserProperties(){
    }
   /* public List<Contact> contacts {
        get {
            if (null == contacts) {
                contacts = [
                        SELECT Id, AccountId, Email, Name
                        FROM Contact
                        WHERE AccountId IN :getIds()
                ];
            }
            return contacts;
        }
        public set;
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
        public set;
    }
    public heap_Accounts(List<SObject> accounts){
        records = accounts;
    }

    public heap_Accounts(){
        records = new List<SObject>();
    }

    public override Type getObjectType(){
        return Account.class;
    }

    public override void addUserProperties(heap_Calls calls){
        for (Account acct : (List<Account>)records){
            List<String> identities = getIdentities(acct);
            Map<String, Object> userProperties = getPropertyValues(acct, null);
            calls.addProperties(identities, userProperties);
        }
    }

    public void hydrateFromIdentities(List<String> identities) {
        String queryString = hydrationQuery(identities);
        hydrateFromQueryResults(Database.query(queryString));
    }

    public void hydrateFromQueryResults(List<SObject> results) {
        records.addAll(results);
        for (Account accountEntry: (List<Account>)results) {
            contacts.addAll(accountEntry.Contacts);
        }
    }

    public String hydrationQuery(List<String> identities) {
        return 'SELECT ' + ofMappings.queryString(getObjectType().getName()) +
                ', (SELECT AccountId, ' + heap_Configuration.heapSettings.ContactIdentity__c + ' FROM Contacts) ' +
                ' FROM Account ' +
                ' WHERE Id IN ' +
                ' (Select AccountId FROM Contact WHERE ' + heap_Configuration.heapSettings.ContactIdentity__c + ' IN :identities)';
    }

    public override List<String> getIdentities(){
        Set<String> identities = new Set<String>();
        for (List<Contact> contacts : contactsByAccountId.values()) {
            for(Contact contactEntry: contacts) {
                String identity = getIdentity(contactEntry);
                if (null == identity) continue;
                identities.add(identity);
            }
        }
        List<String> returns = new List<String>();
        returns.addAll(identities);
        return returns;
    }

    public override List<String> getIdentities(SObject record){
        List<String> returns = new List<String>();
        List<Contact> accountContacts = contactsByAccountId.get((Id)record.get('Id'));
        if (null != accountContacts){
            for ( Contact accountContact: accountContacts) {
                String identity = getIdentity(accountContact);
                if (null != identity ) {
                    returns.add(identity);
                }
            }
        }
        return returns;
    }

    public override heap_Calls bulkBackload() {
        System.debug(records);
        heap_Calls calls = new heap_Calls();
        addUserProperties(calls);
        return calls;
    }*/


}
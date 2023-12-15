public with sharing class heap_Contacts extends heap_Base implements heap_IUserPropertySource {
	//[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
	// For code coverage while deploying commented methods
    public heap_Contacts(){}
    public override void addUserProperties(){
    }
    /*public heap_Contacts() {
        records = new List<SObject>();
    }
    public heap_Contacts(List<SObject> contacts) {
        records = contacts;
    }

    public override Type getObjectType(){
        return Contact.class;
    }

    public void hydrateFromIdentities(List<String> identities){
        hydrateFromQueryResults(Database.query(hydrationQuery(identities)));
    }

    public void hydrateFromQueryResults(List<SObject> results) {
        records.addAll((List<SObject>)results);
    }

    public String hydrationQuery(List<String> identities) {
        String objectQueryString = ofMappings.queryString(getObjectType().getName());
        if (!ofMappings.containsField(getObjectType().getName(), 'Email')){
            objectQueryString += ', Email';
        }
        return 'SELECT ' + objectQueryString +
                ' FROM Contact ' +
                ' WHERE ' + heap_Configuration.heapSettings.ContactIdentity__c + ' IN :identities';
    }

    public override List<String> getIdentities(){
        List<String> identities = new List<String>();
        for (Contact c : (List<Contact>)records) {
            String identity = getIdentity(c);
            if (null == identity) continue;
            identities.add(identity);
        }
        return identities;
    }
    public override List<String> getIdentities(SObject record){
        List<String> toRet = new List<String>();
        String identity = getIdentity(record);
        if (null != identity) {
            toRet.add(identity);
        }
        return toRet;
    }

    public override void addUserProperties(heap_Calls calls){
        for (Contact identityContact: (List<Contact>)records) {
            String identity = getIdentity(identityContact);
            if (null != identity) {
                Map<String, Object> userProperties = getPropertyValues(identityContact, null);
                calls.addProperties(identity, userProperties);
            }
        }
    }

    public override heap_Calls bulkBackload() {
        heap_Calls calls = new heap_Calls();
        addUserProperties(calls);
        return calls;
    }*/
}
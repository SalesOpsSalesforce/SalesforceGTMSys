public with sharing class heap_Calls {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration 
    // For code coverage while deploying commented methods
    public heap_Calls(){}
    /*public heap_TrackingCall trackingCalls;
    public heap_UserPropertyCall userPropertyCalls;
    public heap_IHeapService service = new heap_HeapService();

    public heap_Calls() {
        trackingCalls = new heap_TrackingCall();
        userPropertyCalls = new heap_UserPropertyCall();
    }

    public heap_Calls(heap_TrackingCall trackingCalls_c, heap_UserPropertyCall userPropertyCalls_c) {
        trackingCalls = trackingCalls_c;
        userPropertyCalls = userPropertyCalls_c;
    }

    // TODO this could probably use a better name
    public void call(){
        List<String> trackingCallJson = trackingCalls.toJSON();
        if (null != trackingCallJson) {
            System.debug(trackingCallJson);
            service.call(trackingCallJson, 'track');
        }
        List<String> userPropertyCallJson = userPropertyCalls.toJSON();
        if (null != userPropertyCallJson) {
            service.call(userPropertyCallJson, 'add_user_properties');
        }
    }

    public void backloadCall() {
        List<String> trackingCallJson = trackingCalls.toJSON();
        if (null != trackingCallJson) {
            service.syncCall(trackingCallJson, 'track');
        }
        List<String> userPropertyCallJson = userPropertyCalls.toJSON();
        if (null != userPropertyCallJson) {
            service.syncCall(userPropertyCallJson, 'add_user_properties');
        }
    }

    public void addProperty(String identity, String property, Object propertyValue) {
        if (null == propertyValue) return;
        userPropertyCalls.addProperty(identity, property, propertyValue);
    }

    public void addProperty(List<String> identities, String property, Object propertyValue) {
        for(String identity: identities) {
            addProperty(identity, property, propertyValue);
        }
    }

    public void addProperties(List<String> identities, Map<String, Object> propertyValues) {
        if ( identities.size() > 0 ) {
            for ( String property : propertyValues.keySet() ) {
                addProperty(identities, property, propertyValues.get(property));
            }
        }
    }

    public void addProperties(String identity, Map<String, Object> propertyValues) {
        for ( String property : propertyValues.keySet() ) {
            addProperty(identity, property, propertyValues.get(property));
        }
    }

    public void addEvent(SObject record, String identity, String eventName, Map<String, String> properties) {
        trackingCalls.addEvent(record, identity, eventName, removeNullValues(properties));
    }

    public void addEvent(SObject record, String identity, String eventName, Map<String, String> properties, DateTime timestamp) {
        trackingCalls.addEvent(record, identity, eventName, removeNullValues(properties), timestamp);
    }

    public void addUserProperties(List<String> identities) {
        for (Type propertyClass: heap_Configuration.userPropertyTypes) {
            heap_IUserPropertySource userPropertySource = (heap_IUserPropertySource)propertyClass.newInstance();
            userPropertySource.hydrateFromIdentities(identities);
            userPropertySource.addUserProperties(this);
        }
    }

    private Map<String, String> removeNullValues(Map<String, String> properties) {
        Map<String, String> tempProps = new Map<String, String>();
        for (String key : properties.keySet()) {
            if (null == properties.get(key)) continue;
            tempProps.put(key, properties.get(key));
        }
        return tempProps;
    }*/
}
public with sharing class heap_TrackingCall {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_TrackingCall(){}
    /*public String appId;
    public List<Map<String, Object>> events = new List<Map<String, Object>>();

    public heap_TrackingCall() {
        appId = heap_Configuration.HeapAppId;
    }

    private String getIdempotencyKey(String identity, String eventName, Map<String, String> properties, DateTime timestamp) {
        if (null == timestamp) {
            timestamp = DateTime.now();
        }
        String uniqueIdString = String.valueOf(JSON.serialize(properties));
        uniqueIdString += identity;
        uniqueIdString += eventName;
        uniqueIdString += String.valueOf(timestamp.getTime());
        uniqueIdString += appId;

        return heap_Util.base64encodedMD5(uniqueIdString);
    }

    public List<String> toJSON() {
        if (0 == events.size()) {
            return null;
        }
        List<String> tempList = new List<String>();
        for (List<Map<String, Object>> chunk: heap_Util.chunk(events, 250)) {
            tempList.add(
                JSON.serialize(
                    new Map<String, Object>{
                        'app_id' => appId,
                        'events' => chunk
                    },
                    true
                )
            );
        }
        return tempList;
    }

    public void addEvent(SObject record, String identity, String eventName, Map<String, String> properties, DateTime timestamp){
        if (properties.size() > 0 && !String.isBlank(identity)) {
            events.add(
                new Map<String, Object>{
                        'identity' => identity,
                        'event' => eventName,
                        'timestamp' => timestamp,
                        'properties' => properties,
                        'idempotency_key' => getIdempotencyKey(identity, eventName, properties, timestamp)
                }
            );
        }
    }

    public void addEvent(SObject record, String identity, String eventName, Map<String, String> properties){
        addEvent(record, identity, eventName, properties, (DateTime)record.get('LastModifiedDate'));
    }*/
}
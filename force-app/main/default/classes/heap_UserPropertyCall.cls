public with sharing class heap_UserPropertyCall {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_UserPropertyCall(){}
    /*public String appId;
    public Map<String, Map<String, String>> users = new Map<String, Map<String, String>>();

    public List<String> toJSON() {
        if (0 == users.size()) {
            return null;
        }
        List<String> tempList = new List<String>();
        List<String> keyList = new List<String>();
        keyList.addAll(users.keySet());
        for (List<String> keyChunk: heap_Util.chunk(keyList, 250)) {
            List<Map<String, Object>> chunk = new List<Map<String, Object>>();
            for (String key: keyChunk) {
                chunk.add(new Map<String, Object>{
                        'identity' => (Object)key,
                        'properties' => (Object)users.get(key)
                });
            }
            tempList.add(
                JSON.serialize(
                    new Map<String, Object>{
                        'app_id' => appId,
                        'users' => chunk
                    },
                    true
                )
            );
        }
        return tempList;
    }

    public heap_UserPropertyCall(){
        appId = heap_Configuration.HeapAppId;
    }

    public void addProperty(String identity, String property, Object propertyValue) {
        if (null == identity) return;
        if (users.containsKey(identity)) {
            users.get(identity).put(property, String.valueOf(propertyValue));
        } else {
            users.put(identity, new Map<String, String>{property => String.valueOf(propertyValue)});
        }
    }*/
}
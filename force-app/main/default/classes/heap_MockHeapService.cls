@IsTest
global with sharing class heap_MockHeapService implements heap_IHeapService{
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    //// For code coverage while deploying commented methods
    global static void asyncCall(){}
    /*static private Integer calls = 0;
    static private Map<String, List<String>> history = new Map<String, List<String>>();

    global static void call(List<String> identities, String endpoint) {
        syncCall(identities, endpoint);
    }

    global static void syncCall(List<String> identities, String endpoint) {
        calls += identities.size();
        if (history.containsKey(endpoint)) {
            history.get(endpoint).addAll(identities);
        } else {
            history.put(endpoint, identities);
        }
    }

    global static void asyncCall(List<String> identities, String endpoint) {
        calls += identities.size();
        if (history.containsKey(endpoint)) {
            history.get(endpoint).addAll(identities);
        } else {
            history.put(endpoint, identities);
        }
    }


    public Integer getCallsMade() {
        return calls;
    }

    public void printHistory() {
        for( String endPoint: history.keySet()) {
            for (String body: history.get(endPoint)) {
                system.debug(body);
            }
        }
    }*/
}
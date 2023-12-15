public class AlexaRankRefreshBulk implements Database.AllowsCallouts {
    /**
    * Handle fetching alexa ranks in bulk asynchronously using the Solution Architect
    *  AWS Bulk Alexa Fetcher and SFDC Bulk API v2 wrapper APIs
     */

    private String baseUrl = 'https://xr388iddo0.execute-api.us-east-2.amazonaws.com/production/alexa-rank';

    // Convert parameters to JSON for request
    public String buildBody(List<String> querySelect, String queryFrom, String queryWhere) {
        Map<String,Object> data = new Map<String,Object>{
            'threaded' => true,
            'destination' => 'sfdc_prod',
            'immediateResponse' => false,
            'query_select' => querySelect,
            'query_from' => queryFrom,
            'query_where' => queryWhere
        };
        return JSON.serialize(data);
    }

    // Make a request to the specified Klaviyo API path
    public void makeRequest(String method, String url, String body) {
        // Get current K4K API key set
        Map <String, String> k4kSettings = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Code_Setting__mdt','K4K Settings Config');
        String k4kApiKeySet = k4kSettings.get('API Key Set Toggle');
        // Retrieve keys for current key set
        Map <String, String> apiKeys = GeneralUtils.getMetadataTypeValuesByLabel('KlaviyoAPIAccount__mdt',k4kApiKeySet);
        String apiKey = apiKeys.get('K4KAwsSyncApiKey');
        // Build request
        HttpRequest request = new HttpRequest();
        request.setTimeout(100000);
        request.setMethod(method);
        request.setEndpoint(url);
        request.setHeader('x-api-key', apiKey);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        // Send request
        try {
            HTTPResponse res = new HTTP().send(request);
            GeneralUtils.logRequest(request, res);
        } catch (System.CalloutException ex) {
            GeneralUtils.logRequestException(request, ex);
        }
    }


    public void startBulkAlexaRankFetch(List<String> querySelect, String queryFrom, String queryWhere) {
        String body = buildBody(querySelect, queryFrom, queryWhere);
        makeRequest('POST', this.baseUrl, body);
    }
}
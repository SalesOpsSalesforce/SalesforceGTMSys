public class K4KAwsApi implements Database.AllowsCallouts {
    /**
    * Handle any Track and Identify calls originating from other Apex code
     */
    private String baseUrl = 'https://xr388iddo0.execute-api.us-east-2.amazonaws.com/production/sfdc-sync';
    private String apiKey = '' ;
    private List<Map<String,Object>> accountPayloads = new List<Map<String,Object>>();
    private List<Map<String,Object>> customerOnboardingPayloads = new List<Map<String,Object>>();
    private List<Map<String,Object>> leadPayloads = new List<Map<String,Object>>();

    // Construct API request object using a map of API keys
    public K4KAwsApi(Map<String,String>  apiKeys) {
      this.apiKey = apiKeys.get('K4KAwsSyncApiKey');
    }

    public void setAccountPayloads(List<Map<String,Object>> payloads){
        this.accountPayloads = payloads;
    }

    public void setCustomerOnboardingPayloads(List<Map<String,Object>> payloads){
        this.customerOnboardingPayloads = payloads;
    }

    public void setLeadPayloads(List<Map<String,Object>> payloads){
        this.leadPayloads = payloads;
    }

    // Convert parameters to JSON for request
    public String buildBody() {
        Map<String,Object> data = new Map<String,Object>{
            'records' => new Map<String,Object>{
                'accounts' => this.accountPayloads,
                'customer_onboardings' => this.customerOnboardingPayloads,
                'leads' => this.leadPayloads
            }
        };
        return JSON.serialize(data);
    }

    // Make a request to the specified Klaviyo API path
    public void makeRequest(String method, String url, String body) {
      // Build request
      HttpRequest request = new HttpRequest();
      request.setTimeout(5000);
      request.setMethod(method);
      request.setEndpoint(url);
      request.setHeader('x-api-key', this.apiKey);
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

    // Initiate SFDC > Klaviyo Staff Account K4K sync
    public void sync() {
        makeRequest('POST', this.baseUrl, buildBody());
    }
}
public class AlexaRankRefreshController{
    
    private static String baseUrl = 'https://data.alexa.com/data';
    private static Long defaultAlexaRank = null;
    public Account acct;
    
    public AlexaRankRefreshController(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
    }
    
    
    // Make a request to the specified Klaviyo API path
    public HTTPResponse makeRequest(String method, String url) {
        // Build request
        HttpRequest request = new HttpRequest();
        request.setTimeout(5000);
        request.setMethod(method);
        request.setEndpoint(url);
        // Send request
        try {
            // HTTPResponse res = new HTTP().send(request); VR - Commented this line and added the below if else
            HTTPResponse res = new HTTPResponse();
            if(!Test.isRunningTest()){    
                res = new HTTP().send(request);
            }    
            else{
                res.setBody('<request><SD></SD></request>');
            }  
            System.debug(url);
            System.debug(res.toString());
            return res;
        } catch (System.CalloutException e) {
            System.debug(url);
            System.debug('ERROR:' + e);
            return null;
        }
    }
    
    // Get alexa rank
    public Long getAlexaRank(String url) {        
        // Set query params
        String query = '?cli=10&url=' + EncodingUtil.urlEncode(url, 'UTF-8');
        
        // Retrieve Alexa Rank
        String requestUrl = AlexaRankRefreshController.baseUrl + query;
        HTTPResponse res = makeRequest('GET', requestUrl);
        
        // Get Alexa Rank from response
        DOM.Document doc = res.getBodyDocument();
        if(doc.getRootElement().getChildElement('SD',null) == null){
            return AlexaRankRefreshController.defaultAlexaRank;
        }
        Dom.XmlNode alexaRankNode = doc.getRootElement()
            .getChildElement('SD',null)
            .getChildElement('POPULARITY',null);
        Long alexaRank = Long.valueOf(alexaRankNode.getAttribute('TEXT', null));
        system.debug(alexaRank);
        return alexaRank;
    }
    
    public PageReference updateAlexaRank(){

        try {
            List<Account> currentAcct = [SELECT Id, Website FROM Account where Id =: acct.Id];
            String url = string.valueOf(currentAcct[0].Website);
            // If the domain invalid, return a default high value
            if(GeneralUtils.isValidUrl(url)){
                Long alexaRank = getAlexaRank(url);
                acct.etailinsights_Alexa_Rank__c = alexaRank;
            }
            else{
                acct.etailinsights_Alexa_Rank__c = AlexaRankRefreshController.defaultAlexaRank;
            }
        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
        
        acct.Alexa_Rank_Last_Refresh__c = dateTime.now();
        update acct;
        
        return new PageReference('/'+acct.Id);
        
    }    
    
}
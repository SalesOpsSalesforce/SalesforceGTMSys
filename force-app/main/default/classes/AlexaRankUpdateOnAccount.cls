global class AlexaRankUpdateOnAccount{
  //[RGaokar 11/12/2021 TP #90961]
 //This class method is optimized to bulkify callouts. The new classes AlexaRankBatch and AlexaRankCallout are used for account and lead object alexa rank
 //This class can be deleted

    global AlexaRankUpdateOnAccount(){}  // For code coverage while deploying commented method
   /* @future(callout=true)
    public static void updateAccountRank(String acctId){
        
        List <String> executionFlow = new List <String> ();
        try{            
            
            Account acct = [SELECT Id, Website FROM Account where Id =: acctId];
            String url = string.valueOf(acct.Website);
            executionFlow.add('URL is '+url);
            if(GeneralUtils.isValidUrl(url)){
                executionFlow.add('URL is valid ');
                Long alexaRank = getAlexaRank(url);
                acct.etailinsights_Alexa_Rank__c = alexaRank;
                acct.Alexa_Rank_at_Last_Owner_Change__c = alexaRank;
                executionFlow.add('Alexa Rank returned '+alexaRank);
            }
            else{
                acct.etailinsights_Alexa_Rank__c = null;
            }
            
            update acct;
        }
        catch(Exception  ex){
            GeneralUtils.logException(ex); 
            ExceptionHandling.performExceptionHandling(ex, 'AlexaRankUpdateonAccount: UpdateAccountRank', executionFlow);       
        }            
        
    }
    
    // Get alexa rank
    public static Long getAlexaRank(String url) {        
        // Set query params
        String query = '?cli=10&url=' + EncodingUtil.urlEncode(url, 'UTF-8');
        
        // Retrieve Alexa Rank
        String requestUrl = 'https://data.alexa.com/data' + query;
        HTTPResponse res = makeRequest('GET', requestUrl);
        
        // Get Alexa Rank from response
        DOM.Document doc = res.getBodyDocument();
        if(doc.getRootElement().getChildElement('SD',null) == null){
            return null;
        }
        Dom.XmlNode alexaRankNode = doc.getRootElement()
            .getChildElement('SD',null)
            .getChildElement('REACH',null);
        Long alexaRank = Long.valueOf(alexaRankNode.getAttribute('RANK', null));
        system.debug(alexaRank);
        return alexaRank;
    }
    
    // Make a request to the specified Klaviyo API path
    public static HTTPResponse makeRequest(String method, String url) {
        List <String> executionFlow = new List <String> ();
        // Build request
        HttpRequest request = new HttpRequest();
        request.setTimeout(5000);
        request.setMethod(method);
        request.setEndpoint(url);
        // Send request
        try {
            HTTPResponse res = new HTTPResponse();
            if(!Test.isRunningTest()){    
                res = new HTTP().send(request);
            }    
            else{
                res.setBody('<request><SD></SD></request>');
            }        
            System.debug(url);
            executionFlow.add('URL is '+url);
            System.debug(res.toString());
            executionFlow.add('HTTP Response '+res.toString());
            return res;
        } catch (System.CalloutException e) {
            System.debug(url);
            System.debug('ERROR:' + e);
            ExceptionHandling.performExceptionHandling(e, 'AlexaRankUpdateonAccount: makeRequest', executionFlow); 
            return null;
        }
    }*/
    
}
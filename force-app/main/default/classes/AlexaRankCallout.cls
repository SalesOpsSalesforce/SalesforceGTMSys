public class AlexaRankCallout {
    // Get alexa rank
    public static Double getAlexaRank(String url) {        
        // Set query params
        String query = '?cli=10&url=' + EncodingUtil.urlEncode(url, 'UTF-8');
        
        // Retrieve Alexa Rank
        String requestUrl = 'https://data.alexa.com/data' + query;
        HTTPResponse res = makeRequest('GET', requestUrl);
        
        // Get Alexa Rank from response if request is successful
        // [RGaokar 2/24/2022 TP #89071] if condition is added to check valid response before processing it.
        if(res != null && res.getStatusCode() == 200){
            DOM.Document doc = res.getBodyDocument();
            if(doc.getRootElement().getChildElement('SD',null) == null){
                return null;
            }
            Dom.XmlNode alexaRankNode = doc.getRootElement()
                .getChildElement('SD',null)
                .getChildElement('POPULARITY',null);
            Double alexaRank = Long.valueOf(alexaRankNode.getAttribute('TEXT', null));
            system.debug('alexaRank--'+alexaRank);
            return alexaRank;
        }
        return null;
    }
    
    // Make a request to the specified Klaviyo API path
    public static HTTPResponse makeRequest(String method, String url) {
        List <String> executionFlow = new List <String> ();
        // Build request
        HttpRequest request = new HttpRequest();
        request.setTimeout(10000);//[RGaokar 2/24/2022 TP #89071] timeout is increased from 5000 to 10000.
        request.setMethod(method);
        request.setEndpoint(url);
        // Send request
        try {
            HTTPResponse res = new HTTPResponse();
            if(!Test.isRunningTest()){    
                res = new HTTP().send(request);
            }    
            else{
                res.setBody('<request><SD><POPULARITY TEXT="1111"/></SD></request>');
                res.setStatus('OK');
            	res.setStatusCode(200);
            }        
            System.debug(url);
            executionFlow.add('URL is '+url);
            System.debug(res.toString());
            executionFlow.add('HTTP Response '+res.toString());
            return res;
        } catch (System.CalloutException e) {
            System.debug(url);
            System.debug('ERROR:' + e);
            ExceptionHandling.performExceptionHandling(e, 'AlexaRankCallout: makeRequest', executionFlow); 
            return null;
        }
    }
    
}
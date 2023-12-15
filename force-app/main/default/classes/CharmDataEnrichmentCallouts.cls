//[RGaokar 04/27/2022 TP #119370, 119800] Charm io api helper class for Callouts
//[RGaokar 09/15/2023 SFDC-3575 Sync additional charm fields]
public class CharmDataEnrichmentCallouts{ 
    public static void processCharmCallouts (List<sObject> recordList){
        Map<string,Set<Id>> websiteIdsMap = new Map<string,Set<Id>>();
        List<sObject> sObjectUpdateList = new List<sObject>();
        for (sObject obj:recordList){
            if(!websiteIdsMap.containsKey(string.valueOf(obj.get('Clean_Website__c')).toLowerCase())){
                websiteIdsMap.put(string.valueOf(obj.get('Clean_Website__c')).toLowerCase(), new Set<Id>{obj.id});
            }else{
                websiteIdsMap.get(string.valueOf(obj.get('Clean_Website__c')).toLowerCase()).add(obj.id);
            }   
        }

        //Process callouts
        Boolean sandboxOrg = [SELECT IsSandbox FROM Organization].IsSandbox;
        String errorString = '';
        string endPointURL = 'callout:Charm_io';
        string requestEndPointURL = endPointURL +'/api/v2/enrichment/records';
        string requestBody = getRequestBody(websiteIdsMap.keySet());
        HttpRequest req = new HttpRequest();
        req.setEndpoint(requestEndPointURL);
        req.setHeader('Authorization', 'Token '+Data_Enrichment_API__mdt.getInstance('Charm_io').Token__c);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setBody(requestBody);
        try{
            Http http = new Http();
            HttpResponse response = new HttpResponse();
            if(!Test.isRunningTest() && !sandboxOrg){
                response = http.send(req);
            }else{
                response.setHeader('Content-Type', 'application/json');
                response.setBody(getTestResponseBody(websiteIdsMap.keySet()));
                response.setStatusCode(200);
            }
            //Process response
            if(response != null && response.getStatusCode() == 200){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                //system.debug('responseMap--'+responseMap);
                List<Object> responseDataList = (List<Object>)responseMap.get('data');
                List<Object> responseErrorList = (List<Object>)responseMap.get('errors');
                //system.debug('responseErrorList--'+string.valueof(responseErrorList));
                for (Object responseData : responseDataList) {
                    Map<String, Object> dataAttributes = (Map<String, Object>)responseData;
                    if(dataAttributes.get('brand_data') != null && dataAttributes.containsKey('query_value')){//Brand data is returned and query_value is available 
                        Map<String, Object> brandData = (Map<String, Object>)dataAttributes.get('brand_data');
                        Set <Id> sObjIds = websiteIdsMap.get((string) dataAttributes.get('query_value'));
                        sObjectUpdateList.addAll(processCharmResponse(brandData,sObjIds));
                        websiteIdsMap.remove((string) dataAttributes.get('query_value'));
                    }
                } 
            }else if(response != null){
                errorString += '\n'+getErrorRecordDetails(websiteIdsMap)+' Response Code: '+response.getStatusCode();
            }   
        }catch(System.CalloutException ex){
            errorString += '\n'+getErrorRecordDetails(websiteIdsMap)+' Error Message: '+ex.getMessage();
        }
        
        //If some records did not received valid response then set their charm fields to null
        if(!websiteIdsMap.isEmpty()){
            Set<Id> nonProcessedSobjIds = new Set<Id>();
            for(Set<Id> Ids:websiteIdsMap.values()){
                nonProcessedSobjIds.addAll(Ids);
            }
            sObjectUpdateList.addAll(processCharmResponse(null,nonProcessedSobjIds));
        }
        
        //Update records
        if(sObjectUpdateList.size()>0){
            List<Database.SaveResult> srList = Database.update(sObjectUpdateList, false);
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    errorString += '\n'+'Record Id: '+ result.getId();
                    for(Database.Error err : result.getErrors()) {
                        errorString += ' Error Message: ' +err.getMessage()+'\n';
                    } 
                }
            }
        }
        
        //Create expection record for errors
        if(String.isNotBlank(errorString) || Test.isRunningTest()){
            List <String> executionFlow = new List <String> ();
            executionFlow.add('Errors occured when updating Charm io metrics for following records:');
            executionFlow.add(errorString);
            ExceptionHandling.performExceptionHandling(null, 'CharmDataEnrichmentCallouts', executionFlow);
        }
    }
    
    //Generate Charm io request body
    private static string getRequestBody(Set<string> websites){
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeFieldName('query');
        jsonGen.writeStartArray();
        for(string website:websites){
            jsonGen.writeStartObject();
            jsonGen.writeStringField('url', website);
            jsonGen.writeEndObject();
        }
        jsonGen.writeEndArray();
        jsonGen.writeEndObject();
        //system.debug('jsonGen.getAsString()--'+jsonGen.getAsString());
        return jsonGen.getAsString();  
    }
    
    //[RGaokar 08/17/2022 SFDC-609 Removed Charm Growth Score & Charm Success Score. Added Charm State/Province]
    //Process Response
    private static List<sObject> processCharmResponse(Map<String, Object> brandData,Set <Id> sObjIds){
        List<sObject> sObjectList = new List<sObject>();
        string charmCountry = null;
        string charmTechs = null;
        string charmEmailTechs = null;
        Double faceboookFollowers = null;
        Double instagramFollowers = null;
        Double twitterFollowers = null;
        Double tiktokFollowers = null;
        Double charmNoofEmployess = null;
        string charmEcommPlatform = null;
        Double charmRevenue = null;
        string charmState = null;
        string facebook_category = null;
        string google_categories = null;
        string website_description = null;
        string ngrams = null;
        if(brandData != null){
            charmCountry = (string)brandData.get('country_code');
            charmState = (string)brandData.get('state');
            faceboookFollowers = (double)brandData.get('facebook_follows');
            instagramFollowers = (double)brandData.get('instagram_followers_count');
            charmNoofEmployess = (double)brandData.get('linkedin_employees_linkedin');
            charmEcommPlatform = (string)brandData.get('platform');
            charmRevenue = (double)brandData.get('revenue_estimate');
            tiktokFollowers = (double)brandData.get('tiktok_followers_count');
            twitterFollowers = (double)brandData.get('twitter_followers_count');
            charmTechs = brandData.containsKey('techs')?string.join((List<object>)brandData.get('techs'), ', '):null;
            charmEmailTechs = brandData.containsKey('techs_email_marketing')?string.join((List<object>)brandData.get('techs_email_marketing'), ', '):null;
            facebook_category = (string)brandData.get('facebook_category');
            website_description = (string)brandData.get('website_description');
            google_categories = brandData.containsKey('google_categories')?string.join((List<object>)brandData.get('google_categories'), ', '):null;
            ngrams = brandData.containsKey('ngrams')?string.join((List<object>)brandData.get('ngrams'), ', '):null;
        }
        for(Id sObjId:sObjIds){
            sObject sObj = sObjId.getSobjectType().newSObject(sObjId);
            sObj.put('Charm_Country__c', charmCountry);
            sObj.put('Charm_State_Province__c', charmState);
            sObj.put('Facebook_Followers__c', faceboookFollowers);
            sObj.put('Instagram_Followers__c', instagramFollowers);
            sObj.put('Charm_Num_of_Employees__c', charmNoofEmployess);
            sObj.put('Charm_Ecommerce_Platform__c', charmEcommPlatform);
            sObj.put('Charm_Revenue__c', charmRevenue);
            sObj.put('TikTok_Followers__c', tiktokFollowers);
            sObj.put('Twitter_Followers__c', twitterFollowers);
            sObj.put('Charm_Technology__c', charmTechs);
            sObj.put('Charm_Email_Marketing_Tech__c', charmEmailTechs);
            sObj.put('Charm_Facebook_Category__c', facebook_category);
            sObj.put('Charm_Google_Category__c', google_categories);
            sObj.put('Charm_Website_Description__c', website_description);
            sObj.put('Charm_Brand_Keywords__c', ngrams);
            sObj.put('Charm_Enriched_for_Segmentation__c', true);//[RGaokar 11/07/2023 SFDC-3627 Flag for Segmentation Sync]
            sObjectList.add(sObj);
        }
        return sObjectList;
    }
    
    //[RGaokar 08/17/2022 SFDC-609 Removed Charm Growth Score & Charm Success Score. Added Charm State/Province]
    //Generate test response body
    private static string getTestResponseBody(Set<string> websites){
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeFieldName('errors');
        jsonGen.writeStartArray();
        jsonGen.writeEndArray();
        jsonGen.writeFieldName('data');
        jsonGen.writeStartArray();
        for(string website:websites){
            jsonGen.writeStartObject();//data
            jsonGen.writeStringField('query_value', website);
            jsonGen.writeFieldName('brand_data');
            jsonGen.writeStartObject();//brand_data
            jsonGen.writeStringField('brand_url', website);
            jsonGen.writeStringField('country_code', 'US');
            jsonGen.writeStringField('state', 'MA');
            jsonGen.writeStringField('facebook_category', 'test_facebook');
            jsonGen.writeStringField('website_description', 'test_website');
            jsonGen.writeNumberField('facebook_follows', 50);
            jsonGen.writeNumberField('instagram_followers_count', 50);
            jsonGen.writeNumberField('linkedin_employees_linkedin', 50);
            jsonGen.writeStringField('platform', 'Shopify');
            jsonGen.writeNumberField('revenue_estimate', 50);
            jsonGen.writeNumberField('tiktok_followers_count', 50);
            jsonGen.writeNumberField('twitter_followers_count', 50);
            jsonGen.writeFieldName('techs');
            jsonGen.writeStartArray();
            jsonGen.writeString('techs1');
            jsonGen.writeString('techs2');
            jsonGen.writeEndArray();
            jsonGen.writeFieldName('techs_email_marketing');
            jsonGen.writeStartArray();
            jsonGen.writeString('techsEmail1');
            jsonGen.writeString('techsEmail2');
            jsonGen.writeEndArray();
            jsonGen.writeEndObject();//brand_data
            jsonGen.writeEndObject();//data
        }
        jsonGen.writeEndArray();
        jsonGen.writeEndObject();//Response
        return jsonGen.getAsString();  
    }
    
    //Error Records
    private static string getErrorRecordDetails(Map<string,Set<Id>> websiteIdsMap){
        string errorRecords = '';
        for(string website:websiteIdsMap.keyset()){
            errorRecords += 'Record Ids: ';
            for(Id recordId:websiteIdsMap.get(website)){
                errorRecords += recordId+',';
            }
            errorRecords += ' Website: '+website;
        }
        return errorRecords; 
    }
    
}
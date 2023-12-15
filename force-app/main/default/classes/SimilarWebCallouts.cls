//[RGaokar 04/29/2022 TP #119625] SimilarWeb callout helper class
public class SimilarWebCallouts {
    private static boolean totalVisitsAtOwnerChange = false;
    public static void processSimilarWebCallouts (List<sObject> recordList, Boolean setTotalVisitsAtOwnerChange){
        Map<string,Set<Id>> websiteIdsMap = new Map<string,Set<Id>>();
        List<sObject> sObjectUpdateList = new List<sObject>();
        SimilarWebCallouts.totalVisitsAtOwnerChange = setTotalVisitsAtOwnerChange;
        for (sObject obj:recordList){
            if(!websiteIdsMap.containsKey(string.valueOf(obj.get('Clean_Website__c')).toLowerCase())){
                websiteIdsMap.put(string.valueOf(obj.get('Clean_Website__c')).toLowerCase(), new Set<Id>{obj.id});
            }else{
                websiteIdsMap.get(string.valueOf(obj.get('Clean_Website__c')).toLowerCase()).add(obj.id);
            }  
        }
        
        //Process callouts
        string swApiKey = Data_Enrichment_API__mdt.getInstance('SimilarWeb').API_Key__c;
        Integer endMonthOffset = Date.today().Day() < 11?2:1;//SW data for the prior month aren't available until the 10th of the following month, per the terms of SW SLA.
        Integer requestEndMonth = (Date.today().month()-endMonthOffset) > 0?(Date.today().month()-endMonthOffset):(Date.today().month()-endMonthOffset) + 12;
        Integer requestEndYear = (Date.today().month()-endMonthOffset) > 0?Date.today().year():Date.today().year() - 1;
        string requestEndDate = requestEndYear+ '-'+ requestEndMonth;
        //Similar web mertrics over Last 6 months
        Integer requestStartMonth = (Date.today().month()-endMonthOffset) - 5 > 0?(Date.today().month()-endMonthOffset) - 5:(Date.today().month()-endMonthOffset) - 5 + 12;
        Integer requestStartYear = (Date.today().month()-endMonthOffset) - 5 > 0?Date.today().year():Date.today().year() - 1;
        string requestStartDate = requestStartYear+ '-'+ requestStartMonth;
        string requestCountry = 'world';
        Boolean requestmaindomainonly = false;
        String errorString = '';
        Boolean sandboxOrg = [SELECT IsSandbox FROM Organization].IsSandbox;
        //As SimilarWeb provides only Rest endpoint which handles one website at a time, callout need to done inside for loop, for bulk records the 10 records will be process in each batch.
        for(string website:websiteIdsMap.keyset()){
            Set <Id> sObjIds = websiteIdsMap.get(website);
            string requestEndPointURL = 'callout:SimilarWeb' +'/v1/website/';
            requestEndPointURL += website+'/lead-enrichment/all?api_key='+swApiKey;
            requestEndPointURL += '&start_date='+requestStartDate+'&end_date='+requestEndDate+'&country='+requestCountry;
            requestEndPointURL += '&main_domain_only='+requestmaindomainonly+'&format=json&show_verified=false';
            //system.debug('requestEndPointURL--'+requestEndPointURL);
            HttpRequest req = new HttpRequest();
            req.setEndpoint(requestEndPointURL);
            req.setTimeout(12000);
            req.setMethod('GET');
            try{
                Http http = new Http();
                HttpResponse response = new HttpResponse();
                if(!Test.isRunningTest() && !sandboxOrg){
                    response = http.send(req);
                }else{
                    response.setHeader('Content-Type', 'application/json');
                    response.setBody('{"global_rank": 50, "visits": [{"date": "2022-03-01","value": 23912036}]}');
                    response.setStatusCode(200);
                }
                
                if(response != null && response.getStatusCode() == 200){
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    sObjectUpdateList.addAll(processSWResponse(responseMap, sObjIds));    
                }else if(response != null){
                    sObjectUpdateList.addAll(processSWResponse(null, sObjIds));
                    if(response.getStatusCode() != 404 && response.getStatusCode() != 400)//Response 404 is for Data not found & 400 for bad request/website so excluding those from error records.
                        errorString += '\n'+getErrorRecordDetails(websiteIdsMap.get(website))+' Website: '+website +' Response Code: '+response.getStatusCode();
                }
            }catch(System.CalloutException ex){
                sObjectUpdateList.addAll(processSWResponse(null, sObjIds));
                if(!ex.getMessage().containsIgnoreCase('Illegal character in opaque part')){//excluding bad website errors
                    string apiKeytoRemove = 'api_key='+swApiKey;
                    errorString += '\n'+getErrorRecordDetails(websiteIdsMap.get(website))+' Website: '+website +' Error Message: '+ex.getMessage().remove(apiKeytoRemove);
                } 
            }
        }
        
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
            executionFlow.add('Errors occured when updating Similarweb metrics for following records:');
            executionFlow.add(errorString);
            ExceptionHandling.performExceptionHandling(null, 'SimilarWebCallouts', executionFlow);
        }
    }
    
    //Process Response
    private static List<sObject> processSWResponse(Map<String, Object>responseMap, Set <Id> sObjIds){
        Double globalRank = null;
        Double avgVisits = null;
        List<sObject> sObjectList = new List<sObject>();
        if(responseMap != null){
            globalRank = (Double)responseMap.get('global_rank');
            List<Object> responseVisitsList = (List<Object>)responseMap.get('visits');
            if(responseVisitsList != null && responseVisitsList.size()>0){
                Double TotalVisits = 0;
                Integer TotalMonths = 0;
                for(Object responseVisits: responseVisitsList){
                    Map<String, Object> responseVisitsMap = (Map<String, Object>)responseVisits;
                    if(responseVisitsMap.get('value') != null){
                        TotalVisits += (Double)responseVisitsMap.get('value');
                        TotalMonths += 1;
                    }
                }
                avgVisits = TotalVisits != 0?TotalVisits/TotalMonths:null;
            }
        }
        
        //Set values on record 
        for(Id sObjId:sObjIds){
            sObject sObj = sObjId.getSobjectType().newSObject(sObjId);
            sObj.put('Similarweb_Rank__c', globalRank);
            sObj.put('Similarweb_Total_Visits__c', avgVisits);
            if(SimilarWebCallouts.totalVisitsAtOwnerChange == true){
                sObj.put('Similarweb_Total_Visits_at_Owner_Change__c', avgVisits);
            }
            sObjectList.add(sObj);
        } 
        return sObjectList;
    }
    
    //Error Record Ids
    private static string getErrorRecordDetails(Set<Id>recordIds){
        string errorRecords = 'Record Ids: ';
        for(Id recordId:recordIds){
            errorRecords += recordId+',';
        }
        return errorRecords; 
    }
}
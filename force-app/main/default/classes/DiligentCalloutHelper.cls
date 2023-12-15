//[RGaokar 2/27/2023 SFDC-1881 Diligent <> SFDC Callout Helper]
public class DiligentCalloutHelper {
    private static Boolean sandboxOrg = [Select IsSandbox from Organization].IsSandbox;
    private static Id admRecordTypeId = Schema.SObjectType.Risk_Intelligence_Data__c.getRecordTypeInfosByDeveloperName().get('Adverse_Media').getRecordTypeId();
    private static Id watchListRecordTypeId = Schema.SObjectType.Risk_Intelligence_Data__c.getRecordTypeInfosByDeveloperName().get('PEP_Watchlists').getRecordTypeId();
    private static map<string,decimal> monitorListIdMap = new map<string,decimal>();
    
    public static List<DiligentSearchProcessor.DiligentPayload> processDiligentSearchPayload(List<DiligentSearchProcessor.DiligentPayload>diligentPayloadList, string diligentApi){
        List<DiligentSearchProcessor.DiligentPayload>updatedDiligentPayloadList = new List<DiligentSearchProcessor.DiligentPayload>();//List contains search_id, retrieved results
        set<id>failedDiligentSearchAccIds = new set<id>();
        String errorString = '';
        string endpointURL;
        if(diligentApi == 'search'){
            endpointURL = '/api/v1/search';
        }else if (diligentApi == 'status'){
            endpointURL = '/api/v1/status';
        }else if (diligentApi == 'results'){
            endpointURL = '/api/v1/results';
        }else if(diligentApi == 'convert_to_monitor'){
            endpointURL = '/api/v1/convert_to_monitor';
            List<Diligent_Monitored_List__mdt> monitorList = [Select DeveloperName, List_Id__c, Type__c From Diligent_Monitored_List__mdt where Active__c = true];
            for(Diligent_Monitored_List__mdt item :monitorList){
                monitorListIdMap.put(item.Type__c, item.List_Id__c);
            }
        }
        
        //Iterate through each payload to perform REST Callout to Diligent API
        for(DiligentSearchProcessor.DiligentPayload payload :diligentPayloadList){
            string requestBody;
            if(diligentApi == 'search'){
                requestBody = getSearchRequestBody(payload);
            }else if (diligentApi == 'status'){
                requestBody = getSearchStatusRequestBody(payload);
            }else if (diligentApi == 'results'){
                requestBody = getSearchResultRequestBody(payload);
            }else if(diligentApi == 'convert_to_monitor'){
                requestBody = getSearchtoMonitorRequestBody(payload);
            }
                        
            map<string,object>processedCalloutResponse = sendDiligentCallout(payload,endpointURL,requestBody);
            
            //Check for response & error
            if(!processedCalloutResponse.isEmpty() && processedCalloutResponse.containsKey('payload')){
                updatedDiligentPayloadList.add((DiligentSearchProcessor.DiligentPayload)processedCalloutResponse.get('payload'));
            }else if(!processedCalloutResponse.isEmpty() && processedCalloutResponse.containsKey('errorString')){
                failedDiligentSearchAccIds.add(payload.accountId);
                errorString += (string)processedCalloutResponse.get('errorString');
            }  
        }
        
        //Process errors if any
        if(string.isNotBlank(errorString) || Test.isRunningTest()){
            processErrors(errorString,failedDiligentSearchAccIds);
        }
        
        //Send the successful callout results to Diligent processors to queue another callout for further processing
        return updatedDiligentPayloadList;
    }
    
    //Send Callout to Diligent APIs
    public static map<string,object> sendDiligentCallout(DiligentSearchProcessor.DiligentPayload payload, string endpointURL, string requestBody){
        string errorString = '';
        map<string,object>processedCalloutResponse = new map<string,object>();
        string requestEndpointURL = 'callout:Diligent' + endpointURL;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(requestEndpointURL);
        req.setBody(requestBody);
        //system.debug('requestBody-- '+requestBody);
        req.setHeader('accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        try{
            Http http = new Http();
            HttpResponse response = new HttpResponse();
            if(!Test.isRunningTest() && !sandboxOrg){
                response = http.send(req);
            }else if(endpointURL.containsIgnoreCase('search')){
                response.setStatusCode(201);
                response.setBody(getTestResponseBody('search'));
            }else if(endpointURL.containsIgnoreCase('status')){
                response.setStatusCode(200);
                response.setBody(getTestResponseBody('status'));    
            }else if(endpointURL.containsIgnoreCase('results')){
                response.setStatusCode(200);
                response.setBody(getTestResponseBody('results'));
            }else if(endpointURL.containsIgnoreCase('convert_to_monitor')){
                response.setStatusCode(201);
                response.setBody(getTestResponseBody('convert_to_monitor'));
            }
            
            //system.debug('response-- '+response.getBody());
            if(response != null && response.getStatusCode() == 201 && endpointURL.containsIgnoreCase('search')){
                payload.search_id =(integer)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('search_id');
                processedCalloutResponse.put('payload',payload);
            }else if(response != null && response.getStatusCode() == 200 && endpointURL.containsIgnoreCase('status')){
                payload.status = (string)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('status');
                processedCalloutResponse.put('payload',payload);
            }else if(response != null && response.getStatusCode() == 200 && endpointURL.containsIgnoreCase('results')){
                payload.responseBody = response.getBody();
                processedCalloutResponse.put('payload',payload);
            }else if(response != null && response.getStatusCode() == 201 && endpointURL.containsIgnoreCase('convert_to_monitor')){
                payload.term_id =(integer)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('term_id');
                payload.list_id =(integer)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('list_id');
                processedCalloutResponse.put('payload',payload);
            }else if (response != null && response.getStatusCode() != 200 && response.getStatusCode() != 201){
                errorString += '\n'+'Record Id: ' +payload.accountId +' Response Code: '+response.getStatusCode();
                processedCalloutResponse.put('errorString',errorString);
            }   
        }catch(system.CalloutException ex){
            errorString += '\n'+'Record Id: ' +payload.accountId +' Error Message: '+ex.getMessage();
            processedCalloutResponse.put('errorString',errorString); 
        }
        return processedCalloutResponse;
    }
    
    //Prepare Diligent Search request body
    private static string getSearchRequestBody(DiligentSearchProcessor.DiligentPayload payload){
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeStringField('term', payload.term);
        if(string.isNOTBlank(payload.country))jsonGen.writeStringField('location', payload.country);
        jsonGen.writeStringField('scope', 'default');
        jsonGen.writeStringField('client_reference', payload.accountId);
        jsonGen.writeFieldName('categories');
        jsonGen.writeStartArray();
        jsonGen.writeString('Adverse Media');
        jsonGen.writeString('Watchlists');
        jsonGen.writeString('PEP');
        jsonGen.writeEndArray();
        jsonGen.writeNumberField('threshold_score', 85);
        jsonGen.writeStringField('token', Label.Diligent_Authentication_Token);
        jsonGen.writeEndObject();
        return jsonGen.getAsString();
    }
    
    //Prepare Diligent Search Status request body
    private static string getSearchStatusRequestBody(DiligentSearchProcessor.DiligentPayload payload){
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeNumberField('search_id', payload.search_id);
        jsonGen.writeStringField('token', Label.Diligent_Authentication_Token);
        jsonGen.writeEndObject();
        return jsonGen.getAsString();
    }
    
    //Prepare Diligent Search Result request body
    private static string getSearchResultRequestBody(DiligentSearchProcessor.DiligentPayload payload){
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeNumberField('search_id', payload.search_id);
        jsonGen.writeStringField('token', Label.Diligent_Authentication_Token);
        jsonGen.writeEndObject();
        return jsonGen.getAsString();
    }
    
    //Prepare Diligent Search To Monitor request body
    private static string getSearchtoMonitorRequestBody(DiligentSearchProcessor.DiligentPayload payload){
        Decimal monitor_list_id = payload.recordType == 'Klaviyo_Account' ? monitorListIdMap.get('Customer') : monitorListIdMap.get('Partner');
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeNumberField('search_id', payload.search_id);
        jsonGen.writeNumberField('list_id', monitor_list_id);
        jsonGen.writeStringField('Active', 'Monitor');
        jsonGen.writeStringField('token', Label.Diligent_Authentication_Token);
        jsonGen.writeEndObject();
        return jsonGen.getAsString();
    }
    
    //Process Diligent Results
    public static List<DiligentSearchProcessor.DiligentPayload> processDiligentResults(List<DiligentSearchProcessor.DiligentPayload>diligentPayloadList){
        Map<Id,DiligentSearchProcessor.DiligentPayload>accIdDiligentResultsMap = new Map<Id,DiligentSearchProcessor.DiligentPayload>();
        set<Id>nonProcessedDiligentAccIds = new set<Id>();
        String errorString = '';
        set<id>failedDiligentSearchAccIds = new set<id>();
        
        //Seperate processed & non-processed Diligent requests
        for(DiligentSearchProcessor.DiligentPayload payload:diligentPayloadList){
            if(payload.status == 'Finished'){
                accIdDiligentResultsMap.put(payload.accountId, payload);//Create Diligent search records for respective accounts
            }else{
                nonProcessedDiligentAccIds.add(payload.accountId);// Mark these accounts as Diligent search failed.
            } 
        }
        
        //Process Diligent Finished Search Results
        if(!accIdDiligentResultsMap.isEmpty()){
            List<Risk_Intelligence_Data__c> RIDRecords = new List<Risk_Intelligence_Data__c>();
            List<Risk_Intelligence_Data__c> riskDataList = [Select Id from Risk_Intelligence_Data__c where Account__c in :accIdDiligentResultsMap.keyset()];
            
            //If Existing Risk data is retrieved then delete those records before adding new records
            if(!riskDataList.isEmpty()){
                List<Database.DeleteResult> deleteResults = Database.delete(riskDataList, false);
            }
            
            for(DiligentSearchProcessor.DiligentPayload result:accIdDiligentResultsMap.values()){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(result.responseBody);
                List<Object> adverseMediaList = (List<Object>)responseMap.get('Adverse Media');
                List<Object> watchlists = (List<Object>)responseMap.get('Watchlists');
                List<Object> PEPs = (List<Object>)responseMap.get('PEP');
                
                //Create Adverse Media records
                RIDRecords.addAll(createAdverseMediaRecords(result.accountId,adverseMediaList));
                
                //Create Watchlist records
                RIDRecords.addAll(createWatchlistRecords(result.accountId,watchlists));
                
                //Create PEP records
                RIDRecords.addAll(createWatchlistRecords(result.accountId,PEPs)); 
            }
            
            //Create Risk Intelligence Data records
            If(!RIDRecords.isEmpty()){
                List<Database.SaveResult> srList = Database.insert(RIDRecords, false);
                for(Database.SaveResult result:srList){
                    if(!result.isSuccess()){
                        Id failedDiligentSearchAccId = RIDRecords[srList.indexOf(result)].Account__c; 
                        failedDiligentSearchAccIds.add(failedDiligentSearchAccId);
                        errorString += '\n'+'Record Id: ' +failedDiligentSearchAccId;
                        for(Database.Error err : result.getErrors()) {
                            errorString += ' Error Message: ' +err.getMessage()+'\n';
                        } 
                    }
                }
                
                //remove failed accounts from the list to avoid getting failed term added to Monitor list, this will help to avoid duplicate terms in monitored list
                if(!failedDiligentSearchAccIds.isEmpty()){
                    for(Id failedAccId:failedDiligentSearchAccIds){
                        accIdDiligentResultsMap.remove(failedAccId);
                    }
                }
            } //If(!RIDRecords.isEmpty())
        }//if(!accIdDiligentResultsMap.isEmpty())
        
        //If there are non-processed Diligent requests then flag the account
        if(!nonProcessedDiligentAccIds.isEmpty()){
            failedDiligentSearchAccIds.addAll(nonProcessedDiligentAccIds);
            errorString += '\n'+' Error Message: Non-processed Diligent request for following accounts: '+ '\n'+ failedDiligentSearchAccIds;
        }
        
        //Process errors if any
        if(string.isNotBlank(errorString) || Test.isRunningTest()){
            processErrors(errorString,failedDiligentSearchAccIds);
        }
        
        return accIdDiligentResultsMap.values();
    }
    
    //Adverse Media records creation
    public static List<Risk_Intelligence_Data__c> createAdverseMediaRecords(string accountId, List<Object> adverseMediaList){
        List<Risk_Intelligence_Data__c> adverseMediaRecords = new List<Risk_Intelligence_Data__c>();
        for(Object adverseMedia :adverseMediaList){
            if(adverseMediaList.indexof(adverseMedia) == 5)
                Break;
            Map<String, Object> adverseMediaAttributes = (Map<String, Object>)adverseMedia;
            Risk_Intelligence_Data__c adm = new Risk_Intelligence_Data__c(Account__c = accountId, recordtypeId = admRecordTypeId);
            adm.Title__c = (string)adverseMediaAttributes.get('title');
            adm.Snippet__c = (string)adverseMediaAttributes.get('snippet');
            adm.Relevance__c = (integer)adverseMediaAttributes.get('relevance');
            adm.URL__c = (string)adverseMediaAttributes.get('url');
            adm.Date_of_Article__c = Datetime.valueOf(((string)(adverseMediaAttributes.get('date'))).replace('T', ' '));
            adverseMediaRecords.add(adm);
        }
        return adverseMediaRecords;
    }
    
    //Watchlist records creation
    public static List<Risk_Intelligence_Data__c> createWatchlistRecords(string accountId, List<Object> watchlists){
        List<Risk_Intelligence_Data__c> watchListRecords = new List<Risk_Intelligence_Data__c>();
        for(Object watchlist :watchlists){
            Map<String, Object> watchListAttributes = (Map<String, Object>)watchlist;
            if(watchListAttributes.get('score') == 100){
                Risk_Intelligence_Data__c watchListRecord = new Risk_Intelligence_Data__c(Account__c = accountId, recordtypeId = watchListRecordTypeId);
                watchListRecord.List_Name__c = (string)watchListAttributes.get('list_name');
                watchListRecord.Matched_Entry__c = (string)watchListAttributes.get('matched_entry');
                watchListRecord.Matched_Entry_Type__c = (string)watchListAttributes.get('matched_entry_type');
                watchListRecord.Master_Entry__c = (string)watchListAttributes.get('master_entry');
                watchListRecord.Master_Entry_Type__c = (string)watchListAttributes.get('master_entry_type');
                watchListRecord.Score__c = (integer)watchListAttributes.get('score');
                
                //Additional Information
                List<Object> additional_info = (List<Object>)watchListAttributes.get('additional_info');
                if(additional_info != null){
                    for(Object info:additional_info){
                        if(((List<Object>)info)[0] == 'Authority')watchListRecord.Authority__c = (string)((List<Object>)info)[1];
                        if(((List<Object>)info)[0] == 'Case')watchListRecord.Case__c = (string)((List<Object>)info)[1];
                        if(((List<Object>)info)[0] == 'Country')watchListRecord.Country__c = (string)((List<Object>)info)[1];
                        if(((List<Object>)info)[0] == 'Category')watchListRecord.Category__c = (string)((List<Object>)info)[1];
                        if(((List<Object>)info)[0] == 'Date_of_Publication'){
                            List<string> datestringList = ((string)((List<Object>)info)[1]).split('\\.');
                            if(datestringList.size() == 3){//If date in correct format available Date-Month-Year then only process
                                String formatteddateString = datestringList[2] + '-'+ datestringList[1] + '-'+ datestringList[0] + ' 00:00:00';
                            	watchListRecord.Date_of_Publication__c = Date.valueOf(formatteddateString);
                            } 
                        }
                    }
                }
                
                watchListRecords.add(watchListRecord); 
            } 
        }
        return watchListRecords;
    }
    
    //Process Convert Search to Monitor term results (Update Diligent list id & term id on account).
    public static void processMonitorTermInfo(List<DiligentSearchProcessor.DiligentPayload>diligentPayloadList){
        List<Account>updateAccList = new List<Account>();
        String errorString = '';
        //Update account for term & list ids
        for(DiligentSearchProcessor.DiligentPayload payload:diligentPayloadList){
           updateAccList.add(new Account(id = payload.accountId, Diligent_Term_Id__c = payload.term_id, Diligent_List_Id__c = payload.list_id)); 
        }
        
        //Update accounts for term & list ids
        if(!updateAccList.isEmpty()){
            List<Database.SaveResult> srAccList = Database.update(updateAccList, false);
            for(Database.SaveResult result:srAccList){
                if(!result.isSuccess()){
                    errorString += '\n'+'Error occured during update. Record Id: ' +result.getId();
                    for(Database.Error err : result.getErrors()) {
                        errorString += ' Error Message: ' +err.getMessage()+'\n';
                    } 
                }
            }
        }
        
        //Process errors if any
        if(string.isNotBlank(errorString) || Test.isRunningTest()){
            processErrors(errorString,new set<id>());
        }
    }
    
    //Error Handling
    public static void processErrors(string errorString, set<id>failedDiligentSearchAccIds){
        List <String> errorList = new List <String> ();
        List<Account>updateAccList = new List<Account>();
        errorList.add('Errors occured during Diligent Search for following records:');
        errorList.add(errorString);
        ExceptionHandling.performExceptionHandling(null, 'DiligentCalloutHelper', errorList);
        
        //Set failed flag on account
        for(id recordId:failedDiligentSearchAccIds){
            updateAccList.add(new Account(id = recordId, Diligent_Search_Failed__c = true));
        }
        
        if(!updateAccList.isEmpty()){
            List<Database.SaveResult> srList = Database.update(updateAccList, false);
        } 
    }
    
    //-------------------------------------------------------------------------------------------------------------------------   
    
    //Diligent Annual Refresh
    //Update list status: API: Monitor list api: update list 
    public static void processListStatus(Decimal listId, string status){
        string requestBody;
        String endpointURL = 'callout:Diligent' + '/api/v1/monitor_list';
        requestBody = getMonitorListStatusRequest(listId, status);
        map<string,object>processedCalloutResponse = sendMonitoredDiligentCallout(endpointURL,requestBody,listId,null);
        
        //Process Errors
        if(!processedCalloutResponse.isEmpty() && processedCalloutResponse.containsKey('errorString')){
            processErrors((string)processedCalloutResponse.get('errorString'),new set<id>());
        }  
    }
    
    //Prepare Diligent Monitor List Status request body
    private static string getMonitorListStatusRequest(decimal listId, string status){
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeNumberField('list_id', (integer)listId);
        jsonGen.writeStringField('token', Label.Diligent_Authentication_Token);
        jsonGen.writeStringField('active', status);
        jsonGen.writeEndObject();
        return jsonGen.getAsString();
    }
    
    //Process Monitor term request: API: Retrieve Monitor Results for a Term
    public static void processMonitorTermsResult(List<Account>accList){
        string requestBody;
        String errorString = '';
        String endpointURL = 'callout:Diligent' + '/api/v1/monitor_term_results';
        map<id,string>accIdResultMap = new map<id,string>();
        
        for(Account a:accList){
            requestBody = getMonitorTermResultRequest(a);
            map<string,object>processedCalloutResponse = sendMonitoredDiligentCallout(endpointURL,requestBody,null,a);
            
            //Check for response & error
            if(!processedCalloutResponse.isEmpty() && processedCalloutResponse.containsKey('payload')){
                accIdResultMap.put(a.id, (string)processedCalloutResponse.get('payload'));
            }else if(!processedCalloutResponse.isEmpty() && processedCalloutResponse.containsKey('errorString')){
                errorString += (string)processedCalloutResponse.get('errorString');
            } 
        }
        
        if(!accIdResultMap.isEmpty()){
            errorString += processAnnualResults(accIdResultMap);//Saves errors if any during the processing of results
        }
        
        //Process Errors
        if(string.isNotBlank(errorString) || Test.isRunningTest()){
            processErrors(errorString,new set<id>());
        } 
    }
    
    //Prepare Diligent Monitor Term Result request body
    private static string getMonitorTermResultRequest(Account a){
        String monthDate = System.label.Diligent_Annual_Refresh_Month_Date;
        List<string>monthDateList = monthDate.split('-');
        Date dt = Date.newInstance(System.today().Year()-1, integer.valueof(monthDateList[0]), integer.valueof(monthDateList[1]));
        DateTime first_result_date = DateTime.newInstanceGMT(dt, Time.newInstance(0, 0, 0, 0));
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeNumberField('term_id', (integer)a.Diligent_Term_Id__c);
        jsonGen.writeNumberField('list_id', (integer)a.Diligent_List_Id__c);
        jsonGen.writeStringField('token', Label.Diligent_Authentication_Token);
        jsonGen.writeDateTimeField('first_result_date', first_result_date);
        jsonGen.writeEndObject();
        return jsonGen.getAsString();
    }
    
    //Send Callout to Diligent Monitored API for Annual Refresh
    public static map<string,object> sendMonitoredDiligentCallout(string endpointURL, string requestBody,decimal listId, account a){
        string errorString = '';
        map<string,object>processedCalloutResponse = new map<string,object>();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointURL);
        req.setBody(requestBody);
        //system.debug('requestBody-- '+requestBody);
        req.setHeader('accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        try{
            Http http = new Http();
            HttpResponse response = new HttpResponse();
            if(!Test.isRunningTest() && !sandboxOrg){
                response = http.send(req);
            }else if(endpointURL.containsIgnoreCase('monitor_list')){
                response.setStatusCode(200);
                response.setBody(getTestResponseBody('monitor_list'));
            }else if(endpointURL.containsIgnoreCase('monitor_term_results')){
                response.setStatusCode(200);
                response.setBody(getTestResponseBody('results'));
            }
            
            //system.debug('response-- '+response.getBody());
            if(response != null && response.getStatusCode() == 200 && endpointURL.containsIgnoreCase('monitor_term_results')){
                processedCalloutResponse.put('payload',response.getBody());   
            }else if (response != null && response.getStatusCode() != 200 && endpointURL.containsIgnoreCase('monitor_list')){
                errorString += '\n'+'List Id: ' +listId +' Status Failed to Update' +' Response Code: '+response.getStatusCode() + ' Error: '+response.getBody();
            }else if (response != null && response.getStatusCode() != 200 && endpointURL.containsIgnoreCase('monitor_term_results')){
                errorString += '\n'+'Account Id: ' +a.Id +' List Id: ' + a.Diligent_List_Id__c + ' Response Code: '+response.getStatusCode() + ' Error: '+response.getBody();
            }   
        }catch(system.CalloutException ex){
            if(endpointURL.containsIgnoreCase('monitor_list')){
                errorString += '\n'+'List Id: ' +listId +' Status Failed to Update' +' Error Message: '+ex.getMessage();
            }else{
                errorString += '\n'+'Account Id: ' +a.Id +' List Id: ' + a.Diligent_List_Id__c + ' Error Message: '+ex.getMessage();
            } 
        }
        
        if(string.isNotBlank(errorString)){
            processedCalloutResponse.put('errorString',errorString);
        }
        
        return processedCalloutResponse;
    }
    
    public static string processAnnualResults(map<id,string>accIdResultMap){
        List<Risk_Intelligence_Data__c> RIDRecords = new List<Risk_Intelligence_Data__c>();
        List<Risk_Intelligence_Data__c> riskDataList = [Select Id from Risk_Intelligence_Data__c where Account__c in :accIdResultMap.keyset()];
        String errorString = '';
        
        //If Existing Risk data is retrieved then delete those records before adding new records
        if(!riskDataList.isEmpty()){
            List<Database.DeleteResult> deleteResults = Database.delete(riskDataList, false);
        }
        
        for(Id accId:accIdResultMap.keyset()){
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(accIdResultMap.get(accId));
            List<Object> adverseMediaList = (List<Object>)responseMap.get('adverse_media_results');
            List<Object> watchlists = (List<Object>)responseMap.get('watchlist_results');
            List<Object> PEPs = (List<Object>)responseMap.get('PEP');

            //Create Adverse Media records
            if(adverseMediaList != null)RIDRecords.addAll(createAdverseMediaRecords(accId,adverseMediaList));
            
            //Create Watchlist records
            if(watchlists != null)RIDRecords.addAll(createWatchlistRecords(accId,watchlists));
            
            //Create PEP records
            if(PEPs != null)RIDRecords.addAll(createWatchlistRecords(accId,PEPs)); 
        }

        //Create Risk Intelligence Data records
        If(!RIDRecords.isEmpty()){
            List<Database.SaveResult> srList = Database.insert(RIDRecords, false);
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    Id failedDiligentSearchAccId = RIDRecords[srList.indexOf(result)].Account__c;
                    errorString += '\n'+'Record Id: ' +failedDiligentSearchAccId;
                    for(Database.Error err : result.getErrors()) {
                        errorString += ' Error Message: ' +err.getMessage()+'\n';
                    } 
                }
            }
        } //If(!RIDRecords.isEmpty())
        return errorString;
    }
    
    public class monitorResult{
        public Integer term_id;
        public List<Object>adverse_media_results;
        public List<Object>watchlist_results;
    }
    //-------------------------------------------------------------------------------------------------------------------------    
    
    //Get test response body
    @TestVisible
    private static string getTestResponseBody(string diligentApi){
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        if(diligentApi == 'search'){
            jsonGen.writeNumberField('search_id', Integer.valueof((Math.random() * 1000)));
        }else if(diligentApi == 'status'){
            jsonGen.writeStringField('status', 'Finished'); 
        }else if(diligentApi == 'results'){
            jsonGen.writeFieldName('Adverse Media');
            jsonGen.writeStartArray();
            jsonGen.writeStartObject();
            jsonGen.writeStringField('title', 'test title');
            jsonGen.writeStringField('snippet', 'test snippet');
            jsonGen.writeNumberField('relevance', 100);
            jsonGen.writeStringField('date', '2023-03-07T11:59:00');
            jsonGen.writeStringField('url', 'test.com');
            jsonGen.writeEndObject();
            jsonGen.writeEndArray();
            
            jsonGen.writeFieldName('Watchlists');
            jsonGen.writeStartArray();
            jsonGen.writeStartObject();
            jsonGen.writeStringField('list_name', 'test list');
            jsonGen.writeStringField('matched_entry', 'test matched');
            jsonGen.writeStringField('matched_entry_type', 'Individual');
            jsonGen.writeStringField('master_entry', 'test master');
            jsonGen.writeStringField('master_entry_type', 'Individual');
            jsonGen.writeNumberField('score', 100);
            jsonGen.writeEndObject();
            jsonGen.writeEndArray();
            
            jsonGen.writeFieldName('PEP');
            jsonGen.writeStartArray();
            jsonGen.writeStartObject();
            jsonGen.writeStringField('list_name', 'test PEP list');
            jsonGen.writeStringField('matched_entry', 'test matched PEP');
            jsonGen.writeStringField('matched_entry_type', 'Individual');
            jsonGen.writeStringField('master_entry', 'test master PEP');
            jsonGen.writeStringField('master_entry_type', 'Individual');
            jsonGen.writeNumberField('score', 100);
            jsonGen.writeEndObject();
            jsonGen.writeEndArray();
        }else if(diligentApi == 'convert_to_monitor'){
            jsonGen.writeNumberField('list_id', Integer.valueof((Math.random() * 1000)));
            jsonGen.writeNumberField('term_id', Integer.valueof((Math.random() * 1000)));
        }else if(diligentApi == 'monitor_list'){
            jsonGen.writeNumberField('list_id', Integer.valueof((Math.random() * 1000)));
            jsonGen.writeStringField('active', 'Monitor');
        }
        jsonGen.writeEndObject();
        
        return jsonGen.getAsString();  
    }
    
}
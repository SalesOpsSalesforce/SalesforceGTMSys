//[RGaokar 11/03/2022 SFDC - 1157 SF to Redpoint Helper Class for Redpoint Callouts]
//[RGaokar 03/28/2023 SFDC-2233 Reduce SF -> Workato task by reducing the frequency of hitting Workato webhook (Sending direct call to Redpoint for less records)]
//[RGaokar 04/11/2023 SFDC-2350  SF -> Redpoint Workato task reduction: Remove Workato loops by sending individual Contact payload instead of account & related contacts in payload]
//[RGaokar 09/12/2023 SFDC-3536 Shut down the direct call from SF to Redpoint]
public class RedpointCalloutHandler implements system.Queueable, Database.AllowsCallouts{
    List<RedpointRecordWrapper> payload = new List<RedpointRecordWrapper>();
    Static Boolean sandboxOrg = [SELECT IsSandbox FROM Organization].IsSandbox;
    Static Map<String, Redpoint_API_Key__mdt > redpointCredentials = Redpoint_API_Key__mdt.getAll();
    Static Map<string, id>PayloadKeyRecordIdMap = new Map<string, id>();//Stores Klaviyo profile id/email & respective record id for Update/Identity profile error handling purpose
    public RedpointCalloutHandler(List<RedpointRecordWrapper> payload){
        this.payload = payload;
    }
    
    public void execute(system.QueueableContext ctx){
        //Workato Processing
        String orgNamedcredential;
        String orgAPIKey;
        String orgType = (!sandboxOrg)? 'Production':'Sandbox';
        String errorString = '';
        //Get credentials
        If(!sandboxOrg){//Production
            orgNamedcredential = 'callout:'+ redpointCredentials.get('Workato_Identity_Profile_Webhook').Named_Credential_for_Org__c;
            orgAPIKey = redpointCredentials.get('Workato_Identity_Profile_Webhook').API_Key__c;
        }else{//Sandbox
            orgNamedcredential = 'callout:'+ redpointCredentials.get('Sandbox_Workato_Identity_Profile_Webhook').Named_Credential_for_Org__c;
            orgAPIKey = redpointCredentials.get('Sandbox_Workato_Identity_Profile_Webhook').API_Key__c;
        }
        
        //Create JSON Payload
        String workatoPayload = '{"Data":' + JSON.serialize(payload) + '}';
        //system.debug('Json response --'+workatoPayload);
        string endPointURL = orgNamedcredential;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointURL);
        req.setHeader('Authorization', 'api-key '+orgAPIKey);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('accept', 'application/json');
        req.setHeader('Org_Type', orgType);
        req.setMethod('POST');
        req.setBody(workatoPayload);
        try{
            Http http = new Http();
            HttpResponse response = new HttpResponse();
            if(!Test.isRunningTest() && !sandboxOrg){
                response = http.send(req);
            }else{
                response.setHeader('Content-Type', 'application/json');
                response.setStatusCode(200);
            }
            
            if (response != null && response.getStatusCode() != 200){//If error comes
                errorString += '\n'+' Response Code: '+response.getStatusCode();
            }
        }catch(System.CalloutException ex){
            //system.debug('Error Message: '+ex.getMessage());
            errorString += '\n'+' Error Message: '+ex.getMessage();
        }
        
        //Process errors
        if(String.isNotBlank(errorString) || Test.isRunningTest()){
            processErrors(errorString, payload);
        }
        
        //RGaokar 09/12/2023 SFDC-3536 Commenting direct call
        //Workato Processing
        /*If(payload.size() > 10 || Test.isRunningTest()){//Workato task reduction using direct call to Redpoint api for payload.size() <= 10}else{//Redpoint API Processing
			//Workato Processing....
		}else{
			processRedpointAPIPayload(payload);
		}*/
    }
    
    //Workato Callout error handling
    private static void processErrors(String errorString, List<RedpointRecordWrapper> payload){
        //Get all failed record ids
        Set<Id> failedsObjIds = new Set<Id>();
        List<sObject> sObjectUpdateList = new List<sObject>();
        List <String> errorList = new List <String> ();
        for(RedpointRecordWrapper redpointPayload:payload){
            failedsObjIds.add((Id)redpointPayload.Record.get('SF_Id'));
        }
        
        if(!failedsObjIds.isEmpty()){
            for(Id sObjId:failedsObjIds){
                sObject sObj = sObjId.getSobjectType().newSObject(sObjId);
                sObj.put('Failed_Redpoint_Sync__c', true);
                sObjectUpdateList.add(sObj);
            }
            errorList.add('Following error occured for Redpoint K4K Sync:');
            errorList.add(errorString);
            errorList.add('The record ids failed Workato Sync are:');
            errorList.addAll(new List<Id>(failedsObjIds));
        }
        
        //Update Failed Records
        if(!sObjectUpdateList.isEmpty()){
            List<Database.SaveResult> srList = Database.update(sObjectUpdateList, false);
            String updateErrors = '';
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    updateErrors += '\n'+'Record Id: '+ result.getId();
                    for(Database.Error err : result.getErrors()) {
                        updateErrors += ' Error Message: ' +err.getMessage()+'\n';
                    }  
                }
            }
            
            if (String.isNotBlank(updateErrors)){
                errorList.add('Errors occured when updating Failed Redpoint Sync flag for following records:');
                errorList.add(updateErrors);
            }
        }
        
        if(!errorList.isEmpty()){
            ExceptionHandling.performExceptionHandling(null, 'RedpointCalloutHandler', errorList);  
        }
    }
    
    //Redpoint Payload Processor Wrapper
    public class RedpointRecordWrapper {
        public map<string,object> Record {get;set;}
        
        //Redpoint Payload includes record
        public RedpointRecordWrapper(map<string,object> Record){
            this.Record = Record;
        }
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    //[RGaokar 03/28/2023 SFDC-2233 Workato Task Reduction: Reduce frequency of calling Workato recipe]
    //Directly send callout to Redpoint if records are less than or equal to 10
    //Keeping this logic seperate from workato callout if we need to shut down this entirely in future
    //Commenting Direct call [RGaokar 09/12/2023 SFDC-3536 Shut down the direct call from SF to Redpoint]
    
    /*public static void processRedpointAPIPayload(List<RedpointRecordWrapper> payloadList){
        List<UpdateProfileWrapper> updateProfileList = new List<UpdateProfileWrapper>();
        List<IdentityProfileWrapper> identityProfileList = new List<IdentityProfileWrapper>();
        map<string,string>errorMap = new map<string,string>();//Captures errors if any
        
        for(RedpointRecordWrapper payload:payloadList){  
            if(payload.Record.get('Klaviyo_Profile_ID__c') != null){
                PayloadKeyRecordIdMap.put((string)payload.Record.get('Klaviyo_Profile_ID__c'),(Id)payload.Record.get('SF_Id'));
                updateProfileList.add(new UpdateProfileWrapper(payload));   
            }else{
                PayloadKeyRecordIdMap.put((string)payload.Record.get('email'),(Id)payload.Record.get('SF_Id'));
                identityProfileList.add(new IdentityProfileWrapper(payload));
            } 
        }
        
        if(!updateProfileList.isEmpty()){
            errorMap.putAll(sendUpdateProfileCallouts(updateProfileList));
        }
        
        if(!identityProfileList.isEmpty()){
            errorMap.putAll(sendIdentityProfileCallouts(identityProfileList)); 
        }
        
        //Send error to Slack & Mark record as failed
        if(!errorMap.isEmpty() || Test.isRunningTest()){
            processRedpointErrors(errorMap);
        }
    }
    
    public class UpdateProfileWrapper{
        public string type;
        public string id;
        public map<string,object> attributes = new map<string,object>();
        
        public UpdateProfileWrapper(RedpointRecordWrapper payload){
            string email;
            this.type = 'profile';
            this.id = (string)payload.Record.get('Klaviyo_Profile_ID__c');
            email = (string)payload.Record.get('email');
            payload.Record.remove('Klaviyo_Profile_ID__c');//Remove additional properties
            payload.Record.remove('email');//Remove additional properties
            payload.Record.remove('SF_Id');//Remove additional properties
            payload.Record.remove('AccountId');//Remove additional properties
            map <string,object> properties = payload.Record;
            if(string.isNotBlank(email)) this.attributes.put('email', email);
            this.attributes.put('properties',properties);
        }
    }
    
    public class IdentityProfileWrapper{
        public map<string,object> identityRecord = new map<string,object>();
        public IdentityProfileWrapper(RedpointRecordWrapper payload){
            payload.Record.remove('Klaviyo_Profile_ID__c');//remove additional properties
            payload.Record.remove('SF_Id');//remove additional properties
            payload.Record.remove('AccountId');//remove additional properties
            this.identityRecord.putAll(payload.Record);  
        }   
    }
    
    public static map<string,string> sendUpdateProfileCallouts(List<UpdateProfileWrapper>payloadList){
        String orgNamedcredential;
        String orgAPIKey;
        map<string,string>errorMap = new map<string,string>();//Captures errors if any
        
        //Get credentials
        If(!sandboxOrg){//Production
            orgNamedcredential = 'callout:'+ redpointCredentials.get('Redpoint_Private_API_Key_Production').Named_Credential_for_Org__c;
            orgAPIKey = redpointCredentials.get('Redpoint_Private_API_Key_Production').API_Key__c;
        }else{//Sandbox
            orgNamedcredential = 'callout:'+ redpointCredentials.get('Redpoint_Private_API_Key_Sandbox').Named_Credential_for_Org__c;
            orgAPIKey = redpointCredentials.get('Redpoint_Private_API_Key_Sandbox').API_Key__c;
        }
        
        for(UpdateProfileWrapper updatePayload:payloadList){
            //Create JSON Payload
            string payloadBody = '{"data":' + JSON.serialize(updatePayload) + '}';
            //system.debug('Json payloadBody --'+payloadBody);
            string endPointURL = orgNamedcredential + '/profiles/' + updatePayload.id;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPointURL);
            req.setHeader('Authorization', 'Klaviyo-API-Key '+orgAPIKey);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('accept', 'application/json');
            req.setHeader('revision', '2023-02-22');
            req.setMethod('PATCH');
            req.setBody(payloadBody);
            errorMap.putAll(processRedpointCallout(req,'Update',updatePayload)); 
        }
        
        return errorMap;
    }
    
    
    public static map<string,string> sendIdentityProfileCallouts(List<IdentityProfileWrapper>payloadList){
        String orgNamedcredential;
        String orgAPIKey;
        map<string,string>errorMap = new map<string,string>();//Captures errors if any
        
        //Get credentials
        If(!sandboxOrg){//Production
            orgNamedcredential = 'callout:'+ redpointCredentials.get('Redpoint_Public_API_Key_Production').Named_Credential_for_Org__c;
            orgAPIKey = redpointCredentials.get('Redpoint_Public_API_Key_Production').API_Key__c;
        }else{//Sandbox
            orgNamedcredential = 'callout:'+ redpointCredentials.get('Redpoint_Public_API_Key_Sandbox').Named_Credential_for_Org__c;
            orgAPIKey = redpointCredentials.get('Redpoint_Public_API_Key_Sandbox').API_Key__c;
        }
        
        for(IdentityProfileWrapper payload:payloadList){
            //Create JSON Payload
            map<string,object> requestBodyMap = new map<string,object>();
            requestBodyMap.put('token', orgAPIKey);
            requestBodyMap.put('properties', payload.identityRecord);
            string payloadBody = 'data=' + EncodingUtil.urlEncode(JSON.serialize(requestBodyMap),'UTF-8');
           	//system.debug('payloadBody --'+payloadBody);
            string endPointURL = orgNamedcredential + '/identify';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPointURL);
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('accept', 'text/html');
            req.setMethod('POST');
            req.setBody(payloadBody);
            errorMap.putAll(processRedpointCallout(req, 'Identity', payload.identityRecord));
        }
        
        return errorMap;
    }
    
    //Callout request helper for direct Redpoint Callout
    public static map<string,string> processRedpointCallout(HttpRequest req, string apiType, object payload){
        String errorString = '';
        Id recordId;
        map<string,string>errorMap = new map<string,string>();
        try{
            Http http = new Http();
            HttpResponse response = new HttpResponse();
            if(!Test.isRunningTest() && !sandboxOrg){
                response = http.send(req);
                //system.debug('response--'+response.getBody());
            }else{
                response.setHeader('Content-Type', 'application/json');
                response.setStatusCode(200);
            }
            
            if (response != null && response.getStatusCode() != 200 && apiType == 'Update'){//If error comes for update api
                recordId = PayloadKeyRecordIdMap.get(((UpdateProfileWrapper)payload).id);
                errorString += '\n'+' SF Record -> Redpoint Profile Sync Failed. SF Record Ids: '+recordId + '\n'+ response.getBody();
            }else if (response != null && response.getStatusCode() == 200 && apiType == 'Identity' && response.getBody() == '0'){//If error comes for identity api, it sends response as 0 with response code of 200
                recordId = PayloadKeyRecordIdMap.get((string)((map<string,object>)payload).get('email'));
                errorString += '\n'+' SF Record -> Redpoint Profile Sync Failed. SF Record Ids: '+recordId + ' Body: ' +response.getBody();
            }
        }catch(System.CalloutException ex){
            if(apiType == 'Update'){
                recordId = PayloadKeyRecordIdMap.get(((UpdateProfileWrapper)payload).id);
                errorString += '\n'+' SF Record -> Redpoint Profile Sync Failed. SF Record Ids: '+recordId;
            }else if(apiType == 'Identity'){
                recordId = PayloadKeyRecordIdMap.get((string)((map<string,object>)payload).get('email'));
                errorString += '\n'+' SF Record -> Redpoint Profile Sync Failed. SF Record Ids: '+recordId; 
            }
            errorString += '\n'+' Error Message: '+ex.getMessage();
        }
        
        if(string.isNotBlank(errorString) && apiType != 'Slack'){
            errorMap.put(recordId,errorString);
        }
        
        return errorMap;
    }
    
    //Error handling for direct Redpoint callout
    public static void processRedpointErrors(map<string,string>processedRequestMap){
        List<sObject> sObjectUpdateList = new List<sObject>();
        //Send message to Slack Redpoint error channel
        String orgNamedcredential;
        String endPointURL;
        If(!sandboxOrg){//Production
            orgNamedcredential = 'callout:'+ redpointCredentials.get('Redpoint_Slack_Webhook_Production').Named_Credential_for_Org__c;
            endPointURL = orgNamedcredential + redpointCredentials.get('Redpoint_Slack_Webhook_Production').Webhook_URL__c;
        }else{//Sandbox
            orgNamedcredential = 'callout:'+ redpointCredentials.get('Redpoint_Slack_Webhook_Sandbox').Named_Credential_for_Org__c;
            endPointURL = orgNamedcredential + redpointCredentials.get('Redpoint_Slack_Webhook_Sandbox').Webhook_URL__c;
        }
        for(Id sObjId: processedRequestMap.keyset()){
            map<string,string>requestBody = new map<string, string>();
            requestBody.put('text',(string)processedRequestMap.get(sObjId));
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPointURL);
            req.setMethod('POST');
            req.setBody(Json.serialize(requestBody));
            processRedpointCallout(req, 'Slack', null);
            
            //Add failed records
            sObject sObj = sObjId.getSobjectType().newSObject(sObjId);
            sObj.put('Failed_Redpoint_Sync__c', true);
            sObjectUpdateList.add(sObj);
        }
        
        //Update Failed Records
        List<Database.SaveResult> srList = Database.update(sObjectUpdateList, false);   
    }*/
}
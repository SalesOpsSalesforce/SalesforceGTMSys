//[RGaokar 02/16/2023 SFDC-1359 Salesforce -> Redpoint Customer Onboarding request callout helper]
public class RedpointCustomerOnboardingCallout {
    //Prepare payalod for Redpoint Sync
    public static void processRedpointPayload(List<RedpointCustomerOnboardingProcessor.CustomerOnboardingEventPayload>payloadList){
        List<RedpointPayload>redpointPayloadList = new List<RedpointPayload>(); 
        for(RedpointCustomerOnboardingProcessor.CustomerOnboardingEventPayload payload:payloadList){
            string onboardingdatetype = payload.OnboardingStatus == 'Onboarding Completed' ? 'SFD_CompletedOnboardingDate' : 'SFD_CancelledOnboardingDate';
            datetime onboardingDate = payload.OnboardingStatus == 'Onboarding Completed' ? payload.CompletedOnboardingDate : payload.CancelledOnboardingDate;
            string eventName = payload.OnboardingStatus == 'Onboarding Completed' ? 'Completed Onboarding' : 'Cancelled Onboarding';
            
            //[VR 11/30/2023 SFDC-3606] Add Klaviyo Account ID & OBS - payload.OnboardingName, payload.KlaviyoAccountId, payload.OnboardingCompletedDate, payload.OnboardingSegment, payload.OnboardingProducts, payload.AssignedOnboardingRep
            if(string.isNotBlank(payload.PrimaryKlaviyoUserEmail)){
                RedpointPayload processedPayload = new RedpointPayload(payload.PrimaryKlaviyoUserEmail,'Main_User__c',onboardingdatetype,onboardingDate,eventName,payload.OnboardingStatus,payload.customerOnboardingId, payload.OnboardingName, payload.KlaviyoAccountId, payload.OnboardingCompletedDate, payload.OnboardingSegment, payload.OnboardingProducts, payload.AssignedOnboardingRep);
                redpointPayloadList.add(processedPayload);
            }
            
            //[VR 11/30/2023 SFDC-3606] Add Klaviyo Account ID & OBS - payload.OnboardingName, payload.KlaviyoAccountId, payload.OnboardingCompletedDate, payload.OnboardingSegment, payload.OnboardingProducts, payload.AssignedOnboardingRep
            if(string.isNotBlank(payload.DecisionMakerEmail)){
                RedpointPayload processedPayload = new RedpointPayload(payload.DecisionMakerEmail,'Economic_Buyer__c',onboardingdatetype,onboardingDate,eventName,payload.OnboardingStatus,payload.customerOnboardingId, payload.OnboardingName, payload.KlaviyoAccountId, payload.OnboardingCompletedDate, payload.OnboardingSegment, payload.OnboardingProducts, payload.AssignedOnboardingRep);
                redpointPayloadList.add(processedPayload);
            }  
        }
        
        processRedpointCallout(redpointPayloadList);  
    }
    
    //Process Callout
    public static void processRedpointCallout(List<RedpointPayload>redpointPayloadList){
        Boolean sandboxOrg = [SELECT IsSandbox FROM Organization].IsSandbox;
        Map<String, Redpoint_API_Key__mdt> redpointCredentials = Redpoint_API_Key__mdt.getAll();
        String errorString = '';
        Set<id>failedRedpointSyncIds = new Set<id>();
        List<Customer_Onboarding__c> updateCOList = new List<Customer_Onboarding__c>();
        string requestEndPointURL = 'callout:Redpoint_Create_Event';
        String orgAPIKey;
        //Get credentials
        If(!sandboxOrg){//Production
            orgAPIKey = redpointCredentials.get('Redpoint_Private_API_Key_Production').API_Key__c;
        }else{//Sandbox 
            orgAPIKey = redpointCredentials.get('Redpoint_Private_API_Key_Sandbox').API_Key__c;
        }
        
        for(RedpointPayload payload:redpointPayloadList){
            string requestBody = getRequestBody(payload);
            HttpRequest req = new HttpRequest();
            req.setEndpoint(requestEndPointURL);
            req.setHeader('Authorization', 'Klaviyo-API-Key '+orgAPIKey);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('accept', 'application/json');
            req.setHeader('revision', '2023-01-24');
            req.setMethod('POST');
            req.setBody(requestBody);
            try{
                Http http = new Http();
                HttpResponse response = new HttpResponse();
                if(!Test.isRunningTest() && sandboxOrg){
                    response = http.send(req);
                }else{
                    response.setHeader('Content-Type', 'application/json');
                    response.setStatusCode(202);
                }
                
                if (response != null && response.getStatusCode() != 202){//If error comes
                    errorString += '\n'+'Record Id: ' +payload.customerOnboardingId +' Response Code: '+response.getStatusCode();
                    failedRedpointSyncIds.add(payload.customerOnboardingId);
                }
            }catch(System.CalloutException ex){
                errorString += '\n'+'Record Id: ' +payload.customerOnboardingId +' Error Message: '+ex.getMessage();
                failedRedpointSyncIds.add(payload.customerOnboardingId);
            }  
        }
        
        //Error handling
        if(string.isNotBlank(errorString) || Test.isRunningTest()){
            List <String> errorList = new List <String> ();
            errorList.add('Errors occured during Customer onboarding Redpoint sync for following records:');
            errorList.add(errorString);
            ExceptionHandling.performExceptionHandling(null, 'RedpointCustomerOnboardingCallout', errorList);
            
            for(id recordId:failedRedpointSyncIds){
                updateCOList.add(new Customer_Onboarding__c(id = recordId, Failed_Redpoint_Sync__c = true));
            }
            
            if(!updateCOList.isEmpty()){
                List<Database.SaveResult> srList = Database.update(updateCOList, false);
            }
        } 
    }
    
    //Prepare request body
    public static string getRequestBody(RedpointPayload payload){
        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeFieldName('data');
        jsonGen.writeStartObject();
        jsonGen.writeStringField('type', 'event');
        jsonGen.writeFieldName('attributes');
        jsonGen.writeStartObject();
        jsonGen.writeFieldName('profile');
        jsonGen.writeStartObject();
        jsonGen.writeDateTimeField(payload.onboardingdatetype, payload.onboardingDate);
        jsonGen.writeStringField('SFD_OnboardingStatus', payload.OnboardingStatus);
        jsonGen.writeStringField('$email', payload.email);
        jsonGen.writeEndObject();//profile
        jsonGen.writeFieldName('metric');
        jsonGen.writeStartObject();
        jsonGen.writeStringField('name', payload.eventName);
        jsonGen.writeEndObject();//metric
        jsonGen.writeFieldName('properties');
        jsonGen.writeStartObject();
        jsonGen.writeStringField('SFD_OnboardingRecordRole', payload.OnboardingRecordRole);
        //[VR 11/30/2023 SFDC-3606] Added in below fields
        jsonGen.writeStringField('onboarding_name', payload.onboardingName);
        jsonGen.writeStringField('current_account_id', payload.klaviyoAccountId);
        jsonGen.writeStringField('onboarding_status', payload.OnboardingStatus);
        jsonGen.writeDateField('onboarding_completed_date', payload.onboardingCompletedDate);
        jsonGen.writeStringField('onboarding_segment', payload.onboardingSegment);
        jsonGen.writeStringField('onboarding_product', payload.onboardingProduct);
        jsonGen.writeStringField('assigned_onboarding_rep', payload.assignedOnboardingRep);
        jsonGen.writeEndObject();//properties
        jsonGen.writeEndObject();//attributes
        jsonGen.writeEndObject();//data
        jsonGen.writeEndObject();
        return jsonGen.getAsString();
    }
    
    public class RedpointPayload{
        public string email{get;set;}
        public string onboardingdatetype{get;set;}
        public datetime onboardingDate{get;set;}
        public string eventName{get;set;}
        public string OnboardingRecordRole{get;set;}
        public string OnboardingStatus{get;set;}
        public string customerOnboardingId{get;set;}
        //[VR 11/30/2023 SFDC-3606] Added in below fields
        public String onboardingName{get;set;}
        public String klaviyoAccountId{get;set;}
        public Date onboardingCompletedDate{get;set;}
        public String onboardingSegment{get;set;}
        public String onboardingProduct{get;set;}
        public String assignedOnboardingRep{get;set;}
        
        //[VR 11/30/2023 SFDC-3606] Updated payload String onboardingName, String klaviyoAccountId, Date onboardingCompletedDate, String onboardingSegment, String onboardingProduct, String assignedOnboardingRep
        public RedpointPayload(string email,string OnboardingRecordRole,string onboardingdatetype,datetime onboardingDate,string eventName, string OnboardingStatus,string customerOnboardingId, String onboardingName, String klaviyoAccountId, Date onboardingCompletedDate, String onboardingSegment, String onboardingProduct, String assignedOnboardingRep){
            this.email = email;
            this.onboardingdatetype = onboardingdatetype;
            this.onboardingDate = onboardingDate;
            this.eventName = eventName;
            this.OnboardingRecordRole = OnboardingRecordRole;
            this.OnboardingStatus = OnboardingStatus;
            this.customerOnboardingId = customerOnboardingId;
            //[VR 11/30/2023 SFDC-3606] Added in below fields
            this.onboardingName = onboardingName;
            this.klaviyoAccountId = klaviyoAccountId;
            this.onboardingCompletedDate = onboardingCompletedDate;
            this.onboardingSegment = onboardingSegment;
            this.onboardingProduct = onboardingProduct;
            this.assignedOnboardingRep = assignedOnboardingRep;
        }
    }
    
}
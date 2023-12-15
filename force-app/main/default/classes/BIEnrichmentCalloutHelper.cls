//[RGaokar 11/07/2023 SFDC-3627 Send Salesforce Account/Lead Info to BI Model - Callout Helper]
public class BIEnrichmentCalloutHelper {
    public static void sendPayload(List<BIEnrichmentProcessor.BIEnrichmentRecordWrapper> biPayload){
        Boolean sandboxOrg = [SELECT IsSandbox FROM Organization].IsSandbox;
        Map<String, Workato_BI_Enrichment_Credential__mdt> workatoBIEnrichmentCredentials = Workato_BI_Enrichment_Credential__mdt.getAll();
        String orgAPIKey;
        String orgType = (!sandboxOrg)? 'Production':'Sandbox';
        String endpointURL = 'callout:Workato_Webhook';
        String errorString = '';
        
        //Get credentials
        If(!sandboxOrg){//Production
            endpointURL += workatoBIEnrichmentCredentials.get('Workato_BI_Enrichment_Production').Webhook_URL__c;
            orgAPIKey = workatoBIEnrichmentCredentials.get('Workato_BI_Enrichment_Production').API_Key__c;
        }else{//Sandbox 
            endpointURL += workatoBIEnrichmentCredentials.get('Workato_BI_Enrichment_Sandbox').Webhook_URL__c;
            orgAPIKey = workatoBIEnrichmentCredentials.get('Workato_BI_Enrichment_Sandbox').API_Key__c;
        }
        
        //Send payload to Workato
        //system.debug('payload--'+ '{"data":' + JSON.serialize(biPayload) + '}');
        //Create Request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointURL);
        req.setHeader('Authorization', 'api-key '+orgAPIKey);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('accept', 'application/json');
        req.setHeader('Org_Type', orgType);
        req.setMethod('POST');
        req.setBody('{"data":' + JSON.serialize(biPayload) + '}');
        try{
            Http http = new Http();
            HttpResponse response = new HttpResponse();
            if(!Test.isRunningTest() && !sandboxOrg){
                response = http.send(req);
            }else{
                response.setHeader('Content-Type', 'application/json');
                response.setStatusCode(200);
            }
            
            if(response != null && response.getStatusCode() == 200){//For successful sync unchecked the Segmentation Sync Ready flag on records
                processSuccess(biPayload);
            }else if (response != null && response.getStatusCode() != 200){//If error comes
                errorString += '\n'+' Response Code: '+response.getStatusCode();
            }
        }catch(System.CalloutException ex){
            errorString += '\n'+' Error Message: '+ex.getMessage();
        }
        
        if(String.isNotBlank(errorString) || Test.isRunningTest()){
            processErrors(errorString,biPayload);
        }
    }
    
    //Workato Callout success handling - Unchecked Segmentation Sync Ready flag on records
    private static void processSuccess(List<BIEnrichmentProcessor.BIEnrichmentRecordWrapper> biPayload){
        List<sObject> sObjectSuccessList = new List<sObject>();
        for(BIEnrichmentProcessor.BIEnrichmentRecordWrapper payload:biPayload){
            Id sObjId = (Id)payload.Record.get('Id');
            sObject sObj = sObjId.getSobjectType().newSObject(sObjId);
            sObj.put('Segmentation_Sync_Ready__c', false);
            sObjectSuccessList.add(sObj);
        }
        
        //Update Success Records to unset Segmentation_Sync_Ready__c
        if(!sObjectSuccessList.isEmpty()){
            List<Database.SaveResult> srList = Database.update(sObjectSuccessList, false);
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    system.debug('Record Id: '+ result.getId());
                    for(Database.Error err : result.getErrors()) {
                        system.debug('Error Message: ' +err.getMessage());
                    }  
                }
            }
        }
    }
    
    //Workato Callout error handling
    private static void processErrors(String errorString, List<BIEnrichmentProcessor.BIEnrichmentRecordWrapper> biPayload){
        //Get all failed records
        map<Id,string> failedsObjMap = new map<Id,string>();
        List<sObject> sObjectUpdateList = new List<sObject>();
        List <String> errorList = new List <String> ();
        for(BIEnrichmentProcessor.BIEnrichmentRecordWrapper payload:biPayload){
            failedsObjMap.put((Id)payload.Record.get('Id'), (string)payload.Record.get('BI_Enrichment_Sync_Status__c'));
        }
        
        if(!failedsObjMap.isEmpty()){
            string statusToRemove = 'Success - ' + biPayload[0].Record.get('type');
            string statusToUpdate = 'Failed - ' + biPayload[0].Record.get('type');
            
            for(Id sObjId:failedsObjMap.keyset()){
                sObject sObj = sObjId.getSobjectType().newSObject(sObjId);
                string bIEnrichmentSyncStatus = failedsObjMap.get(sObjId);
                
                if(bIEnrichmentSyncStatus != null && !bIEnrichmentSyncStatus.containsIgnoreCase(statusToUpdate)){
                    List<string> bIEnrichmentSyncStatusList = bIEnrichmentSyncStatus.split(';');
                    if(bIEnrichmentSyncStatusList.contains(statusToRemove)){
                        bIEnrichmentSyncStatusList.remove(bIEnrichmentSyncStatusList.indexOf(statusToRemove));
                    }
                    bIEnrichmentSyncStatusList.add(statusToUpdate);
                    bIEnrichmentSyncStatus = String.join(bIEnrichmentSyncStatusList,';');
                }else if(bIEnrichmentSyncStatus == null){
                    bIEnrichmentSyncStatus = statusToUpdate;
                }
                
                sObj.put('BI_Enrichment_Sync_Status__c', bIEnrichmentSyncStatus);
                sObjectUpdateList.add(sObj);
            }
            errorList.add('Following error occured for BI Enrichment Sync:');
            errorList.add(errorString);
            errorList.add(' The record ids failed Workato Sync are: ');
            errorList.addAll(new List<Id>(failedsObjMap.keyset()));
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
                errorList.add('Errors occured when updating BI Enrichment Sync Status for following records: ');
                errorList.add(updateErrors);
            }
        }
        
        if(!errorList.isEmpty()){
            ExceptionHandling.performExceptionHandling(null, 'BIEnrichmentCalloutHelper', errorList);  
        }
    }
    
}
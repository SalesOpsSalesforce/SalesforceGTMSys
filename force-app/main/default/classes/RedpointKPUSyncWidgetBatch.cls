//[RGaokar 12/01/2022 SFDC-1158 Update account & leads if respective KPU monitored formula fields get update]
//Using invocable method & batch apex as KPU updates happens in bulk & lead object cannot process batch of standard size 200
//This method is called from KPU after save if Redpoint monitored KPU fields are updated & matching account/lead found
//[RGaokar 07/27/2023 SFDC:3218 Extending this class as a HELPER class to handle all use cases other than KPU]
//[RGaokar 07/27/2023 SFDC:3218 Adding logic to handle related records update for Redpoint Sync Widget Update]
public class RedpointKPUSyncWidgetBatch implements database.Batchable<sObject>{
    List<paramRedpointSyncWidget> redpointWidgetParams;
    public RedpointKPUSyncWidgetBatch(List<paramRedpointSyncWidget> redpointWidgetParams){
        this.redpointWidgetParams = redpointWidgetParams;
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        set<Id> accountIds = new set <Id>();
        set<Id> leadIds = new set <Id>();
        string query;
        for(paramRedpointSyncWidget record:redpointWidgetParams){
            if(record.sObjectType == 'Account'){
                accountIds.add(record.sObjId);
            }else if(record.sObjectType == 'Lead'){
                leadIds.add(record.sObjId);
            } 
        }
        
        if(!accountIds.isEmpty()){
            query = 'Select id, Redpoint_Formula_Sync_Widget__c from account where id in :accountIds';  
        }
        
        if(!leadIds.isEmpty()){
            query = 'Select id, Redpoint_Formula_Sync_Widget__c from lead where id in :leadIds';  
        }
        
        return Database.getQueryLocator(query);  
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        processRedpointSyncWidgetUpdates(scope); 
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
    //RGaokar 07/27/2023 SFDC:3218 Method change to Helper method which will be also called by other use cases than KPU
    //Invocable method called from KPU after save flow when Redpoint monitored fields for KPU changes/ or other flows for related record changes
    @InvocableMethod(label='Update accounts & leads for Redpoint Formula Sync Widget')
    public static void updateRedpointSyncWidget (List<paramRedpointSyncWidget> redpointWidgetPayload){
        List<paramRedpointSyncWidget> redpointWidgetParams = new List<paramRedpointSyncWidget>();
        if(!redpointWidgetPayload.isEmpty()){
            //items in redpointWidgetPayload list in one transaction will be of same type, so checking first item is sufficient
            if(redpointWidgetPayload[0].relatedsObjRecords != null){
                redpointWidgetParams = processRelatedRecords(redpointWidgetPayload);
            }else{
                redpointWidgetParams.addAll(redpointWidgetPayload);
            }
        }
        
        if(!redpointWidgetParams.isEmpty()){
            //[RGaokar 12/12/2022 SFDC-1445,1482 To avoid flex queue burden for less number of records]
            //If records to process are less or equal to 50 then process the update Synchronously otherwise use asynchronous batch to avoid CPU timeout errors 
            if(redpointWidgetParams.size()<= 50){
                List<sObject>scope = new List<sObject>();
                for(paramRedpointSyncWidget record:redpointWidgetParams){
                    sObject sObj = record.sObjId.getSobjectType().newSObject(record.sObjId);
                    scope.add(sObj);
                }
                processRedpointSyncWidgetUpdates(scope);
            }else{
                RedpointKPUSyncWidgetBatch redpointWidget = new RedpointKPUSyncWidgetBatch(redpointWidgetParams);
                Database.executeBatch(redpointWidget, 50);//Passing 50 records to avoid timeout error
            }  
        }
        
    }
    
    //Add list of type paramRedpointSyncWidget for related records
    public static List<paramRedpointSyncWidget> processRelatedRecords(List<paramRedpointSyncWidget> redpointWidgetPayload){
        List<paramRedpointSyncWidget> redpointWidgetParams = new List<paramRedpointSyncWidget>();
        for(paramRedpointSyncWidget record:redpointWidgetPayload){
            for(sObject sObj:record.relatedsObjRecords){
                paramRedpointSyncWidget param = new paramRedpointSyncWidget();
                param.sObjId = sObj.Id;
                param.sObjectType = record.sObjectType;
                redpointWidgetParams.add(param);
            }
        }
        return redpointWidgetParams;
    }
    
    //Helper method for synchronous & asynchronous updates
    public static void processRedpointSyncWidgetUpdates(List<sObject>scope){
        //Update Redpoint_Formula_Sync_Widget__c to current time
        for(sObject sObj:scope){
            sObj.put('Redpoint_Formula_Sync_Widget__c', system.now());
        }
        
        List<Database.SaveResult> srList = Database.update(scope, false);
        String updateErrors = '';
        for(Database.SaveResult result:srList){
            if(!result.isSuccess()){
                updateErrors += '\n'+'Record Id: '+ result.getId();
                for(Database.Error err : result.getErrors()) {
                    updateErrors += ' Error Message: ' +err.getMessage()+'\n';
                }  
            }
        }
        
        if (String.isNotBlank(updateErrors) || Test.isRunningTest()){
            List <String> errorList = new List <String> ();
            errorList.add('Errors occured when setting Redpoint Formula Sync Widget for following records:');
            errorList.add(updateErrors);
            ExceptionHandling.performExceptionHandling(null, 'RedpointKPUSyncWidgetBatch', errorList);
        }
        
    }
    
   
    public class paramRedpointSyncWidget {
		@InvocableVariable
        public id sObjId;
        
		@InvocableVariable(required=true)
        public String sObjectType;
        
        @InvocableVariable
        public List<sObject> relatedsObjRecords;
    }
}
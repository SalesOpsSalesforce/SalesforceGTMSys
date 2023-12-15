//[RGaokar 12/28/2022 SFDC-1546 Offload Redpoint Formula Widget update process for KPU nightly sync job]
public class RedpointKPUNightlySyncWidgetBatch implements database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        string query = 'Select id, Redpoint_Update__c from Klaviyo_Product_Usage__c where Redpoint_Update__c = true';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Klaviyo_Product_Usage__c>scope){
        set<id>kpuIds = new set<id>();
        for(Klaviyo_Product_Usage__c kpu:scope){
            kpuIds.add(kpu.id);
            kpu.Redpoint_Update__c = false;//Clear Redpoint_Update__c flag on Klaviyo_Product_Usage__c
        }
        
        //Get related accounts for KPU Redpoint monitored changes
        List<Account> accList = [Select id,Redpoint_Formula_Sync_Widget__c from Account where Klaviyo_Product_Usage__c in :kpuIds];
        
        //Get related non-converted leads for KPU Redpoint monitored changes
        List<Lead> ldList = [Select id,Redpoint_Formula_Sync_Widget__c from Lead where Klaviyo_Product_Usage__c in :kpuIds AND isconverted = false
                            AND (Klaviyo_Profile_ID__c != null OR Email != null)];
        
        //Update Redpoint_Formula_Sync_Widget__c to current time for accounts & leads
        if(!accList.isEmpty())RedpointKPUSyncWidgetBatch.processRedpointSyncWidgetUpdates(accList);
        if(!ldList.isEmpty())RedpointKPUSyncWidgetBatch.processRedpointSyncWidgetUpdates(ldList);
        
        //Clear Redpoint_Update__c flag on Klaviyo_Product_Usage__c
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
            errorList.add('Errors occured when resetting Redpoint Update flag for following KPU records:');
            errorList.add(updateErrors);
            ExceptionHandling.performExceptionHandling(null, 'RedpointKPUNightlySyncWidgetBatch', errorList);
        }
    }
    
    public void finish(Database.BatchableContext bc){
        
    }

}
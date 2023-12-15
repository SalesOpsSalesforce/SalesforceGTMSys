//[RGaokar 02/14/2022 TP #106769] Helper class for merge operation
//Handling contact merge for AutoConvertLeads class, can be extended in future if needed to handle multiple use cases on different objects by specifying objectName.
public class MergesObjectRecordsBatch implements Database.Batchable<sObject>{
    
    Map<Id,AutoConvertLeads.DuplicateRecordInfo>MasterDuplicateRecords;
    Set<Id> MasterRecordIds;
    string objectName;
    public MergesObjectRecordsBatch(Map<Id,AutoConvertLeads.DuplicateRecordInfo>MasterDuplicateRecords, string objectName){
        this.MasterDuplicateRecords = MasterDuplicateRecords;
        this.MasterRecordIds = MasterDuplicateRecords.keyset();
        this.objectName = objectName;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'Select Id from '+objectName +' where Id in :MasterRecordIds';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        String errorString;
        for (sObject sObj:scope){  
            //Merge Operation
            Database.MergeResult result = Database.merge(sObj, MasterDuplicateRecords.get(sObj.Id).duplicateContactId, false);
            
            //If merge is successful then create ACR for master contact and account, else handle the error result
            if(result.isSuccess()){
                AccountContactRelation acr = new AccountContactRelation();
                acr.ContactId = result.getId();
                acr.AccountId = MasterDuplicateRecords.get(result.getId()).duplicateContactAccountId;
                acr.IsActive = true;
                acrList.add(acr);
            }else{
                errorString =+ '\n'+'Master/Existing Contact: '+result.getId();
                errorString =+ '\n'+'Duplicate/New Contact: '+result.getMergedRecordIds();
                for(Database.Error err : result.getErrors()) {
                    errorString =+ ': '+err.getMessage()+'\n';
                }
                system.debug('errorString--'+errorString);
            }
        }
        
        if(acrList.size() > 0){
            insert acrList;
        }
        
        //Create expection record for errors
        if(String.isNotBlank(errorString) || Test.isRunningTest()){
            List <String> executionFlow = new List <String> ();
            executionFlow.add('Errors occured when merging following contacts:');
            executionFlow.add(errorString);
            ExceptionHandling.performExceptionHandling(null, 'MergesObjectRecordsBatch', executionFlow);
        }
    }
    
    public void finish (Database.BatchableContext bc){
        
    }
    
}
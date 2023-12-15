// This class is used to set Master_Account_Id__c to null (used for account deduplication)
// Test class: AccountDeduplicationCleanBatchTest
// To manually execute from dc - Database.executeBatch(new AccountDeduplicationCleanBatch(),10);

global class AccountDeduplicationCleanBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        //Use the below for records when a master account ID already exists
        String allAccounts = 'SELECT Clean_Website__c FROM Account where  RecordType.Name = \'Klaviyo Account\' and Clean_Website__c != null and Clean_Website__c != \'-\' and Clean_Website__c != \'.\' and  Master_Account_Id__c != null';
        return Database.getQueryLocator(allAccounts);
            
    }
    
    global void execute(Database.BatchableContext bc, List<Account> acctRecList){
    
        for(Account a: acctRecList){
            a.Master_Account_Id__c = null;            
        }
        
        if(acctRecList.size() > 0){
            update acctRecList;
        }
        
    }    
    
    global void finish(Database.BatchableContext bc){
        
    }    
}
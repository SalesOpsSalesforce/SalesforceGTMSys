trigger KlaviyoAccountSync on Account (after insert, after update) {
    /**
    * If an Account's CSM, OBS, CAM, or AE changes, pass in the new User's info to sync back to Klaviyo.
    */
    
    
    try{
        // Gather Set of accounts with changes to these fields
        Map <String, String> disabledTriggers = KlaviyoAccountSync.getMetadataTypeValuesByLabel('TriggerDisablementSwitch__mdt','DisableTriggers');
        if (!Boolean.valueOf(disabledTriggers.get('KlaviyoAccountSync')) && !KlaviyoAccountSync.alreadyProcessed){
            // Grab fields to watch for changes from K4K_Account_Field__mdt
            List<String> fields = new List<String> ();
            fields.add('SUPPORT_Account_Manager__c'); // Lookup(User) field for CSM
            fields.add('Onboarding_Specialist__c'); // Lookup(User) field for OBS
            fields.add('RP_Referral_Partner_Account__c'); // Lookup(Account) field for referal partner account
            fields.add('OwnerId'); // Lookup(User) field for AE
            // Gather Set of accounts with changes to these fields
            Set<String> objectFields = Schema.SObjectType.Account.fields.getMap().keySet();
            Set<Account> accountsToSync = new Set<Account>();
            for (Account account: Trigger.new) { // Handle bulk inserts
                for (String field: fields) { // Check each watched field
                    if ((!Trigger.isUpdate || Trigger.oldMap.get(account.Id).get(field) != account.get(field)) &&
                        (objectFields.contains(field.toLowerCase()) && !accountsToSync.contains(account) && account.get(field) != null)){
                            system.debug(field + ' changed');
                            accountsToSync.add(account); // change recorded for this field, add to list
                        }
                }
            }
            if (accountsToSync.size()>0){
                // Queue new CSM list for processing
                KlaviyoAccountSync klAccountSync = new KlaviyoAccountSync(accountsToSync);
                //[06/30/2021 vr] Added the if filter while 34 and 35 are already existing lines of code
                if(KlaviyoAccountSync.isRunFromTAPBatch <> true){
                    ID jobID = System.enqueueJob(klAccountSync);
                    System.debug('Queued new job with jobID' + jobID);
                }
            }
            KlaviyoAccountSync.alreadyProcessed = true;
        } else if (Boolean.valueOf(disabledTriggers.get('KlaviyoAccountSync'))) {
            // In case trigger is disabled by trigger-disable MDT, set "alreadyProcessed = true" so tests can still pass
            KlaviyoAccountSync.alreadyProcessed = true;
        }
    } catch (Exception ex) {
        System.debug('Exception: "' + ex.getMessage() +
                     '" of type "' + ex.getTypeName() +
                     '" caused by "' + ex.getCause() +
                     '" on line number ' + ex.getLineNumber() + '\n' +
                     'Stack Trace: ' + ex.getStackTraceString());
    }
}
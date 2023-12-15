trigger K4KAccountTrigger on Account (after insert, after update) {
    /*
      If any of an Account's fields listed in the Custom Metadata Type
      K4K_Account_Field__mdt change, send that account for further processing
     */

     try{
       // Only run code if trigger isn't disabled and it hasn't already run
       Map <String, String> disabledTriggers = GeneralUtils.getMetadataTypeValuesByLabel('K4KDisableTrigger__mdt','K4KDisableTrigger');
       if (!Boolean.valueOf(disabledTriggers.get('K4KAccountTrigger')) && !K4KProcessor.alreadyProcessed){
        // Grab fields to watch for changes from K4K_Account_Field__mdt
        Map <String, String> k4kAccountFields = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Account_Field__mdt','K4K_CS_v1');
        List<String> fields = k4kAccountFields.values();

        // Gather Set of accounts with changes to these fields
        Set<String> objectFields = Schema.SObjectType.Account.fields.getMap().keySet();
        Set<SObject> accountsToSync = new Set<SObject>();
        for (Account account: Trigger.new) { // Handle bulk inserts
            if (Trigger.isUpdate){
              for (String field: fields) { // Check each watched field
                if (objectFields.contains(field.toLowerCase()) && !accountsToSync.contains(account) && Trigger.oldMap.get(account.Id).get(field) != account.get(field)){
                  accountsToSync.add(account); // change recorded for this field, add to list
                }
              }
            }
            else {
              accountsToSync.add(account); // change recorded for this field, add to list
            }
        }
        if (accountsToSync.size()>0){
          // Queue account list for processing
          K4KProcessor k4kClient = new K4KProcessor(accountsToSync);
          ID jobID = System.enqueueJob(k4kClient);
          System.debug('Queued new job with jobID' + jobID);
        }
        K4KProcessor.alreadyProcessed = true;
      } else if (Boolean.valueOf(disabledTriggers.get('K4KAccountTrigger'))) {
        // In case trigger is disabled by trigger-disable MDT, set "alreadyProcessed = true" so tests can still pass
        K4KProcessor.alreadyProcessed = true;
      }
    } catch (Exception ex) {
      GeneralUtils.logException(ex);
    }
}
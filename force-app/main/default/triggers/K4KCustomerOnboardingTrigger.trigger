trigger K4KCustomerOnboardingTrigger on Customer_Onboarding__c (after insert, after update) {
    /*
      If any of an CustomerOnboarding's fields listed in the 1 entry for Custom Metadata Type
      K4K_Customer_Onboarding_Field__mdt change, send that Customer Onboarding for further processing
    */
    try{
      // Only run code if trigger isn't disabled and it hasn't already run
      Map <String, String> disabledTriggers = GeneralUtils.getMetadataTypeValuesByLabel('K4KDisableTrigger__mdt','K4KDisableTrigger');
      if (!Boolean.valueOf(disabledTriggers.get('K4KCustomerOnboardingTrigger')) && !K4KProcessor.alreadyProcessed){
       // Get K4K CustomerOnboarding Fields we're watching for from entry on the K4K CustomerOnboarding Field custom Metadata Type
       Map <String, String> k4kCustomerOnboardingFields = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Customer_Onboarding_Field__mdt','K4K_OB_v1');
       List<String> fields = k4kCustomerOnboardingFields.values();

       // Gather Set of customerOnboardings with changes to these fields
       Set<String> objectFields = Schema.SObjectType.Customer_Onboarding__c.fields.getMap().keySet();
       Set<SObject> customerOnboardingsToSync = new Set<SObject>();
       for (Customer_Onboarding__c customerOnboarding: Trigger.new) { // Handle bulk inserts
           if (Trigger.isUpdate){
             for (String field: fields) { // Check each watched field
               if (objectFields.contains(field.toLowerCase()) && !customerOnboardingsToSync.contains(customerOnboarding) && Trigger.oldMap.get(customerOnboarding.Id).get(field) != customerOnboarding.get(field)){
                 customerOnboardingsToSync.add(customerOnboarding); // change recorded for this field, add to list
               }
             }
           }
           else {
             customerOnboardingsToSync.add(customerOnboarding); // change recorded for this field, add to list
           }
       }
       if (customerOnboardingsToSync.size()>0){
         // Queue customerOnboarding list for processing
         K4KProcessor k4kClient = new K4KProcessor(customerOnboardingsToSync);
         ID jobID = System.enqueueJob(k4kClient);
         System.debug('Queued new job with jobID' + jobID);
       }
       K4KProcessor.alreadyProcessed = true;
     } else if (Boolean.valueOf(disabledTriggers.get('K4KCustomerOnboardingTrigger'))) {
       // In case trigger is disabled by trigger-disable MDT, set "alreadyProcessed = true" so tests can still pass
       K4KProcessor.alreadyProcessed = true;
     }
   } catch (Exception ex) {
     GeneralUtils.logException(ex);
   }
}
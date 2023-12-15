trigger K4KLeadTrigger on Lead (after insert, after update) {
    /*
      If any of an Lead's fields listed in the 1 entry for Custom Metadata Type
      K4K_Lead_Field__mdt change, send that lead for further processing
     */
     try{
       // Only run code if trigger isn't disabled and it hasn't already run
       Map <String, String> disabledTriggers = GeneralUtils.getMetadataTypeValuesByLabel('K4KDisableTrigger__mdt','K4KDisableTrigger');
       if (!Boolean.valueOf(disabledTriggers.get('K4KLeadTrigger')) && !K4KProcessor.alreadyProcessed){
        // Get K4K Lead Fields we're watching for from entry on the K4K Lead Field custom Metadata Type
        Map <String, String> k4kLeadFields = GeneralUtils.getMetadataTypeValuesByLabel('K4K_Lead_Field__mdt','K4K_M_v1');
        List<String> fields = k4kLeadFields.values();

        // Gather Set of leads with changes to these fields
        Set<String> objectFields = Schema.SObjectType.Lead.fields.getMap().keySet();
        Set<SObject> leadsToSync = new Set<SObject>();
        for (Lead lead: Trigger.new) { // Handle bulk inserts
            if (Trigger.isUpdate){
              for (String field: fields) { // Check each watched field
                if (objectFields.contains(field.toLowerCase()) && !leadsToSync.contains(lead) && Trigger.oldMap.get(lead.Id).get(field) != lead.get(field)){
                  leadsToSync.add(lead); // change recorded for this field, add to list
                }
              }
            }
            else {
              leadsToSync.add(lead); // change recorded for this field, add to list
            }
        }
        if (leadsToSync.size()>0){
          // Queue lead list for processing
          K4KProcessor k4kClient = new K4KProcessor(leadsToSync);
          ID jobID = System.enqueueJob(k4kClient);
          System.debug('Queued new job with jobID' + jobID);
        }
        K4KProcessor.alreadyProcessed = true;
      } else if (Boolean.valueOf(disabledTriggers.get('K4KLeadTrigger'))) {
        // In case trigger is disabled by trigger-disable MDT, set "alreadyProcessed = true" so tests can still pass
        K4KProcessor.alreadyProcessed = true;
      }
    } catch (Exception ex) {
      GeneralUtils.logException(ex);
    }
}
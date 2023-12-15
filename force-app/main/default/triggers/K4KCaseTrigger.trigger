trigger K4KCaseTrigger on Case (after insert, after update) {
    /*
      If any of an Case's fields listed in the 1 entry for Custom Metadata Type
      K4K_Case_Field__mdt change, send that supportCase for further processing

      At the moment, we only care about Case types for Manual Review:
      RecordTypeID (Specific for manual review alert cases) = 0123o000001pPeXAAU
      Manual_Review_Alert
     */
     try{
       Id manualReviewTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get('Manual_Review_Alert').getRecordTypeId();
       // Only run code if trigger isn't disabled and it hasn't already run
       Map <String, String> disabledTriggers = GeneralUtils.getMetadataTypeValuesByLabel('K4KDisableTrigger__mdt','K4KDisableTrigger');
       if (!Boolean.valueOf(disabledTriggers.get('K4KCaseTrigger')) && !K4KProcessor.alreadyProcessed){
        // Gather Set of supportCases with changes to these fields
        Set<SObject> supportCasesToSync = new Set<SObject>();
        for (Case supportCase: Trigger.new) { // Handle bulk inserts
          if (!supportCasesToSync.contains(supportCase) && supportCase.get('RecordTypeId') == manualReviewTypeId){
            supportCasesToSync.add(supportCase); // new "Manual Review" Case, add to list
          }
        }
        // Queue supportCase list for processing
        K4KProcessor k4kClient = new K4KProcessor(supportCasesToSync);
        ID jobID = System.enqueueJob(k4kClient);
        System.debug('Queued new job with jobID' + jobID);
        K4KProcessor.alreadyProcessed = true;
      } else if (Boolean.valueOf(disabledTriggers.get('K4KCaseTrigger'))) {
        // In case trigger is disabled by trigger-disable MDT, set "alreadyProcessed = true" so tests can still pass
        K4KProcessor.alreadyProcessed = true;
      }
    } catch (Exception ex) {
      GeneralUtils.logException(ex);
    }
}
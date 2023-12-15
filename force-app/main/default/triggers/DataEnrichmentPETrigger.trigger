//[RGaokar 11/22/2022 SFDC-1182 Data Enrichment Platform Event Subscriber]
trigger DataEnrichmentPETrigger on Data_Enrichment__e (after insert) {
    DataEnrichmentPEHandler.processDataEnrichment(Trigger.new);
}
//[RGaokar 11/22/2022 SFDC-1182 Data Enrichment Platform Event Subscriber Handler]
//Passing single record to queueable to avoid filling batch flex queue
//For SW: Passing multiple records to batch of size 10 as Similarweb supports 10 Rest API requests/second
//For Charm: Passing multiple records to batch of size 100. Charm io api request supports 250 websites/request.
//Test coverage using SimilarWebTest & CharmDataEnrichmentTest
public class DataEnrichmentPEHandler {
    public static void processDataEnrichment(List<Data_Enrichment__e> newRecords){
        if(newRecords.size() == 1){
            List<Lead> ldList = [Select id, Clean_Website__c from Lead where id =:newRecords.get(0).Record_Id__c];
            system.enqueueJob(new SimilarWebMetricsProcessor(ldList, false));//Send to SW Callout
            system.enqueueJob(new CharmDataEnrichmentProcessor(ldList));//Send to Charm Callout
        }else{
            Set<Id>ldIds = new Set<Id>(); 
            for(Data_Enrichment__e deRecord:newRecords){
                ldIds.add(deRecord.Record_Id__c);
            }
            string query = 'Select id, Clean_Website__c from Lead where id in ';
            
            //Send to Charm Callout
            CharmDataEnrichmentBatch charmBatch = new CharmDataEnrichmentBatch(query, ldIds);
            Database.executeBatch(charmBatch, 100);
            
            //Send to SW Callout
            SimilarWebBatch swBatch = new SimilarWebBatch(query, ldIds, false);
            System.scheduleBatch(swBatch, 'DataEnrichmentSWBatch'+System.now(), 5, 10);//Scheduling after 5 mins to avoid record locking issues 
        }
    }
    
}
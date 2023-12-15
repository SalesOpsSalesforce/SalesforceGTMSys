//[RGaokar 11/07/2023 SFDC-3627 Send Salesforce Account/Lead Info to BI Model]
@isTest
public class BIEnrichmentTest {
    @testSetup
    static void dataSetup(){
        //Create accounts
        List<account> accList = new List<account>();
        accList.add(new Account(Name='Test Account 1', Product_Klaviyo_Account_ID__c = '1212', Website = 'test1@test.com', 
                                Country__c = 'USA', Legal_Business_Name__c = 'test1', Charm_Revenue__c = 100,
                                StoreLeads_Annual_Revenue__c = 100));
        
        accList.add(new Account(Name='Test Account 2', Product_Klaviyo_Account_ID__c = '2323', Website = 'test2@test.com', 
                                Country__c = 'USA', Legal_Business_Name__c = 'test2', Charm_Revenue__c = 200,
                                StoreLeads_Annual_Revenue__c = 200));
        
        insert accList;
        
        //Create Leads
        List<lead> leadList = new List<lead>();
        leadList.add(new lead(LastName='Test Lead 1', Website = 'test1@test.com', Country_Location__c = 'USA', 
                              Company = 'test1', Charm_Revenue__c = 100,StoreLeads_Annual_Revenue__c = 100,
                              BI_Enrichment_Sync_Status__c = 'Success - segment'));
        
        leadList.add(new lead(LastName='Test Lead 2', Website = 'test2@test.com', Country_Location__c = 'USA', 
                              Company = 'test2', Charm_Revenue__c = 200,StoreLeads_Annual_Revenue__c = 200));
        
        insert leadList;   
    }
    
    @isTest
    static void testAccountBISync(){
        List<account> accList = [Select id,Website,Country__c,Legal_Business_Name__c,Charm_Revenue__c,
                                 StoreLeads_Annual_Revenue__c,BI_Enrichment_Sync_Status__c from Account];
        
        List<BIEnrichmentProcessor.recordWrapper>records = new List<BIEnrichmentProcessor.recordWrapper>();
        for(account a:accList){
            BIEnrichmentProcessor.recordWrapper record = new BIEnrichmentProcessor.recordWrapper();
            record.recordId = a.Id;
            record.processingType = 'segment';
            records.add(record);
        }
        
        Test.startTest();
        BIEnrichmentProcessor.getRecords(records);
        Test.stopTest();
    }
    
    @isTest
    static void testLeadBISync(){
        List<lead> leadList = [Select id,LastName,Website,Country_Location__c,Company,Charm_Revenue__c,
                               StoreLeads_Annual_Revenue__c,BI_Enrichment_Sync_Status__c from lead];
        List<BIEnrichmentProcessor.recordWrapper>records = new List<BIEnrichmentProcessor.recordWrapper>();
        for(lead l:leadList){
            BIEnrichmentProcessor.recordWrapper record = new BIEnrichmentProcessor.recordWrapper();
            record.recordId = l.Id;
            record.processingType = 'segment';
            records.add(record);
        }
        
        Test.startTest();
        BIEnrichmentProcessor.getRecords(records);
        Test.stopTest();
    }
    
    @isTest
    static void testAccountBIErrorSync(){
        List<account> accList = [Select id,Website,Country__c,Legal_Business_Name__c,Charm_Revenue__c,
                                 StoreLeads_Annual_Revenue__c,BI_Enrichment_Sync_Status__c,
                                 Segmentation_Sync_Ready__c,Customer_Group__c from Account];
        accList[0].BI_Enrichment_Sync_Status__c = 'Failed - segment';
        accList[1].Segmentation_Sync_Ready__c = true;
        update accList;
        
        Test.startTest();
        BIEnrichmentErrorRecoveryScheduler biEnrichSch = new BIEnrichmentErrorRecoveryScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test BI Enrich Error Recovery Scheduler', sch, biEnrichSch);
        Test.stopTest();
    }
    
    @isTest
    static void testLeadBIErrorSync(){
        List<lead> leadList = [Select id,LastName,Website,Country_Location__c,Company,Charm_Revenue__c,
                               StoreLeads_Annual_Revenue__c,BI_Enrichment_Sync_Status__c,
                               Segmentation_Sync_Ready__c,Customer_Group__c from lead];
        leadList[0].BI_Enrichment_Sync_Status__c = 'Failed - segment';
        leadList[1].Segmentation_Sync_Ready__c = true;
        update leadList;
        
        Test.startTest();
        BIEnrichmentErrorRecoveryScheduler biEnrichSch = new BIEnrichmentErrorRecoveryScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test BI Enrich Error Recovery Scheduler', sch, biEnrichSch);
        Test.stopTest();
    }
}
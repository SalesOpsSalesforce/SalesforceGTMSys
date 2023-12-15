@isTest
private class KPUAggregatedEcommPlatformBatchTest {
  @isTest
    private static void testKPUAggregatedEcommPlatformUpdateBatch(){
        //Create Klaviyo Product Usage records
        List<Klaviyo_Product_Usage__c> testKPUs = new List<Klaviyo_Product_Usage__c>();
        for(Integer i=0;i<50;i++) {
            testKPUs.add(new Klaviyo_Product_Usage__c(Klaviyo_Account_ID__c = 'TestKPU'+i, 
                                                      bi_Aggregated_Ecommerce_Platform__c = 'Shopify'));
        }
        insert testKPUs;
        
        //Create Account records
        List<Account> testAccounts = new List<Account>();
        for(integer i =0; i<50; i++){
            testAccounts.add(new Account(Name = 'Test'+ i, Klaviyo_Product_Usage__c = testKPUs[i].id));
        }
        
        insert testAccounts;
        
        Test.startTest();
        KPUAggregatedEcommPlatformUpdateBatch aggEcommBatch = new KPUAggregatedEcommPlatformUpdateBatch();
        Database.executeBatch(aggEcommBatch, 50);
        Test.stopTest();
        Account testAcc = [Select id,KPU_Aggregated_Ecommerce_Platform__c from Account where Name = 'Test0'];
        system.assertEquals('Shopify', testAcc.KPU_Aggregated_Ecommerce_Platform__c);
    }

}
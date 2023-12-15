/* Class:      KlaviyoProductUsageTriggerHandlerTest
 * Created On: 1/11/2022
 * Created by: Reeta Gaokar
 * Description: Unit tests for the KlaviyoProductUsageTriggerHandler class
 */

//[RGaokar 1/11/2022 TP #95103 Test Class for KlaviyoProductUsageTriggerHandler class]
@isTest
private class KlaviyoProductUsageTriggerHandlerTest {
    @testSetup 
    private static void setup() {   
        //Create Klaviyo Product Usage records
        List<Klaviyo_Product_Usage__c> testKPUs = new List<Klaviyo_Product_Usage__c>();
        for(Integer i=0;i<300;i++) {
            testKPUs.add(new Klaviyo_Product_Usage__c(Klaviyo_Account_ID__c = 'TestKPU'+i));
        }
        insert testKPUs;
    }
    
    //[1/27/2022 RGaokar TP #96506 This method is moved to KPU before save flow]
    //Test method is not commented to verify the same functionality in flow.
    @isTest
    private static void testmarkAsUpdated(){
        List<Klaviyo_Product_Usage__c> kpuList = [SELECT Id FROM Klaviyo_Product_Usage__c];
        for(Klaviyo_Product_Usage__c kpu:kpuList){
            kpu.PRODUCT_Ecommerce_Integration__c = 'shopify';
            kpu.PRODUCT_Is_Sending_Campaigns__c = true;
            kpu.PRODUCT_Is_Sending_Flows__c = true;
            kpu.PRODUCT_Shopify_Plan__c = 'basic';
            kpu.PRODUCT_Stripe_Net_MRR__c = 100;
            kpu.PRODUCT_of_Emailable_Profiles__c = 3000;
            kpu.MARKETING_utm_Campaign_Last__c = 'test';
            kpu.MARKETING_Referrer_Last__c = 'www.test.com';
            kpu.MARKETING_utm_Source_Last__c = 'test.com';
            kpu.MARKETING_utm_Term_Last__c = 'test'; 
        }
        
        Test.startTest();
        update kpuList;
        
        Klaviyo_Product_Usage__c kpu = [SELECT Id, Updated_by_Heroku__c FROM Klaviyo_Product_Usage__c where Klaviyo_Account_ID__c = 'TestKPU0' limit 1];
        system.assertEquals(true, kpu.Updated_By_Heroku__c);
        Test.stopTest();
    }
    

}
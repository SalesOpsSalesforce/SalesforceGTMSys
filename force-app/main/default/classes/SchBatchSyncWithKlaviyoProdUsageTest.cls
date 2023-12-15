/**
 * Name: SchBatchSyncWithKlaviyoProdUsageTest
 * Created on: Jun 2020
 * Created by: J. Pipkin (OpFocus, Inc)
 * Description:
 */

@isTest
public class SchBatchSyncWithKlaviyoProdUsageTest {

    @testSetup static void buildData() {
        //[RGaokar 1/11/2022 TP #95103 KPU Test data to increase code coverage]
        List<Klaviyo_Product_Usage__c> testKPUs = new List<Klaviyo_Product_Usage__c>();
        for(Integer i=0;i<4;i++) {
            testKPUs.add(new Klaviyo_Product_Usage__c(Klaviyo_Account_ID__c = 'TestKPU'+i));
        }
        insert testKPUs;
        
        // To set Updated_By_Heroku__c = true
        for(Klaviyo_Product_Usage__c kpu:testKPUs){
            kpu.PRODUCT_Ecommerce_Integration__c = 'shopify';
            kpu.PRODUCT_Stripe_Net_MRR__c = 100;
            kpu.PRODUCT_of_Emailable_Profiles__c = 3000;
        }
        update testKPUs;
        
        Lead l1 = new Lead(FirstName='Suzie', LastName='Queue', Company='TestCo 1', Klaviyo_Account_ID__c = testKPUs[0].Klaviyo_Account_ID__c);
        insert new List <Lead> {l1};

        // If the TriggerDisablementSwitch has this disabled, enable it for this unit tests so
        // we can cover that code.
        TriggerDisablementSwitchHelper.mapSwitches.put('Klaviyo_Product_Usage_Creation_Triggers'.toLowerCase(), false);

        Account a1 = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = testKPUs[1].Klaviyo_Account_ID__c);
        Account a2 = new Account(Name='Test Account 2', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Product_Klaviyo_Account_ID__c = testKPUs[2].Klaviyo_Account_ID__c);
        Account a3 = new Account(Name='Test Account 3', SUPPORT_Account_Manager__c=UserInfo.getUserId(), Experts_Tier__c='Silver', Product_Klaviyo_Account_ID__c = testKPUs[3].Klaviyo_Account_ID__c);
        insert new List <Account> {a1, a2, a3};
    }

    //test methods
    //[RGaokar 1/11/2022 TP #95103 Revised existing test methods to improve code coverage]
    static testMethod void testsetup() {
        Test.startTest();
        SchBatchSyncWithKlaviyoProdUsage.setup();
        Test.stopTest();
    }
    
    //To verify the updates performed by batch apex
    static testMethod void testmanual() {
        Test.startTest();
        SchBatchSyncWithKlaviyoProdUsage.manual();
        Test.stopTest();
        Klaviyo_Product_Usage__c kpu = [SELECT Id, Updated_by_Heroku__c FROM Klaviyo_Product_Usage__c where Klaviyo_Account_ID__c = 'TestKPU0' limit 1];
        Account acc = [Select id, PRODUCT_Ecommerce_Integration__c,PRODUCT_Num_Emailable_Profiles__c,PRODUCT_Stripe_Net_MRR__c from Account limit 1];
        Lead l = [Select id, PRODUCT_Ecommerce_Integration__c, PRODUCT_of_Emailable_Profiles__c from Lead limit 1];
        
        system.assertEquals(false, kpu.Updated_By_Heroku__c);
        system.assertEquals('shopify', acc.PRODUCT_Ecommerce_Integration__c);
        system.assertEquals(100, acc.PRODUCT_Stripe_Net_MRR__c);
        system.assertEquals(3000, acc.PRODUCT_Num_Emailable_Profiles__c);
        system.assertEquals('shopify', l.PRODUCT_Ecommerce_Integration__c);
        system.assertEquals(3000, l.PRODUCT_of_Emailable_Profiles__c);  
    }

}
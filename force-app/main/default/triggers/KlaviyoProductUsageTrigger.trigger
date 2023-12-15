/**
 * Name: KlaviyoProductUsageTrigger
 * Created on: May 2020
 * Created by: J. Pipkin (OpFocus, Inc)
 * Description:
 */
trigger KlaviyoProductUsageTrigger on Klaviyo_Product_Usage__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    new KlaviyoProductUsageTriggerHandler().run();
}
/* *********
*  Date:            10/2023
*  Description:     SFDC 3539 LeanData
Ben Holloran
* *********/
trigger PartnerApplication on Partner_Application__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
new PartnerApplicationTriggerHandler().run();

}
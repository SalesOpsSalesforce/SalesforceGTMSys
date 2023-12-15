/* Class:       TestData
 * Created On:  April 2020
 * Created by:  MJ Kahn (OpFocus, Inc)
 * Description: Contains helper methods for unit tests
 */

// [07/13/2022 SFDC -131] Commenting out the class based on TP #89100
// [10/04/2021 TP #89100] Class created with Opfocus to help test with the old partner platform called Magentrix which is now replaced with Allbound. This class is no longer needed. 

@isTest
public class TestData {
/*
    public static Account buildAccount(String name) {
        Account acct = new Account();
        acct.Name = name;
        return acct;
    }*/

//Uncommenting below method as its used in LeadTriggerHandlerTest [RGaokar 08/10/2022 SFDC-608 Apex job holding - Shutting down batch jobs from trigger]
    public static Lead buildLead(String name, String company, String email) {
        Lead ld = new Lead();
        ld.FirstName = name;
        ld.LastName = name;
        ld.Company = company;
        //ld.MARKETING_Initial_Lead_Source_Detail__c = 'Paid - Adwords';
        //ld.MARKETING_Initial_Lead_Source__c = 'Paid';
        ld.RP_Partner_Lead_Registration_Status__c = 'Accept';
        ld.SALES_Disqualification_Reason__c = '';
        ld.SALES_of_Contacts__c = 1000;
        ld.FLOW_BDR_Stated_Num_of_Contacts__c = 1000;
        //ld.SALES_Bad_Alexa__c = false;
        return ld;
    }

}
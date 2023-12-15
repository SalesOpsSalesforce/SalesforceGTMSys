/* *********
*  Date:        06/16/2022
*  Description: Methods for testing Contract__c triggers/ContractsTriggerHandler
*  Developer:   RGaokar
* *********/
@isTest
public class ContractsTriggerHandlerTest {
    @testSetup
    private static void dataSetup(){
        //Create accounts
        List<Account> accList = new List<Account>();
        Map <String,Schema.RecordTypeInfo> accRecordTypeMap = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        //Customer Accounts
        for(Integer i=0;i<2;i++) {
            accList.add(new Account(Name = 'Test Account'+i, recordTypeId = accRecordTypeMap.get('Klaviyo Account').getRecordTypeId(),
                                    Product_Klaviyo_Account_ID__c  = 'abc'+i, Website = 'https://www.google.com'));
        }
        insert accList;
        
        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i=0;i<2;i++) {
        	oppList.add(new Opportunity (Name='Test Opportunity '+i, AccountId=accList[i].Id, StageName='Closed Won', CloseDate=Date.today(), 
                                     Amount=100.0, Opportunity_Product__c = 'Email Subscription'));
        }
        insert oppList;
        
        //Create Contracts
        Map <String,Schema.RecordTypeInfo> contractsRecordTypeMap = Contract__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        List<Contract__c> contractList = new List<Contract__c>();
        for(integer i =0; i<2; i++){
            contractList.add(new Contract__c(Name = 'Test '+i,recordTypeId = contractsRecordTypeMap.get('Service Order').getRecordTypeId(),
                                             Account__c = accList[i].Id, Opportunity__c  = oppList[i].Id, 
                                             Payment_Method__c  = 'Manually Billed', Contract__c = 'Accept'));
        }
        insert contractList;
    }
    
    @isTest
    private static void testRequiredBillingApprovalDate(){
        List<Contract__c> contractList = [Select id, Contract__c, Billing_Approval_Date__c from Contract__c];
        for (Contract__c cntr:contractList){
            cntr.Contract__c = 'Completed';
        }
        Test.startTest();
        try{
            update contractList;
        }catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().containsIgnoreCase('Please enter the Billing Approval Date before approving the contract!') ? true : false;
            system.assertEquals(true, expectedExceptionThrown);
        }
        
        for (Contract__c cntr:contractList){
            cntr.Billing_Approval_Date__c = System.today();
        }
        update contractList;
        List<Contract__c> approvedContractList = [Select id, Contract__c from Contract__c where Contract__c = 'Completed'];
        system.assertEquals(2, approvedContractList.size());
        Test.stopTest();
    }

}
@isTest
public class TransactionSyncBatchTest {
    @isTest
    private static void testTransactionSync(){
        //Create customer accounts
        List<account> customerAccList = new List<account>();
        customerAccList.add(new Account(Name = 'Test Account - Transaction Update', Product_Klaviyo_Account_ID__c = 'KAI123'));
        customerAccList.add(new Account(Name = 'Test Account - Transaction Insert', Product_Klaviyo_Account_ID__c = 'KAI456'));
        insert customerAccList;
        
        //Create Opportunities
        List<opportunity> oppList = new List<opportunity>();
        oppList.add(new Opportunity(Name = 'Transaction Update', Accountid = customerAccList[0].id, Closedate = date.today().addDays(30), StageName = 'S1: Evaluation', Amount = 100, 
                                    Opportunity_Product__c = 'Email Subscription', PRODUCT_Klaviyo_Transaction_Id__c = '111'));
        insert oppList;
        
        //Create Transactions
        List<Transaction__c>trList = new List<Transaction__c>();
        //Transaction to update opportunity
        trList.add(new Transaction__c(Transaction_Id__c = '111',Opportunity_Name__c = 'testTransaction1//Email',Account__c = customerAccList[0].id,
                                      Amount__c = 200,Plan_Limit__c = 200,Product__c = 'Email Subscription',Transaction_Date__c = date.today(),
        							  Customer_Cancellation_Reason__c = 'Cancel Email 1' ,Cancellation_Sub_Reason__c = 'Cancel Email 1',
                                      Cancelled_Notes__c = 'Email Cancle',Cancellation_Zendesk_Ticket_URL__c = 'www.cancle1.com'));
        
       //Transaction to insert opportunity
        trList.add(new Transaction__c(Transaction_Id__c = '222',Opportunity_Name__c = 'testTransaction2//Email',Account__c = customerAccList[1].id,
                                      Amount__c = 200,Plan_Limit__c = 200,Product__c = 'Email Subscription',Transaction_Date__c = date.today(),
        							  Customer_Cancellation_Reason__c = 'Cancel Email 2' ,Cancellation_Sub_Reason__c = 'Cancel Email 2',
                                      Cancelled_Notes__c = 'Email Cancle',Cancellation_Zendesk_Ticket_URL__c = 'www.cancle2.com')); 
        
        //Transaction with sync failure due to missing AccountId
        trList.add(new Transaction__c(Transaction_Id__c = '333',Account__c = customerAccList[1].id,
                                      Amount__c = 200,Plan_Limit__c = 200,Product__c = 'Email Subscription',Transaction_Date__c = date.today(),
        							  Customer_Cancellation_Reason__c = 'Cancel Email 3' ,Cancellation_Sub_Reason__c = 'Cancel Email 3',
                                      Cancelled_Notes__c = 'Email Cancle',Cancellation_Zendesk_Ticket_URL__c = 'www.cancle3.com'));
        
        
		insert trList;
        
        Test.StartTest();
        TransactionSyncScheduler testsch = new TransactionSyncScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Transaction Sync Scheduler', sch, testsch);
        Test.stopTest(); 
    }

}
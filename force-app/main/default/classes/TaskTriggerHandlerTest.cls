@isTest
private class TaskTriggerHandlerTest
{

    @testSetup static void buildData()
    {

        Lead l1 = new Lead(FirstName='Suzie', LastName='Queue', Company='TestCo 1');
        Lead l2 = new Lead(FirstName='Jackie', LastName='Jack', Company='TestCo 2');
        Lead l3 = new Lead(FirstName='Phan', LastName='Nguyen', Company='TestCo 3');
        Lead l4 = new Lead(FirstName='King', LastName='Kong', Company='TestCo 4');
        Lead l5 = new Lead(FirstName='Mr', LastName='Sinister', Company='TestCo 5', 
                            FLOW_Date_Time_of_Response__c=Datetime.now().addDays(5),
                            FLOW_DateTimeof_Last_Reach_out_Activity__c=Datetime.now().addDays(-5),
                            FLOW_DateTimeof_First_Reach_out_Activity__c=Datetime.now().addDays(5)
                            );
        insert new List <Lead> {l1, l2, l3, l4, l5};

        Account a1 = new Account(Name='Test Account 1', SUPPORT_Account_Manager__c=UserInfo.getUserId());
        insert new List <Account> {a1};

        Opportunity o1 = new Opportunity(Name='Test Opp 1', AccountId=a1.Id, StageName='Closed/Won', CloseDate=Date.today());
        insert new List <Opportunity> {o1};
    }

    @isTest
    private static void testTaskHandler()
    {

        List <Lead> lstLeads = [select Id from Lead order by Company];
        List <Account> lstAccounts = [select Id from Account];
        List <Opportunity> lstOpps = [select Id from Opportunity];

        RecordType rt = [select Id from RecordType where SobjectType='Task' and DeveloperName='LinkedIn_Call' limit 1];
        
        test.startTest();

        Task t1 = new Task(WhoId=lstLeads[0].Id);
        t1.Status = 'Completed';
        t1.Type = 'Email';
        t1.Subject = 'Message Sent: ';
        t1.RecordTypeId = rt.Id;
        t1.Priority = 'Normal';
        t1.ActivityDate = Date.newInstance(2021,09,08);
        insert new List <Task> {t1};

        t1 = [select Id, FM_Is_Communication_Activity__c from Task where Id=:t1.Id limit 1];
        System.assertEquals(true, t1.FM_Is_Communication_Activity__c);

        Task t2 = new Task(WhoId=lstLeads[1].Id, Status='Completed', Type='Email',              Subject='Reply: ', RecordTypeId=rt.Id, Priority='Normal');
        Task t3 = new Task(WhoId=lstLeads[2].Id, Status='Completed', Type='Connected',          Subject='Reply: ', RecordTypeId=rt.Id, Priority='Normal');
        Task t4 = new Task(WhoId=lstLeads[2].Id, Status='Completed', Type='Demo',               Subject='Reply: ', RecordTypeId=rt.Id, Priority='Normal');
        Task t5 = new Task(WhoId=lstLeads[2].Id, Status='Completed', Type='Pre-Scheduled Call', Subject='Reply: ', RecordTypeId=rt.Id, Priority='Normal');
        Task t6 = new Task(WhoId=lstLeads[3].Id, Status='Completed', Type='Attempted',          Subject='Reply: ', RecordTypeId=rt.Id, Priority='Normal');
        Task t7 = new Task(WhoId=lstLeads[3].Id, Status='Completed', Type='Left Message',       Subject='Reply: ', RecordTypeId=rt.Id, Priority='Normal');
        Task t8 = new Task(WhoId=lstLeads[4].Id, Status='Completed', Type='Attempted',          Subject='Reply: ', RecordTypeId=rt.Id, Priority='Normal');
        Task t9 = new Task(WhatId = lstAccounts[0].Id, Status='Completed', Type='Attempted',    Subject='Reply: ', RecordTypeId=rt.Id, Priority='Normal', ActivityDate = Date.newInstance(2021,09,08));
        insert new List <Task> {t2, t3, t4, t5, t6, t7, t8, t9};
        
        t9.ActivityDate = Date.newInstance(2021,09,09);
        update t9;

        test.stopTest();


    }
}
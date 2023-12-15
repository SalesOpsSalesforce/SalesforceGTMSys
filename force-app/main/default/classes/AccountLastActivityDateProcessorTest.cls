//[RGaokar 04/05/2023 SFDC-2217 Flow error during more than 12 tasks, as tasks are updating same account multiple time in same Transaction.]
@isTest
public class AccountLastActivityDateProcessorTest {
    
    @isTest
    public static void testAccountLastActivity(){
        Account a = new Account(Name = 'Test Account');
    	insert a;
        Contact c = new Contact(LastName = 'Test Contact', accountId = a.Id);
        insert c;
        
        List<Task>taskList = new List<Task>();
        Task t1 = new Task(WhoId = c.id, Subject = 'Other', Type = 'Email', Status = 'Completed', ActivityDate = Date.newInstance(2023, 2, 17));
        Task t2 = new Task(WhoId = c.id, Subject = 'Other', Type = 'Email', Status = 'Completed', ActivityDate = Date.newInstance(2023, 3, 20));
        taskList.add(t1);
        taskList.add(t2);
        Test.startTest();
        insert taskList;
        
        //For first time run during deployment
        List<AccountLastActivityDateProcessor.TaskInformation> tskInfo = new List<AccountLastActivityDateProcessor.TaskInformation>();
        AccountLastActivityDateProcessor.TaskInformation tInfo1 = new AccountLastActivityDateProcessor.TaskInformation();
        tInfo1.accountId = a.Id;
        tInfo1.LastActivityDate = Date.newInstance(2023, 2, 17);
        tInfo1.Role_of_User_with_Last_Activity = 'SMB AE';
        tskInfo.add(tInfo1);
        AccountLastActivityDateProcessor.TaskInformation tInfo2 = new AccountLastActivityDateProcessor.TaskInformation();
        tInfo2.accountId = a.Id;
        tInfo2.LastActivityDate = Date.newInstance(2023, 3, 20);
        tInfo2.Role_of_User_with_Last_Activity = 'SMB AE';
        tskInfo.add(tInfo2);
        AccountLastActivityDateProcessor.processLastActivityDate(tskInfo);
        
        Account queriedAcc = [Select id,Last_Activity_Date_Custom__c from account where id = :a.Id limit 1];
        system.assertEquals(Date.newInstance(2023, 3, 20), queriedAcc.Last_Activity_Date_Custom__c);
        Test.stopTest();
    }
}
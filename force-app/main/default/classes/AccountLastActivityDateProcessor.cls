//[RGaokar 04/05/2023 SFDC-2217 Flow error during more than 12 tasks, as tasks are updating same account multiple time in same Transaction.]
//[This is the fix for the error where apex logic will check latest activity date for each account & send each account for update only once].
//[RGaokar 10/02/2023 SFDC-3755 Blank owner role bug - Make Role_of_User_with_Last_Activity invocable variable non-required]
public class AccountLastActivityDateProcessor {
    
    @invocableMethod(label = 'Process Last Activity Date for Account')
    public static void processLastActivityDate(List<TaskInformation> tasks){
        map<id,TaskWrapper>accountLastActivityDateMap = new map<id,TaskWrapper>();
        for(TaskInformation task:tasks){
            if(!accountLastActivityDateMap.containskey(task.accountId)){
                TaskWrapper tsk = new TaskWrapper(task.LastActivityDate, task.Role_of_User_with_Last_Activity);
                accountLastActivityDateMap.put(task.accountId, tsk);
            }else if(accountLastActivityDateMap.containskey(task.accountId) 
                     && accountLastActivityDateMap.get(task.accountId).LastActivityDate < task.LastActivityDate){
                         TaskWrapper tsk = new TaskWrapper(task.LastActivityDate, task.Role_of_User_with_Last_Activity);
                         accountLastActivityDateMap.put(task.accountId, tsk);
                     }
        }
        
        List<account>updateAccList = new List<account>();
        for(id accId:accountLastActivityDateMap.keyset()){
            Account a = new account (id = accId);
            a.Last_Activity_Date_Custom__c = accountLastActivityDateMap.get(accId).LastActivityDate;
            a.Role_of_User_with_Last_Activity__c = accountLastActivityDateMap.get(accId).Role_of_User_with_Last_Activity;
            updateAccList.add(a);
        }
        
        if(!updateAccList.isEmpty()){
            String errorString = '';
            List<Database.SaveResult> srList = Database.update(updateAccList, false);
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    errorString += '\n'+'Record Id: ' +result.getId();
                    for(Database.Error err :result.getErrors()){
                        errorString += ' Error Message: ' +err.getMessage()+'\n';
                    }
                }
            }
            //system.debug('Errors--'+errorString);
        } 
    }
    
    public class TaskInformation{
        @InvocableVariable(required = true)
        public string accountId;
        
        @InvocableVariable(required = true)
        public Date LastActivityDate;
        
        @InvocableVariable
        public string Role_of_User_with_Last_Activity;
    }
    
    public class TaskWrapper{
        public Date LastActivityDate{get;set;}
        public string Role_of_User_with_Last_Activity{get;set;}
        
        public TaskWrapper(Date LastActivityDate,string Role_of_User_with_Last_Activity){
            this.LastActivityDate = LastActivityDate;
            this.Role_of_User_with_Last_Activity = Role_of_User_with_Last_Activity;
        }
    }
    
}
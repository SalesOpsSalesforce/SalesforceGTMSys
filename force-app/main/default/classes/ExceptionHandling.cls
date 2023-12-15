public class ExceptionHandling{

    public static void performExceptionHandling(Exception e, String s, List <String> executionFlow){
    
             ExceptionLog__c eLog = new ExceptionLog__c();
             eLog.Exception_Source__c = ''+s;
             if(e != null){ //[RGaokar 12/15/2021]to handle Database.Error records. For database operation the e is set to null
                eLog.Exception_Message__c = e.getMessage();
                eLog.Exception_Cause__c = ''+e.getCause();
                eLog.Exception_Line_Number__c = e.getLineNumber();
                eLog.Exception_Type__c = e.getTypeName();
                eLog.Exception_Stack_Trace__c = e.getStackTraceString();
             }
             eLog.Execution_Flow__c = string.valueOf(executionFlow);
       
             insert eLog;
             
             Messaging.SingleEmailMessage Exmail=new Messaging.SingleEmailMessage();
             List<String> toAddresses = System.Label.ExceptionHandlingEmailList.split(',');
             Exmail.setToAddresses(toAddresses);
             Exmail.setSenderDisplayName('Apex error message (from Exception Handling)');
             Exmail.setSubject('Apex Error from Org : ' + UserInfo.getOrganizationName());
             if(e != null){ //[RGaokar 12/15/2021]to handle Database.Error records. For database operation the e is set to null
                Exmail.setPlainTextBody(e.getMessage());
             } else{
                 Exmail.setPlainTextBody(string.valueOf(executionFlow));
             }
             
             // [vrajapatruni TP #126294 06/12/2022] Governor limits hit issue - commenting the email
             // [vrajapatruni TP #126294 06/13/2022] Enabled the emails again
             //[RGaokar SFDC-2233 04/05/2023 Adding if condition to bypass sending email for test class]
             if(!Test.isRunningTest())Messaging.sendEmail(new Messaging.SingleEmailMessage[] { Exmail });  
    }


}
@isTest
private class AlexaRankRefreshControllerTest
{
    
   @isTest 
   static void testMethod1(){ 
         
         Account testAccount = new Account();
         testAccount.Name='Test Account record' ;
         testAccount.Website='http://www.essenceofemail.com';
         insert testAccount;
        
         Test.StartTest(); 
         
         ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
         AlexaRankRefreshController obj = new AlexaRankRefreshController(sc);
        
         try{    
             Long alexaRank = obj.getAlexaRank(testAccount.Website);
         }
         catch(Exception e){}    
         
         obj.updateAlexaRank();   
        
        Test.StopTest();
    }

}
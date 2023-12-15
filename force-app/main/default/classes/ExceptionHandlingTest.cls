@isTest
private class ExceptionHandlingTest
{

    @isTest
    private static void testExceptionHandling(){
        
        List <String> executionFlow = new List <String> ();
        try{
        
            Lead l = new Lead(FirstName = 'Test', LastName = 'Test Last name', Company = 'Test Company');
            insert l;
            Integer i = 1/0;
            executionFlow.add('Test execution flow');
        
        }
        
        catch(exception e){
            ExceptionHandling.performExceptionHandling(e, 'Test exception', executionFlow);
        }
           
    }

}
//[RGaokar 07/31/2023 SFDC-3243 Test class for InvocableExceptionError]
@isTest
public class InvocableExceptionErrorTest {
    @istest
    public static void testCustomException(){
        try{
            InvocableExceptionError.createCustomException(new String[]{'This is a custom exception'});
        }catch (Exception e){
            system.assertEquals('This is a custom exception', e.getMessage());   
        }
    }
}
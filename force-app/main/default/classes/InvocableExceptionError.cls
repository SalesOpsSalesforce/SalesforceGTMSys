//[RGaokar 07/31/2023 SFDC-3243 This is the helper class to create custom exception]
//Pass error message from flow to this InvocableMethod to throw custom exception with that message.
public class InvocableExceptionError {
    @InvocableMethod(label='Create Custom Exception')
    public static void createCustomException(List<String> errorMessages){
        if(!errorMessages.isEmpty()){
            throw new InvocableCustomException(errorMessages[0]);
        } 
    }
    
    public class InvocableCustomException extends Exception{}
}
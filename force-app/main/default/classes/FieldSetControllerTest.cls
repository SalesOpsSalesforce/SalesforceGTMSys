//[vrajapatruni 02/16/2023 SFDC-1742/1880] Test Class for FieldSetController - OpportunityMPOFieldSet - Add/Update products wizard
@isTest
private class FieldSetControllerTest{
    
    @isTest
    static void testGetFieldSet(){
        //Setup test parameters
        String objectName = 'OpportunityLineItem';
        String fieldSetName = 'OpportunityMPOFieldSet';
        
        //Call the method and check the result
        List<FieldSetController.FieldSetWrapper> result = FieldSetController.getFieldSet(objectName, fieldSetName);
        
        //Assert values for verification
        System.assertEquals('Product2Id', result[0].fieldApiName, 'Unexpected field API name');
        
        // Verifying Error Handling by passing an object that doesn't exists
        objectName = 'Test';
        
        // Call the method and check the result
        test.startTest();
        try{
            FieldSetController.getFieldSet(objectName, fieldSetName);
        } catch(Exception ex){
            System.assertEquals(ex.getMessage().contains('Script-thrown exception'), true);
        }
        test.stopTest();
    }
    
}
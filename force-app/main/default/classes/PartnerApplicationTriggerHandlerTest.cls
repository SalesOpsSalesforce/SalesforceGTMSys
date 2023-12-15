@isTest
public class PartnerApplicationTriggerHandlerTest {
@isTest
    private static void testLeanDataRouting()
    {
        Partner_Application__c PA = new Partner_Application__c(Name='Test Partner App 1', Country__c='Canada');
     insert PA; 
        
        PA.Country__c = 'United States';
        update PA;
   }
}
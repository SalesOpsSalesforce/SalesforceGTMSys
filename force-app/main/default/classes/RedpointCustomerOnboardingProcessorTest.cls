//[RGaokar 02/16/2023 SFDC-1359 Salesforce -> Redpoint Customer Onboarding request processor test]
@isTest
public class RedpointCustomerOnboardingProcessorTest {
    @isTest
    static void testRedpointSync(){
        Account a = new Account(Name = 'Test Account', Industry = 'Automotive');
        insert a;
        Contact c = new Contact(LastName = 'TestContact', AccountId = a.Id, Email = 'test@test.com');
        insert c;
        Opportunity o = new Opportunity (Name = 'Test Opportunity', AccountId = a.Id, Amount = 100, Closedate = system.today(), StageName = 'S1: Evaluation', Opportunity_Product__c = 'Email Subscription');
        insert o;
        Customer_Onboarding__c co = new Customer_Onboarding__c (Name = 'CO Test', Account__c = a.id, Opportunity__c = o.id, Main_User__c = c.id, Economic_Buyer__c = c.id, Status__c = 'Onboarding Accepted');
        insert co;
        //Update Customer onboarding for Redpoint sync
        co.Status__c = 'Onboarding Completed';
        co.Onboarding_Completed_Start_Date_Time__c = system.now();
        update co;
        
        //For first time deployment
        List<RedpointCustomerOnboardingProcessor.CustomerOnboardingEventPayload>payloadList = new List<RedpointCustomerOnboardingProcessor.CustomerOnboardingEventPayload>();
        RedpointCustomerOnboardingProcessor.CustomerOnboardingEventPayload payload = new RedpointCustomerOnboardingProcessor.CustomerOnboardingEventPayload();
        payload.customerOnboardingId = co.id;
        payload.OnboardingStatus = 'Onboarding Completed';
        payload.CompletedOnboardingDate = system.now();
        payload.PrimaryKlaviyoUserEmail = 'test@test.com';
        payload.onboardingName = 'Test Name';
        payload.KlaviyoAccountId = 'testkid';
        payload.onboardingCompletedDate = system.today();
        payload.onboardingSegment = 'Growth';
        payload.onboardingProducts = 'Email, SMS';
        payload.assignedOnboardingRep = 'Test';
        /* payload.
        payload.
        payload.
        payload. */
        payloadList.add(payload);
        RedpointCustomerOnboardingProcessor.getRedpointCustomerOnboardingPayload(payloadList);
    }
    
}
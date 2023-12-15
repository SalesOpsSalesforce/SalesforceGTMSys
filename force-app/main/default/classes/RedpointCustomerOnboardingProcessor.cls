//[RGaokar 02/16/2023 SFDC-1359 Salesforce -> Redpoint Customer Onboarding request processor]
//Considering queueable approach as number of customer onboarding completed / canceled records in a day are max 10. So 100 callout governor limit cannot be hit.
public class RedpointCustomerOnboardingProcessor implements System.Queueable, Database.AllowsCallouts{
    private List<CustomerOnboardingEventPayload>payloadList = new List<CustomerOnboardingEventPayload>();
    //Constructor
    public RedpointCustomerOnboardingProcessor(List<CustomerOnboardingEventPayload>payloadList){
        this.payloadList = payloadList;
    }
    
    
    @invocableMethod(label='Redpoint Customer Onboaring Payload Processor')
    public static void getRedpointCustomerOnboardingPayload(List<CustomerOnboardingEventPayload>payloadList){
        system.enqueueJob(new RedpointCustomerOnboardingProcessor(payloadList));   
    }
    
    //-----Queueable methods
    public void execute(system.QueueableContext ctx){
        RedpointCustomerOnboardingCallout.processRedpointPayload(payloadList);
    }
    
    //Payload Variables 
    public class CustomerOnboardingEventPayload{
        
        @InvocableVariable(required=true)
        public ID customerOnboardingId;
        
        @InvocableVariable
        public String PrimaryKlaviyoUserEmail;
        
        @InvocableVariable
        public String DecisionMakerEmail;
        
        @InvocableVariable
        public datetime CompletedOnboardingDate;
        
        @InvocableVariable
        public datetime CancelledOnboardingDate;
        
        @InvocableVariable(required=true)
        public string OnboardingStatus;
        
        //[VR 11/30/2023 SFDC-3606] Add Klaviyo Account ID & OBS
        @InvocableVariable
        public String OnboardingName;
        
        @InvocableVariable
        public String KlaviyoAccountId;
        
        @InvocableVariable
        public Date OnboardingCompletedDate;
        
        @InvocableVariable
        public String OnboardingSegment;
        
        @InvocableVariable
        public String OnboardingProducts;
        
        @InvocableVariable
        public String AssignedOnboardingRep;
    }
    
}
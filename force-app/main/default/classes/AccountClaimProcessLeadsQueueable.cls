public class AccountClaimProcessLeadsQueueable implements System.Queueable {
    List<Lead> listOfLeads = new List<Lead>();
    public List<Id> AccountIds;
    
    public AccountClaimProcessLeadsQueueable(List<Id> AccountIds, List<Lead> listOfLeads){
        this.listOfLeads = listOfLeads;
        this.AccountIds = AccountIds;
    }
    
    public void execute(QueueableContext context) {
        for (Lead l : listOfLeads) {
            
            // [update vr 02/22/2021]
            if(l.SALES_Disqualification_Reason__c != 'Said No - Do Not Contact'){
                l.LeadSource = 'Outbound';
                l.MARKETING_Most_Recent_Lead_Source_Detail__c = 'Self-Prospected';
                l.SALES_Disqualification_Reason__c = Null;
            }
            
            // [update vr 03/11/2021]
            // When someone does an account claim, if one of the related leads has HasOptedOutOfEmail = True, do not put the Lead in the rep's name. 
            // Instead check SALES_Ecommerce_Platform__c - if it contains "Shopify" put the Lead in Core Placeholder's name. 
            // Otherwise, put it in Special Ops Placeholder's name.
            if(l.HasOptedOutOfEmail <> True){
                
                l.OwnerId = l.Account__r.OwnerId;
                l.SALES_Ecommerce_Platform__c = l.Account__r.Ecommerce_Platform__c;
                
                // [01/11/2023 vrajapatuni SFDC #1514] Move Inbound leads to Inbound placeholder
                if(l.Account__r.OwnerId == System.Label.Core_Placeholder_Id){
                    if((l.MARKETING_Initial_Lead_Source__c == 'Inbound' || l.MARKETING_Initial_Lead_Source__c == 'Paid' || l.MARKETING_Initial_Lead_Source__c == 'App Store' || l.MARKETING_Initial_Lead_Source__c == 'Miscellaneous') && 
                       AccountIds.contains(l.Account__c)  &&
                       (l.Owner.Userrole.Name <> null && !l.Owner.Userrole.Name.contains('iBDR')) &&
                       (l.Referral_Partner_Account__c == null && l.Tech_Partner_Account__c == null && l.MAGENTRIX_Platform_Partner_Account__c == null && l.Investment_Firm__c == null))
                    {
                        l.OwnerId = System.Label.Inbound_Placeholder_User_Id;
                    }
                }
                
            }
            
            Else if(l.HasOptedOutOfEmail == True){
                if((l.SALES_Ecommerce_Platform__c <> Null && l.SALES_Ecommerce_Platform__c.contains('Shopify')) || (l.Account__r.Ecommerce_Platform__c <> Null && l.Account__r.Ecommerce_Platform__c.contains('Shopify'))){
                    // [12/08/2021 VRajapatuni TP #97703] Update with custom label for Core Placeholder
                    l.OwnerId = System.Label.Core_Placeholder_Id;
                }
                else{
                    // [12/08/2021 VRajapatuni TP #97703] Update with custom label for Special Ops Placeholder
                    l.OwnerId = System.Label.Special_Ops_Placeholder_Id;
                }
            }
        }
        List <String> executionFlow = new List <String> ();
        try{
            update listOfLeads;
        }catch(Exception e){
            ExceptionHandling.performExceptionHandling(e, 'AccountClaimProcessLeadsBatch', executionFlow);
        } 
    }
}
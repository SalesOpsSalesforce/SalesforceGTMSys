global class MRRAttributedtoAgencyBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
    
        String query = 'select Id, RP_Referral_Partner_Account__c, SALES_PayoutAmounttoReferralPartner__c, Type__c, CloseDate, Amount, FM_Days_From_New_Account_Close__c, Opportunity_Product__c, IsClosed, IsWon from Opportunity where IsWon = TRUE and RP_Referral_Partner_Account__c <> null and SALES_PayoutAmounttoReferralPartner__c <> null and SALES_PayoutAmounttoReferralPartner__c <> \'No - Not Part of the Program\' order by CloseDate DESC';
             
        return Database.getQueryLocator(query);    
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> OppList){
        
        Set <Id> setRefAccountIds = new Set <Id> ();
        
        for (Opportunity o : OppList) {
            
            if (o.IsClosed && o.IsWon && o.RP_Referral_Partner_Account__c != null && ((String.isNotEmpty(o.SALES_PayoutAmounttoReferralPartner__c) && o.SALES_PayoutAmounttoReferralPartner__c != 'No - Not Part of the Program'))){

                if (o.RP_Referral_Partner_Account__c != null) {
                    setRefAccountIds.add(o.RP_Referral_Partner_Account__c);
                }
            }
        }
                
        List <Opportunity> lstMatchingOpps = 
            [select Id, RP_Referral_Partner_Account__c, Type__c, CloseDate, Amount, FM_Days_From_New_Account_Close__c, Opportunity_Product__c, AccountID, Name 
             from Opportunity 
             where 
                IsWon = TRUE
                and RP_Referral_Partner_Account__c in :setRefAccountIds
                and SALES_PayoutAmounttoReferralPartner__c <> null
                and SALES_PayoutAmounttoReferralPartner__c <> 'No - Not Part of the Program'
             order by CloseDate DESC
            ];
        
        Map <Id, Account> mapAccountIdAccount = new Map <Id, Account> ();
        for (Id i : setRefAccountIds) {
            Account a = new Account(Id=i);
            
            a.FL_Current_Attributed_Agency_MRR__c = 0.0;
            a.FLOW_Current_Attributed_Paying_Customers__c = 0;
            a.FLOW_All_Paid_Klaviyo_Customer_Referred__c = 0;
            a.FLOW_Date_of_Most_Recent_RP_Customer__c = null;

            mapAccountIdAccount.put(i, a);
        }
        
        Set <String> setTypesPlus = new Set <String> {'Land: New Account', 'Land: Account Reactivation'};
        
        for (Opportunity o : lstMatchingOpps) {
            Account a = mapAccountIdAccount.get(o.RP_Referral_Partner_Account__c);
            System.debug(LoggingLevel.INFO, '=========>>>> opportunity: '+o+', account: ' +a);

            if (o.Amount != null) {
                a.FL_Current_Attributed_Agency_MRR__c += o.Amount;
            }


            if (setTypesPlus.contains(o.Type__c)) {
                a.FLOW_Current_Attributed_Paying_Customers__c += 1;
                a.FLOW_All_Paid_Klaviyo_Customer_Referred__c += 1;

                if (a.FLOW_Date_of_Most_Recent_RP_Customer__c == null) {
                    a.FLOW_Date_of_Most_Recent_RP_Customer__c = o.CloseDate;
                }
            }
            else if (String.isNotBlank(o.Type__c) && o.Type__c.equals('Cancellation')) {
                a.FLOW_Current_Attributed_Paying_Customers__c += -1;
            }
            
            // [vrajapatruni 02/07/2023 SFDC-1581] Moved the logic for FLOW_MRRAttributedtoAgencyinLastYear__c and SMS_MRR_Attributed_to_Agency_Last_Year__c to PartnerAccountTotalMRRBatch
            
        }

        System.debug(LoggingLevel.INFO, '=========>>>> updating accounts: '+mapAccountIdAccount.values());
        if (mapAccountIdAccount.values().size() > 0) {
            update mapAccountIdAccount.values();
        }      
        
    }    
    
    global void finish(Database.BatchableContext bc){
        
    }  
      
}
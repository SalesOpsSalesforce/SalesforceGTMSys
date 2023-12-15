public class AccountClaimProcessLeads{

      @InvocableMethod(label='AccountClaimProcessLeads' description='Update leads' category='Lead')  
     
      public static void UpdateAccountCliamProcessLeads(List<ID> ids) {
      
      List<Lead> leadList = [SELECT id, isConverted, Account__r.OwnerId, Account__r.Ecommerce_Platform__c, OwnerId, SALES_Ecommerce_Platform__c, Status, SALES_Disqualification_Reason__c, HasOptedOutOfEmail, Owner.Userrole.Name, MARKETING_Initial_Lead_Source__c, MARKETING_Most_Recent_Lead_Source_Detail__c, LeadSource, Referral_Partner_Account__c, Tech_Partner_Account__c, MAGENTRIX_Platform_Partner_Account__c, Investment_Firm__c, Account__c FROM Lead WHERE Account__c in :ids AND isConverted = false];
          
          if(!leadList.isEmpty() && leadList.size() > 50){    
              // [VRajapatruni 12/08/2021 TP #97703]  Updated the batch size from 1 to 20
              // [VRajapatruni 12/21/2021 TP #95109]  Updated the batch size from 20 to 100
              Database.executeBatch(new AccountClaimProcessLeadsBatch(ids), 100);
          }else if(!leadList.isEmpty()){
              System.enqueueJob(new AccountClaimProcessLeadsQueueable(ids, leadList));
          }    

    }
    
}
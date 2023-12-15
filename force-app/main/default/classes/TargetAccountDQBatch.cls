/* [vrajapatruni 07/01/2021] This is a batch class to update account, leads and contacts when an account is marked as DQ - Do not Contact */

public class TargetAccountDQBatch implements Database.Batchable<sObject> {

    public Set<Id> leadIds;
    public Set<Id> acctIds;
    
    public TargetAccountDQBatch(Set<Id> leadIds, Set<Id> acctIds){
    
        this.leadIds = leadIds;
        this.acctIds = acctIds;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
    
        return Database.getQueryLocator('Select Id, Account__c, OwnerId,  isConverted from Lead where Id in: leadIds');
    
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> leadList){
        
        // [vrajapatruni TP #115513 06/15/2022 Update] This code is for moving an account (TAS = DQ - Do not contact) to core placeholder and setting the assocaited contacts email opt out to true
        
        List <Account> accountList = [Select id, OwnerId from Account where id in: acctIds]; 
        List <Contact> contactList = [Select id, OwnerId from Contact where AccountID in: acctIds]; 
        
        for (Account a : accountList){
            a.OwnerId = system.label.Core_Placeholder_Id;
        }
        
        update accountList;
        
        for (Contact c : contactList){
            c.HasOptedOutOfEmail = true;
        }
        
        update contactList;
        
        for(Lead l : leadList){  
    
            if(acctIds.contains(l.Account__c) && l.isConverted == false){
                 
                l.Status = 'Disqualified';
                l.SALES_Disqualification_Reason__c = 'Said No - Do Not Contact';
                l.DQ_d_Reason_Detail__c = 'Target Account Disqualified - Do Not Contact';
                l.HasOptedOutOfEmail = true; // Sales Opt out
                // [vrajapatruni TP #115513 06/15/2022] This code is for moving a lead (associated to DNC Account) to core placeholder and setting the marketing opt out to true
                l.Marketing_Opt_Out__c = true; // Marketing opt out
                l.OwnerId = system.label.Core_Placeholder_Id;
                
            }

        }
    
        update leadList;
        
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
}
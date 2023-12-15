// This class finds any duplicate accounts based on clean_website__c and merges them based on pre-defined rules
// Test Class: AccountDeduplicationBatchTest
// To manually execute from dc - Database.executeBatch(new AccountDeduplicationBatch(),10);
// This class can also be scheduled using AccountDeduplicationBatchScheduler class

global class AccountDeduplicationBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Retreive all accounts with clean website. Clean website is a formula field (Group by / count(id) > 1 not applicable)
        String allAccounts = 'SELECT Clean_Website__c FROM Account where  RecordType.Name = \'Klaviyo Account\' and Clean_Website__c != null and Clean_Website__c != \'-\' and Clean_Website__c != \'.\' and SystemModStamp >= LAST_N_DAYS:2';  // and  Master_Account_Id__c != null
        return Database.getQueryLocator(allAccounts); 
           
    }
    
    global void execute(Database.BatchableContext bc, List<Account> acctRecList){
    
        Set<Id> matchingIds = new Set<Id>();
        Map<Id, Boolean> specialAcct = new Map<Id, Boolean>();
        Map<String, Id> urlMatchingAcct = new Map<String, Id>();
        Set<String> websitesSet = new Set<String>();
        Map<String, List<Account>> acctWebsiteMap = new Map<String, List<Account>>();
        
        
        // Retrieve all the clean websites into a set
        for(Account a: acctRecList){
            websitesSet.add(a.Clean_Website__c);            
        }
        
        // Retrieve all the accounts associated with the clean websites       
        List<Account> acctsList = [SELECT Id, Name, Product_Klaviyo_Account_ID__c, ParentId, FINANCE_Payment_Method__c, RecordTypeId FROM Account where Clean_Website__c in: websitesSet order by CreatedDate DESC];
        Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Clean_Website__c, MRRCalc__c, RecordTypeId, Owner.isActive, Owner.Profile.Name, Owner.Name from Account where Id in: acctsList]);
        
        // Retrieve all the Account Contact Relationships in order to avoid same contact merge between duplicate and master accounts
        Map<String, List<AccountContactRelation>> acctRelContMap = new Map<String, List<AccountContactRelation>>();
        List<AccountContactRelation> accContRelList = [Select AccountId, ContactId, isDirect from AccountContactRelation where AccountId in: acctsList];
        
        for(AccountContactRelation aRel : accContRelList) {
        
            if(acctRelContMap.get(aRel.AccountId) != null){
                
                List<AccountContactRelation> recs = acctRelContMap.get(aRel.AccountId);
                recs.add(aRel);
                acctRelContMap.put(aRel.AccountId, recs);
                
            }
            else{
            
                List<AccountContactRelation> recs = new List<AccountContactRelation>();
                recs.add(aRel);
                acctRelContMap.put(aRel.AccountId, recs);
            
            }
        
        }
        
        for(Account acct: acctsList){ 
            
            // Checking for Customer Account Ids
            // Conditions: ( Record Type = Klaviyo Account ) AND ( MRR > $0 OR Klaviyo Payment Method != Stripe )
            if(acct.Id <> null && (acctMap.get(acct.Id).RecordTypeId == System.label.Klaviyo_Account_Record_Id) && (acctMap.get(acct.Id).MRRCalc__c > 0 || acct.FINANCE_Payment_Method__c != 'Stripe')){
                
                specialAcct.put(acct.Id, true);
                System.debug('Account is special Customer ' +acct.Id);
            }
            
            // Checking for Has Klaviyo Account ID
            // Conditions: ( Record Type = Klaviyo Account ) AND ( Klaviyo Account ID is not null )
            if(acct.Id <> null && acctMap.get(acct.Id).RecordTypeId == System.label.Klaviyo_Account_Record_Id && acct.Product_Klaviyo_Account_ID__c != null){
                
                specialAcct.put(acct.Id, true);
                System.debug('Account is special Has Klaviyo Account ID ' +acct.Id);
            }
            
            // Checking for Child of Parent Account Structure
            // Conditions: ( Record Type = Klaviyo Account ) AND ( Parent is not null ) 
            if(acct.Id <> null && acctMap.get(acct.Id).RecordTypeId == System.label.Klaviyo_Account_Record_Id && acct.ParentId != null){
                
                specialAcct.put(acct.Id, true);
                System.debug('Account is special Child of Parent ' +acct.Id);
            }
            
            // Checking for Sales-Owned Account
            // Conditions: ( Account Owner is Active ) AND ( Account Owner’s Profile is AE Sales User, BDR Sales User, CAM, OR Sales Management User ) 
            //                AND ( Account Owner Name is not Core Placeholder OR Special Ops Placeholder )
            if( acct.Id <> null && acctMap.get(acct.Id).Owner.isActive 
                && (acctMap.get(acct.Id).Owner.Profile.Name == 'AE Sales User' || acctMap.get(acct.Id).Owner.Profile.Name == 'BDR Sales User' || acctMap.get(acct.Id).Owner.Profile.Name == 'CAM' || acctMap.get(acct.Id).Owner.Profile.Name == 'Sales Management User') 
                && !(acctMap.get(acct.Id).Owner.Name == 'Core Placeholder' || acctMap.get(acct.Id).Owner.Name == 'Special Ops Placeholder')){
                
                specialAcct.put(acct.Id, true);
                System.debug('Account is special Sales-Owned ' +acct.Id);
            }
        }
        
        for(Account acct: acctsList){        
            
            if(acctWebsiteMap.keySet().contains(acctMap.get(acct.Id).Clean_Website__c)){
                List<Account> acctsData = acctWebsiteMap.get(acctMap.get(acct.Id).Clean_Website__c);
                acctsData.add(acct);
                acctWebsiteMap.put(acctMap.get(acct.Id).Clean_Website__c, acctsData);
            }
            else{
                acctWebsiteMap.put(acctMap.get(acct.Id).Clean_Website__c, new List<Account>{acct});
            }
        }
        
        // Merging rules
        // If 2 Accounts have Clean Websites that are an exact:
        // If both accounts are “Special Accounts” (defined above), do not merge them
        // If one of the accounts is a “Special Account” and the other is not a “Special Account”, merge them and keep all attributes from the “Special Account”
        // If neither Account is a “Special Account”, merge them and keep all attributes from the most recently created Account
        for(String s: acctWebsiteMap.keySet()){
            
            // Proceed only when this clean website have an account (additional to the one thats created above and added to list) 
            if(acctWebsiteMap.get(s) != null && acctWebsiteMap.get(s).size() > 1 ){
                
                Account masterAcct;
                List<Account> mergeAccts = new List<Account>();
                Boolean haveInAcctSpecial = false;
                
                // Proccessing all the accounts for a specific website
                for(Account acct: acctWebsiteMap.get(s)){
                    
                    // Set isAcctSpecial to true if the list specialAcct contains a special account with the current clean website
                    boolean isAcctSpecial = specialAcct.keySet().contains(acct.Id);
                    
                    // If the masterAcct is not already set and the current account is a special account, assign the current account to masterAcct
                    if(isAcctSpecial && masterAcct == null){
                        masterAcct = acct;                        
                    }
                    else if(isAcctSpecial == false && mergeAccts.size() < 2 && acct.RecordTypeId == System.label.Klaviyo_Account_Record_Id){                         
                        mergeAccts.add(acct);
                    }
                    
                    // Set haveInAcctSpecial when atleast one of the accounts is not special (shouldn't merge when two accounts are special)
                    if(isAcctSpecial == false){
                        haveInAcctSpecial = true;
                    }
                    
                    // Break if the number of mergeAccts are greater than 2 (Database.merge limitation)
                    if(masterAcct != null && mergeAccts.size() >= 2){
                        break;
                    }
                                        
                } 
                
                if(haveInAcctSpecial == true && mergeAccts.size() > 0){
                    
                    List<Contact> directContactList = new List<Contact>();
                    // When master account is present, merge the duplicates to master
                    if(masterAcct != null){
                    
                        List<AccountContactRelation> relDelList = new List<AccountContactRelation>();
                        
                        // Verify if master has a related contact
                        if(acctRelContMap.get(masterAcct.Id) != null) {
                        
                            for(AccountContactRelation rel1: acctRelContMap.get(masterAcct.Id)){
                                for(Integer i=0; i < mergeAccts.size(); i++){
                                    if(mergeAccts[i].id <> null && acctRelContMap.get(mergeAccts[i].Id) != null){
                                        for(AccountContactRelation rel2: acctRelContMap.get(mergeAccts[i].Id)){
                                            
                                            if(rel1.ContactId == rel2.ContactId){
                                                if(rel2.isdirect) {
                                                    Contact cont = new Contact(Id = rel2.ContactId, AccountId = masterAcct.Id);
                                                    directContactList.add(cont);
                                                }
                                                
                                                relDelList.add(rel2);
                                            }
                                            
                                        }
                                    }
                                }
                            } 
                        }
                        
                        if(directContactList <> null && directContactList.size() > 0){
                            // comment the below for mapping master account Id instead of database merging
                            Database.update(directContactList, false); 
                        }
                            
                        if(relDelList <> null && relDelList.size() > 0){
                            // comment the below for mapping master account Id instead of database merging
                            Database.Delete(relDelList, false);
                        }
                        
                        // comment the below for mapping master account Id instead of database merging
                        Database.merge(masterAcct, mergeAccts, true);
                        
                        // uncomment the below for mapping master account Id instead of database merging
                        // for(Account a : mergeAccts){ a.Master_Account_Id__c = masterAcct.Id;}

                    }    
                    // When both the accounts are not special, then merge the older account to the latest
                    else if(mergeAccts.size() > 1){ 
                        
                        List<AccountContactRelation> relDelList = new List<AccountContactRelation>();
                                                
                        if(acctRelContMap.get(mergeAccts[0].Id) != null ) {
                            if(acctRelContMap.get(mergeAccts[1].Id) != null ){
                                for(AccountContactRelation rel1: acctRelContMap.get(mergeAccts[0].Id)){
                                    for(AccountContactRelation rel2: acctRelContMap.get(mergeAccts[1].Id)){
                                        
                                        if(rel1.ContactId == rel2.ContactId){
                                            if(rel2.isdirect) {
                                                Contact cont = new Contact(Id = rel2.ContactId, AccountId = mergeAccts[0].Id);
                                                directContactList.add(cont);
                                            }
                                                
                                            relDelList.add(rel2);
                                        }
                                        
                                    }
                                } 
                             }       
                        }
                        
                        if(directContactList <> null && directContactList.size() > 0){
                            // comment the below for mapping master account Id instead of database merging
                            Database.update(directContactList, false); 
                        }
                        
                        if(relDelList <> null && relDelList.size() > 0){
                            // comment the below for mapping master account Id instead of database merging
                            Database.Delete(relDelList, false); 
                        } 
                        
                        // comment the below for mapping master account Id instead of database merging
                        Database.merge(mergeAccts[0], mergeAccts[1], true);
                        
                        // uncomment the below for mapping master account Id instead of database merging
                        // mergeAccts[1].Master_Account_Id__c = mergeAccts[0].Id;
                        
                    } 
                    
                    // uncomment the below for mapping master account Id instead of database merging
                    // update mergeAccts; 
                              
                } 
            }
        }
        
    }    
    
    global void finish(Database.BatchableContext bc){
        
    }    
}
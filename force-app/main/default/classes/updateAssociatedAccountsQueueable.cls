// [VRajapatruni 06/27/2023 SFDC-3017] Converting Batch jobs to dual mode - Batch and Queueable based on list size
public class updateAssociatedAccountsQueueable implements System.Queueable {
    public Set<Id> UserIds;
    public list<account> accountHierarchyList{get;private set;}
    set<Id> topParentIds = new set<Id>();
    Map<String,Set<Id>> topParentIdsMap = new Map<String, Set<Id>>();
    List<Account> topParentIdsListMaster = new List<Account>();
    List<Account> ChildAccountsListMaster = new List<Account>();    
    List<User> userList = new List<User>();
    public updateAssociatedAccountsQueueable(Set<Id> UserIds, List<User> listOfUsers){
        this.UserIds = UserIds;
        this.userList = listOfUsers;
    }
    
    public void execute(QueueableContext context) {
        //userList = [Select Id, Associated_Accounts__c, Name from User where Id in: UserIds AND isActive = true AND LastName != 'System' AND FirstName != 'Automated' AND (NOT Name  LIKE '%Site Guest%') AND (NOT Name LIKE '%Platform Integration User%') AND (NOT Name  LIKE '%Catherine Catherine Curran%') AND (NOT Name  LIKE '%Placeholder%') AND (NOT Name  LIKE '%Salesforce API%') AND (NOT Name  LIKE '%Klaviyo Partners%') ];
        System.debug('User Ids picked for processing AA: '+userList);
        Integer totalCount = 0;
        Map<String,Integer> userIdCountMap = new Map<String, Integer>();
        
        //[APickett 02/21/2023 SFDC-1610] removed AND RU_of_Open_Opportunities__c = 0 from query
        AggregateResult[] groupedResults = [SELECT OwnerId, count(Id) cnt FROM Account 
                                            where OwnerId in: userList AND RecordType.Name = 'Klaviyo Account' 
                                            AND MRRCalc__c = 0 AND FINANCE_Payment_Method__c = 'Stripe' 
                                            AND ParentId = Null GROUP BY OwnerId];
        for (AggregateResult ar : groupedResults){
            userIdCountMap.put(''+ar.get('OwnerId'), Integer.valueOf(ar.get('cnt')));
        }
        
        System.debug('Count of accounts parentId Null and meet conditions ' +userIdCountMap);  
        
        //[APickett 02/21/2023 SFDC-1610] removed AND RU_of_Open_Opportunities__c = 0 from query        
        List<Account> allPAccts = [Select Ultimate_Parent__c, OwnerId from Account 
                                   where OwnerId in: userList 
                                   AND 
                                   (( RecordType.Name = 'Parent Account' AND MRRCalc__c = 0 AND FINANCE_Payment_Method__c = 'Stripe' AND ParentId = Null)
                                    OR (MRRCalc__c = 0 AND FINANCE_Payment_Method__c = 'Stripe' AND ParentId != Null))];
        
        Set<Id> acctIdsParentSet = new Set<Id>();
        Set<String> acctIdsParentSet15char = new Set<String>();
        
        for(Account a : allPAccts){
            if(topParentIdsMap.get(a.OwnerId) != null){
                Set<Id> topParIds = topParentIdsMap.get(a.OwnerId);
                topParIds.add(a.Ultimate_Parent__c);
                topParentIdsMap.put(a.OwnerId, topParIds);
            }
            else{
                Set<Id> topParIds = new Set<Id>();
                topParIds.add(a.Ultimate_Parent__c);
                topParentIdsMap.put(a.OwnerId, topParIds);
            }
            acctIdsParentSet.add(a.Ultimate_Parent__c);
        }
        
        topParentIdsListMaster = [Select Id, OwnerId from Account where OwnerId in: userList AND ID in: acctIdsParentSet];
        System.debug('topParentIdsListMaster ' +topParentIdsListMaster);
        
        for(Id i: acctIdsParentSet){
            acctIdsParentSet15char.add(String.valueOf(i).substring(0, 15));
        }
        
        //[APickett 02/21/2023 SFDC-1610] removed RU_of_Open_Opportunities__c field from query
        ChildAccountsListMaster = [select name, Id, MRRCalc__c, FINANCE_Payment_Method__c, Ultimate_Parent__c, (select id from ChildAccounts) from account where Ultimate_Parent__c in: acctIdsParentSet15char];
        
        for(user u: userList){
            Integer calcParentNullCount = 0;
            if(userIdCountMap.get(u.Id) != null){
                calcParentNullCount = userIdCountMap.get(u.Id);
            }
            u.Associated_Accounts__c = calcAA(u.Id) + calcParentNullCount;
        }
        update userList;
    }
    
    // Count the number of associated accounts based on top level parents
    public Integer calcAA(Id userId){
        Integer hierarchyMeetsCount = 0;
        // [VRajapatruni 09/12/2023 SFDC-3617] Null pointer fix
        topParentIds = new Set<Id>();
        if(topParentIdsMap.containskey(userId)){
            topParentIds = topParentIdsMap.get(userId);
        }
        
        List<Account> topParentIdsList = new List<Account>();
        Set<Id> topParentIdsListOwned = new Set<Id>();
        
        for(Account a : topParentIdsListMaster){
            if(a.OwnerId == userId && !topParentIds.isEmpty() && topParentIds.contains(a.Id)){
                topParentIdsList.add(a);
            }        
        }
        
        for(Account acct : topParentIdsList) {
            topParentIdsListOwned.add(acct.Id);
        }
        
        for(Id topParentAccountId: topParentIdsListOwned){
            
            System.debug('Calling Child Accounts List ');
            getChildAccountsInHierarchy(topParentAccountId);
            System.debug('Top Level Parent and its all Child Accounts ' +accountHierarchyList); 
            Boolean hasDisQAcct = false;
            // Account Hierarchy list also contains its own parent account
            if(accountHierarchyList.size() > 1){
                for(Account acct : accountHierarchyList){
                    //[APickett 02/21/2023 SFDC-1610] removed AND RU_of_Open_Opportunities__c = 0 criteria
                    if(acct.MRRCalc__c != 0 || acct.FINANCE_Payment_Method__c != 'Stripe'){
                        hasDisQAcct = true;
                        System.debug(' hasDisQAcct true for account ' +acct.Id);
                    }
                    else{
                        System.debug(' hasDisQAcct false for account ' +acct.Id);
                    }
                }
                if(hasDisQAcct == false){
                    System.debug('This hierachy is eligible ' +topParentAccountId);
                    hierarchyMeetsCount = hierarchyMeetsCount + 1;
                }
                else{
                    System.debug('This hierachy is not eligible ' +topParentAccountId);
                }
            }
        }
        
        System.debug('final count is ' +hierarchyMeetsCount );
        // if(!topParentIds.isEmpty())
        //    topParentIds.clear();
        return hierarchyMeetsCount;
    }
    
    //builds list of the child accounts  
    Private List<Account> getChildAccountsInHierarchy(Id parentAcctId) {
        
        System.debug('Inside Child Account List Method');
        accountHierarchyList = new List<account>();
        List<Account> ChildAccountsList = new List<Account>();
        for(Account a : ChildAccountsListMaster){
            if((String)Id.valueOf(a.Ultimate_Parent__c) == parentAcctId){
                System.debug('Inside If');
                ChildAccountsList.add(a);
            }
        }
        
        // add all the child accounts to accountHierarchy
        for(Account a: ChildAccountsList){
            accountHierarchyList.add(a);
        }
        
        System.debug('accountHierarchyList' +accountHierarchyList);
        return accountHierarchyList;
    }
}
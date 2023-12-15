//[RGaokar 05/25/2022 TP #119587] Controller for Paying Parent Hierarchy LWC component
public with sharing class PayingParentHierarchyController {
    private static Account topPayingParent = new Account();
    private static Map <Id, HierarchyWrapper> hrWrapperMap = new Map <Id, HierarchyWrapper>();
    @AuraEnabled(cacheable = true)
    public static string getPayingParentHierarchy(Id currentAccId){
        Set<id> parentAccIds = new Set<id>();
        getTopPayingParent(currentAccId);
        hrWrapperMap.put(topPayingParent.id,new HierarchyWrapper(topPayingParent));
        parentAccIds.add(topPayingParent.id);
        getBilledUnderParentChild(parentAccIds);
        HierarchyWrapperAura payingParentHierarchyAura = setPayingParentHierarchyAura();
        return JSON.serialize(new List<HierarchyWrapperAura>{payingParentHierarchyAura});
    }
    
    //Get Top Paying Parent Account Node
    private static void getTopPayingParent(Id accId){
        Account acc = [Select id, name, Product_Klaviyo_Account_ID__c, Paying_Parent__c from account where id =:accId limit 1];
        if(acc.Paying_Parent__c != null){
            getTopPayingParent(acc.Paying_Parent__c);
        }else{
            topPayingParent = acc;
        }
    }
    
    //Get all childern of Top Paying Parent Account Node
    private static void getBilledUnderParentChild(Set<Id> parentAccIds){
        Map<Id, Account> childAccMap = new Map <Id, Account>([Select id, name, Product_Klaviyo_Account_ID__c, Paying_Parent__c from account where Paying_Parent__c in :parentAccIds]);
        if(!childAccMap.isEmpty()){
            for(Id childAccId:childAccMap.keyset()){
                HierarchyWrapper childNode = new HierarchyWrapper(childAccMap.get(childAccId));
                hrWrapperMap.put(childAccId,childNode);
                hrWrapperMap.get(childAccMap.get(childAccId).Paying_Parent__c).children.add(childNode);//add as child of respective paying parent 
            }
            getBilledUnderParentChild(childAccMap.keyset());//Get all childern for next parent levels node (which is below top parent node)
        }  
    }
        
    //Set paying parent hierarchy for LWC tree
    private static HierarchyWrapperAura setPayingParentHierarchyAura(){
        HierarchyWrapperAura topPayingParentHierarchyAura = new HierarchyWrapperAura(topPayingParent);
        HierarchyWrapper topPayingParentHierarchy = hrWrapperMap.get(topPayingParent.id);
        topPayingParentHierarchyAura.items = setChildHierarchyAura(topPayingParentHierarchy.children);
        return topPayingParentHierarchyAura;
    }
    
    //Set top paying parent's childern hierarchy for LWC tree
    private static List <HierarchyWrapperAura> setChildHierarchyAura(List<HierarchyWrapper> childHierarchy){
         List <HierarchyWrapperAura> childWrapAura = new List <HierarchyWrapperAura>();
         for(HierarchyWrapper childNode:childHierarchy){
             HierarchyWrapperAura nodeAura = new HierarchyWrapperAura(childNode.nodeAccount);
             nodeAura.items = setChildHierarchyAura(hrWrapperMap.get(childNode.nodeAccount.id).children);
             childWrapAura.add(nodeAura);
         }
         
         if(!childWrapAura.isEmpty()){
             return childWrapAura;
         }else{
             return null;
         }  
    }
    
    //Wrapper class to store node account and its childern
    public class HierarchyWrapper {
        public Account nodeAccount {get;set;}
        public List<HierarchyWrapper> children{get;set;} 
        
        public HierarchyWrapper(Account acc){
            this.nodeAccount = acc;
            this.children = new List<HierarchyWrapper>();
        }
    }
    
    //Wrapper class to structure paying parent hierarchy for LWC tree 
    public class HierarchyWrapperAura {
        public String label {get;set;}
        public String name {get;set;}
        public Boolean expanded {get;set;}
        public string href{get;set;}
        public List<HierarchyWrapperAura> items{get;set;} 
        
        public HierarchyWrapperAura(Account acc){
            this.label = acc.Product_Klaviyo_Account_ID__c != null?acc.Name +', '+acc.Product_Klaviyo_Account_ID__c:acc.Name;
            this.name = acc.id;
            this.expanded = true;
            this.href = URL.getSalesforceBaseUrl().toExternalForm() + '/' + acc.id;
            this.items = new List<HierarchyWrapperAura>();
        }
    }
}
//[RGaokar 07/11/2023 SFDC-2836 Move Previous New Business Territory Accounts with Open Opportunities 
//and the related Open Opportunities after promotion period to previous manager]
//This batch updates account ownership 
public class PromotedAEAccountOwnerUpdateBatch implements Database.Batchable<sObject>,Database.Stateful{
    map<id, Sales_Ops_Request__c>salesRepIdRequestMap = new map<id, Sales_Ops_Request__c>();
    map<id, List<account>>repIdAccountsMap = new map<id, List<account>>();
    map<id, id>repIdPreviousManagerIdMap = new map<id, id>();
    map<id, opportunity>updateOppMap = new map<id, opportunity>();
    
    public PromotedAEAccountOwnerUpdateBatch(map<id, Sales_Ops_Request__c>salesRepIdRequestMap){
        this.salesRepIdRequestMap = salesRepIdRequestMap;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        set<Id>repIds = new set<Id>();
        repIds.addAll(salesRepIdRequestMap.keyset());
        string query = 'Select id,name,ownerid,New_Business_Territory__c,'; 
        query += ' (Select id, ownerid, stagename from opportunities where ownerid in :repIds AND StageName != \'Closed Won\' AND StageName != \'Closed Lost\')';
        query += ' from account where ownerid in :repIds';
        query += ' AND (New_Business_Territory__c like \'%L SMB%\' OR New_Business_Territory__c like \'%U SMB%\')';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){        
        List<account>updateAccList = new List<account>();    
        
        for(Account a:(List<account>)scope){
            string repNewRole = salesRepIdRequestMap.get(a.ownerid).Role_Change_to__c.containsIgnoreCase('U SMB AE') ? 'U SMB' : 'MM';
            
            //If promototed sales rep owned account has open opportunities then move accounts in previous role New Business Territory to previous manager & also move related open opportunities 
            if(!a.opportunities.isEmpty() && salesRepIdRequestMap.containsKey(a.ownerid)
               && (repNewRole == 'U SMB' && a.New_Business_Territory__c.containsIgnoreCase('L SMB')
                   || repNewRole == 'MM' && a.New_Business_Territory__c.containsIgnoreCase('U SMB'))){
                       Id previousManagerId = salesRepIdRequestMap.get(a.ownerid).Previous_Manager__c;
                       updateAccList.add(new account(id = a.Id, ownerid = previousManagerId));
                       
                       //Change owner of related opportunities owned by promoted sales rep
                       for(opportunity o:a.opportunities){
                           if (o.OwnerId == a.ownerId)
                               updateOppMap.put(o.id,new opportunity(id = o.id, ownerid = previousManagerId));
                       }
                       
                       //For Email Notification sending new & old owner information for related accounts
                       if(!repIdAccountsMap.containsKey(a.ownerid)){
                           repIdAccountsMap.put(a.ownerid, new List<Account>());
                       }
                       repIdAccountsMap.get(a.ownerid).add(a);
                       
                       repIdPreviousManagerIdMap.put(a.ownerid, previousManagerId);
                   }  
        }
        
        //Update Accounts for ownership
        if(!updateAccList.isEmpty()){
            string errorString = '';
            List<Database.SaveResult> srList = Database.update(updateAccList, false);
            
            for(Database.SaveResult sr:srList){
                if(!sr.isSuccess()){
                    for(Database.Error err :sr.getErrors()){
                        errorString += 'Account Id: ' + sr.getId() + ' Error Message: ' + err.getMessage()+'\n';
                    }   
                }
            }
            
            //Error Handling
            if(string.isNotEmpty(errorString) || Test.isRunningTest()){
                List<string>errorList = new List<string>();
                errorList.add('The following error occured for Promoted AE Account ownership change: '+'\n');
                errorList.add(errorString);
            	ExceptionHandling.performExceptionHandling(null, 'PromotedAEAccountOwnerUpdateBatch', errorList); 
            } 
        } 
    }
    
    public void finish(Database.BatchableContext bc){
        //Send opportunity owner update to another batch to avoid CPU timeout errors.
        PromotedAEOpportunityOwnerUpdateBatch oppOwnerUpdateBatch = new PromotedAEOpportunityOwnerUpdateBatch(repIdAccountsMap,repIdPreviousManagerIdMap,updateOppMap);
        Database.executeBatch(oppOwnerUpdateBatch, 50);//Update 50 Opportunities at a time
    } 
}
//[RGaokar 07/28/2023 SFDC-3216 Move Previous New Business Territory Accounts WITHOUT Open Opportunities 
//to previous manager on role change effective date]
//Keeping this seperate from PromotedAEAccountOwnerUpdateBatch without using helper method as PromotedAEAccountOwnerUpdateBatch was already implemented
public class PromotedAERoleChangeTodayOwnerUpdate implements Database.Batchable<sObject>,Database.Stateful{
    map<id, Sales_Ops_Request__c>salesRepIdRequestMap = new map<id, Sales_Ops_Request__c>();
    map<id, List<account>>repIdAccountsMap = new map<id, List<account>>();
    map<id, id>repIdPreviousManagerIdMap = new map<id, id>();
    
    public PromotedAERoleChangeTodayOwnerUpdate(map<id, Sales_Ops_Request__c>salesRepIdRequestMap){
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
            
            //Move promototed sales rep owned accounts in previous New Business Territory to previous manager
            if(a.opportunities.isEmpty() && salesRepIdRequestMap.containsKey(a.ownerid)
               && (repNewRole == 'U SMB' && a.New_Business_Territory__c.containsIgnoreCase('L SMB')
                   || repNewRole == 'MM' && a.New_Business_Territory__c.containsIgnoreCase('U SMB'))){
                       Id previousManagerId = salesRepIdRequestMap.get(a.ownerid).Previous_Manager__c;
                       updateAccList.add(new account(id = a.Id, ownerid = previousManagerId));
                       
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
                errorList.add('The following error occured for Promoted AE Accounts w/o opportunity ownership change: '+'\n');
                errorList.add(errorString);
                ExceptionHandling.performExceptionHandling(null, 'PromotedAERoleChangeTodayOwnerUpdate', errorList); 
            } 
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        //Send Emails to new & previous account owner
        //Get user name & email id
        set<id>userIds = new set<id>();
        userIds.addAll(repIdPreviousManagerIdMap.keyset());//Promoted Sales Rep
        userIds.addAll(repIdPreviousManagerIdMap.values());//Previous Manager
        Map<id, user> userMap = new Map<id, user>([Select id,name,email from user where id in :userIds]);
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(id repId:repIdAccountsMap.keyset()){
            Id previousManagerId = repIdPreviousManagerIdMap.get(repId);
            Messaging.SingleEmailMessage sEmail = new Messaging.SingleEmailMessage();
            List<string>toAddresses = new List<string>();
            toAddresses.add(userMap.get(repId).email);
            toAddresses.add(userMap.get(previousManagerId).email);
            sEmail.setToAddresses(toAddresses);
            sEmail.setSubject('Account Ownership Change Notification');
            string msg = 'Hello!' + '\n'+ '\n' + 'This is the notification for account ownership change from '+ userMap.get(repId).name + ' to ' + userMap.get(previousManagerId).name + '\n'+ '\n';
            msg += 'The following prior segment accounts owned by '+ userMap.get(repId).name +' are transferred to '+ userMap.get(previousManagerId).name + '\n';
            for(Account a:repIdAccountsMap.get(repId)){
                msg += a.name + ': klaviyo.lightning.force.com/lightning/r/Account/' + a.id + '/view'+ '\n';
            }
            msg += '\n'+ 'Thanks'+'\n'+'Sales Ops Team';
            sEmail.setPlainTextBody(msg);
            emailList.add(sEmail);
        }
        
        if(!emailList.isEmpty() && !Test.isRunningTest()){
            Messaging.sendEmail(emailList, false);
        }
    }
}
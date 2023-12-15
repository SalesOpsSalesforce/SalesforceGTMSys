//[RGaokar 07/11/2023 SFDC-2836 Move Previous New Business Territory Accounts with Open Opportunities 
//and the related Open Opportunities after promotion period to previous manager]
//This batch updates opportunty ownership & sends email to new & previous owner
public class PromotedAEOpportunityOwnerUpdateBatch implements Database.Batchable<sObject>{
    map<id, List<account>>repIdAccountsMap = new map<id, List<account>>();
    map<id, id>repIdPreviousManagerIdMap = new map<id, id>();
    map<id, opportunity>updateOppMap = new map<id, opportunity>();
    public PromotedAEOpportunityOwnerUpdateBatch(map<id, List<account>>repIdAccountsMap,map<id, id>repIdPreviousManagerIdMap, map<id, opportunity>updateOppMap){
        this.repIdAccountsMap = repIdAccountsMap;
        this.repIdPreviousManagerIdMap = repIdPreviousManagerIdMap;
        this.updateOppMap = updateOppMap;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        set<id>oppIds = new set<id>();
        oppIds.addAll(updateOppMap.keyset());
        String query = 'Select id, ownerid from opportunity where id in :oppIds';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        List<opportunity> updateOppList = new List<opportunity>();
        for(Opportunity o:(List<opportunity>)scope){
            updateOppList.add(updateOppMap.get(o.id));
        }
        
        //Update opportunities for ownership
        if(!updateOppList.isEmpty()){
            string errorString = '';
            List<Database.SaveResult> srList = Database.update(updateOppList, false);
            for(Database.SaveResult sr:srList){
                if(!sr.isSuccess()){
                    for(Database.Error err :sr.getErrors()){
                        errorString += 'Opportunity Id: '+ sr.getId() + ' Error Message: ' + err.getMessage()+'\n';
                    }
                } 
            }
            
            //Error Handing
            if(string.isNotEmpty(errorString) || Test.isRunningTest()){
                List<string>errorList = new List<string>();
                errorList.add('The following error occured for Promoted AE Opportunity ownership change: '+'\n');
                errorList.add(errorString);
                ExceptionHandling.performExceptionHandling(null, 'PromotedAEOpportunityOwnerUpdateBatch', errorList);
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
            sEmail.setSubject('Account & Open Opportunities Ownership Change Notification');
            string msg = 'Hello!' + '\n'+ '\n' + 'This is the notification for account & open opportunities ownership change from '+ userMap.get(repId).name + ' to ' + userMap.get(previousManagerId).name + '\n'+ '\n';
            msg += 'The following prior segment accounts & related open opportunities owned by '+ userMap.get(repId).name +' are transferred to '+ userMap.get(previousManagerId).name + '\n';
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
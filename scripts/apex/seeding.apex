//Generate Sandbox Test Data
// ————| Control Panel |————
// change this to reflect number of records to create
Integer countRecordsToCreate = 10;
Integer kpusPerAcc = 1;
Boolean deleteExistingRecords = true;
Id userId = UserInfo.getUserId();
//String userId = '';
// ————————————————---------
//Gets user record
User user = [SELECT Id, FirstName, LastName FROM User WHERE Id = :userId];
// -————| Delete Logic |————-
if(deleteExistingRecords == true){
	List<Account> accsToDelete = new List<Account>([SELECT Id FROM Account WHERE CreatedDate = Today AND OwnerId =:userId]);
  List<Opportunity> oppsToDelete = new List<Opportunity>([SELECT Id FROM Opportunity WHERE CreatedDate = Today AND AccountId IN :accsToDelete]);
  List<Contract> contractsToDelete = new List<Contract>([SELECT Id FROM Contract WHERE CreatedDate = Today AND OwnerId =:userId AND AccountId IN :accsToDelete]);
  List<Contact> contactsToDelete = new List<Contact>([SELECT Id FROM Contact WHERE CreatedDate = Today AND OwnerId = :userId AND AccountId IN :accsToDelete]);
  List<Order> ordersToDelete = new List<Order>([SELECT Id FROM Order WHERE CreatedDate = Today AND OwnerId = :userId AND AccountId IN :accsToDelete]);
   
  System.debug('Accounts: ' + accsToDelete.size());
  System.debug('Opps: ' + oppsToDelete.size());
  System.debug('Contracts: ' + contractsToDelete.size());
  System.debug('Contacts: ' + contactsToDelete.size());
   
  delete oppsToDelete;
  delete contractsToDelete;
  delete accsToDelete;
  delete contactsToDelete;
  delete ordersToDelete;
   
}
//User initials
String userInitials = (user.FirstName.left(1) + user.LastName.left(1)).toUpperCase();
System.debug('User Initials: ' + userInitials);
//list of Opp Types to create
List<String> oppTypes = new List<String>{
  'Land: New Account'
};
   
//Used to randomize Klaviyo Accound Id
String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
//Date string used in names of records   
String strDate = Date.today().month().format()+ '/' + Date.today().day().format();
//declare record list variables
List<Opportunity> oppList = new List<Opportunity>();
List<Account> accList = new List<Account>();
List<Klaviyo_Product_Usage__c> kpuList = new List<Klaviyo_Product_Usage__c>();
List<Contact> contList = new List<Contact>();
//create Accounts
for(Integer i=0;i<countRecordsToCreate;i++){
  System.debug('Account Iteration:' + i);
	
  //generates random Klaviyo Account Id
  String KlavAccId = '';
  While(KlavAccId.length() < 7){
    Integer idx = math.mod(math.abs(crypto.getRandomInteger()), chars.length());
    KlavAccId += chars.substring(idx, idx+1);  
  }
   
  Account acc = new Account(
  	Name = userInitials + ' TEST ACC - '+ strDate + ' - '+ String.valueOf(i+1),
    Product_Klaviyo_Account_ID__c = KlavAccId,
		OwnerId = userId
  );
   
  accList.add(acc);
}
System.debug('# of Accounts: ' + accList.size());
insert accList;
for(Account acc : accList){
  Klaviyo_Product_Usage__c kpu = new Klaviyo_Product_Usage__c(
  	//Name = acc.Product_Klaviyo_Account_ID__c,
    Klaviyo_Account_ID__c = acc.Product_Klaviyo_Account_ID__c,
    Account__c = acc.Id
  );
  kpuList.add(kpu);   
}
insert kpuList;
//Create Contacts for each Account
for (Integer k = 0; k < accList.size(); k++) {
   
  Account acc = accList[k];
  Contact cont = new Contact(
    AccountId = acc.Id,
    LastName = userInitials + ' TEST CONT - ' + strDate + ' - ' + String.valueOf(k+1),
    Email = userInitials + 'TestCont' + Date.today().month().format() + '.' + Date.today().day().format() + '.' + String.valueOf(k+1) +'@testrecord.com'
  );
  contList.add(cont);
}
insert contList;
//Create Opps for each account
for(Integer j=0;j<countRecordsToCreate;j++){
   
	System.debug('Opp Creation Index: ' + j);
   
  Opportunity NewOpp = new Opportunity(
    Name= userInitials + ' TEST OPP - '+ strDate + ' - '+ String.valueOf(j+1),
    AccountId = accList[j].id,
    Amount = 100,
		OwnerId = userId,
    Opportunity_Product__c = 'Email Subscription',
    StageName = 'S1: Discovery',
    CloseDate = Date.today(),
    LeadSource = 'Inbound',
		Sales_Method__c = 'Contracted',
    MARKETING_Most_Recent_Lead_Source_Detail__c = 'Direct',
    MARKETING_Initial_Lead_Source__c = 'Inbound',
    MARKETING_Initial_Lead_Source_Detail__c = 'Direct',
    SALES_Current_Email_Platform__c = 'Mailchimp',
    Competitive_Environment__c = 'Mailchimp',
    Discount_Approval_Status__c = 'Not Active',
    Discount_Reason__c = 'Accelerate the Deal',
    Discount_Reason_Additional_Details__c = 'Test Test Test',
    Klaviyo_Product_Usage__c = kpuList[j].id 
     
  );
  oppList.add(NewOpp);
}
System.debug('# of Opps: ' + oppList.size());
insert oppList;
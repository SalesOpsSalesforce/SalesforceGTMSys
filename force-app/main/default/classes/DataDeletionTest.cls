// [vrajapatruni 08/15/2022 SFDC-434] Test class for Data Deletion Controller class
@isTest
private class DataDeletionTest {
    
    @testSetup
    static void dataSetup(){
        
        //Create test Leads
        List<Lead> ldList = new List<Lead>();
        for(Integer i=0;i<2;i++) {
            ldList.add(new lead(Lastname ='testLead '+i, Company = 'TestCompany '+i, Website = 'https://www.google.com', email = 'test@email.com'));  
        }
        insert ldList;  
        
        //Create test Accounts
        List<Account> accList = new List<Account>();
        Map <String,Schema.RecordTypeInfo> accRecordTypeMap = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        for(Integer i=0;i<2;i++) {
            accList.add(new Account(Name = 'Test Account'+i, recordTypeId = accRecordTypeMap.get('Klaviyo Account').getRecordTypeId(),
                                    Product_Klaviyo_Account_ID__c  = 'abc'+i, Website = 'https://www.google.com', Main_POC_Email_Address__c = 'test@email.com'));
        }
        insert accList;
        
        //Create test Contacts
        List<Contact> contactList = new List<Contact>();
        for(Integer i=0;i<2;i++) {
            contactList.add(new contact(Lastname ='testContact '+i, email = 'test@email.com'));  
        }
        insert contactList; 
        
        //Create test Cases
        Case testcase = new Case(ContactId = contactList[0].Id, AccountId = accList[0].Id, Status = 'New', Origin = 'Phone');
        insert testcase;
        
        //Create test Tasks
        RecordType rt = [select Id from RecordType where SobjectType='Task' and DeveloperName='LinkedIn_Call' limit 1];
        Task testTask = new Task(WhoId=ldList[0].Id, Status = 'Completed', Type = 'Email', Subject = 'Message Sent:', RecordTypeId = rt.Id, Priority = 'Normal', ActivityDate = Date.newInstance(2021,09,08));
        insert testTask;
        
        //Create Anonymized Contact
        Contact con = new Contact(Lastname ='Anonymized Contact', email = 'ac@email.com');
        insert con;
        
        //Create Skilljar student
        skilljar__Student__c sStud = new skilljar__Student__c(skilljar__Email__c = 'test@email.com', skilljar__Obfuscated_Id__c = '112233');
        insert sStud;
        
        //Create test opportunities for contracts
        List <OpportunityStage> oppStage = [select ApiName, IsActive, IsClosed, IsWon, DefaultProbability from OpportunityStage where IsActive = true and DefaultProbability = 25 limit 1];
        Opportunity opp = new Opportunity(Name='Test Opp 2', AccountId=accList[0].Id, StageName='Closed Won', CloseDate=Date.today(), SALES_PayoutAmounttoReferralPartner__c='Yes - Silver - 10%', Update_Widget__c=1, Type__c='Expand: Additional Product', Amount=100.0, SALES_Ecommerce_Platform__c='Shopify',
                LEAD_Partner_Lead_Registration_Status__c='Accepted', LEAD_Partner_Registration_Status_Reason__c='Accepted - New', LEAD_SALES_DateTimeofPartnerLeadAcceptRe__c=Datetime.now(), Opportunity_Product__c = 'Email Subscription');
        insert opp;
        
        //Create test Contracts
        Contract__c cc = new Contract__c(Name = 'test contract', Account__c = accList[0].Id, Opportunity__c = opp.Id, Counterparty_Signer_Email__c = 'test@email.com');
        insert cc;
        
    }
   
    @isTest
    private static void testDataDeletionController()
    {
        DataDeletionController.getLeadDataByEmail('test@email.com');
        // System.assertEquals(null, result);
    }
}
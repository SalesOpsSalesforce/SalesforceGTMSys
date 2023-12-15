@isTest
public class CharmDataEnrichmentTest {
    @testSetup
    static void dataSetup(){
        //Create accounts
        List<Account> accList = new List<Account>();
        Map <String,Schema.RecordTypeInfo> accRecordTypeMap = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        //Customer Accounts
        for(Integer i=0;i<2;i++) {
            accList.add(new Account(Name = 'Test Account'+i, recordTypeId = accRecordTypeMap.get('Klaviyo Account').getRecordTypeId(),
                                    Product_Klaviyo_Account_ID__c  = 'abc'+i, Website = 'https://www.google.com'));
        }
        insert accList;
        
        //Create Leads
        List<Lead> ldList = new List<Lead>();
        for(Integer i=0;i<2;i++) {
            ldList.add(new lead(Lastname ='testLead '+i, Company = 'TestCompany '+i, Website = 'https://www.google.com'));  
        }
        insert ldList;    
    }
    
    @isTest
    private static void testCharmMetricsUpdates(){
        List<Lead> ldList = [Select id, Website, Clean_Website__c from lead];
        Test.startTest();
        
        //SFDC-1182 Data enrichment on owner change to AE or BDR user
        Profile salesProfile = [Select id from profile where name = 'AE Sales User'];
        Userrole bdrRole = [Select Id,DeveloperName from userrole where DeveloperName like 'iBDR' limit 1];
        Userrole AERole = [Select Id,DeveloperName from userrole where DeveloperName like 'MM_AE_I' limit 1];
        User uBDR = new User(LastName = 'BDR User', email = 'bdr@test.com', username = 'bdr@test.com'+ UserInfo.getOrganizationId(),
                             profileid = salesProfile.Id, UserroleId = bdrRole.Id, Alias = 'bdruser', 
                             EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                             TimeZoneSidKey='America/Los_Angeles');
        User uAE = new User(LastName = 'AE User', email = 'ae@test.com', username = 'ae@test.com'+ UserInfo.getOrganizationId(),
                            profileid = salesProfile.Id, UserroleId = AERole.Id, Alias = 'aeuser', 
                            EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                            TimeZoneSidKey='America/Los_Angeles');
        List<user> userList = new List<user>();
        userList.add(uBDR);
        userList.add(uAE);
        insert userList;
        
        System.runAs(uAE){
            Lead ld = ldList[0];
            ld.Website = 'https://www.facebook.com';
            update ld;
            ld.ownerId = uBDR.Id;
            update ld;
            //[RGaokar 09/06/2022 SFDC-515] Charm Enhancement- Logic extended for account website update
            List<Account> accList = [Select id, Website, Clean_Website__c from Account];
            Account a = accList[0];
            a.Website = 'https://www.facebook.com';
            update a;
            CharmDataEnrichmentScheduler charmSch = new CharmDataEnrichmentScheduler();
            String sch = '0 0 23 * * ?';
            system.schedule('Test CharmIo Scheduler', sch, charmSch);
        }
        Test.stopTest();
    }
}
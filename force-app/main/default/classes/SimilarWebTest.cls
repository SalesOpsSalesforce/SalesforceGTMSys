@isTest
private class SimilarWebTest {
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
    private static void testSimilarWebUpdates(){
        List<Lead> ldList = [Select id, Website from lead];
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
            ldList[0].Website = 'https://www.facebook.com';
            update ldList[0];
            SimilarWebScheduler swSch = new SimilarWebScheduler();
            String sch = '0 0 23 * * ?';
            system.schedule('Test SimilarWeb Scheduler', sch, swSch);
            ldList[0].ownerId = uBDR.Id;
			ldList[1].ownerId = uAE.Id;
            update ldList;
            ldList[0].ownerId = uAE.Id;
            update ldList[0];
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testSimilarWebVFController(){
        Account acc = [Select id, Website from Account limit 1];
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        SimilarWebController swController = new SimilarWebController(sc);
        swController.fetchSimilarWebMetrics();
        Test.stopTest();
    }
}
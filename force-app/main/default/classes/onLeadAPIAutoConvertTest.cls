//[RGaokar 02/14/2022 TP #106769] This test class is for AutoConvertLeads class
@isTest
private class onLeadAPIAutoConvertTest {
    
    static testMethod void onLeadAPIAutoConvertTest() {   
        
        //Set up test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        List<Contact> conList = new List<Contact>(); 
        conList.add(new Contact(LastName = 'Test Contact', accountId = acc.id, email = 'test1@test.com'));
        conList.add(new Contact(LastName = 'Test Contact', accountId = acc.id, email = 'test2@test.com'));
        insert conList;
        Opportunity opp = new Opportunity(Name = 'Test Opp', account = acc, 
                                          StageName= 'Prospecting', CloseDate=Date.today());
        insert opp;
        List<Lead> testLeads = new List<Lead>();
        for(Integer i=0;i<10;i++) {
            testLeads.add(new Lead(company='TestPlatformLead'+i, lastname='TestLeadLast'+i,email='TestLead'+i+'@gmail.com', 
                                   Leadsource = 'Outbound', MARKETING_Most_Recent_Lead_Source_Detail__c = 'Datanyze',
                                   Klaviyo_Account_ID__c = 'abc'+i, Account__c = acc.id));
        }
        testLeads[9].email = 'test2@test.com';
        
        insert testLeads;
        
        Test.startTest();
        List<AutoConvertLeads.ConvertLeadRequest> requestList = new List<AutoConvertLeads.ConvertLeadRequest>();
        for(Integer i=0;i<10;i++){
            AutoConvertLeads.ConvertLeadRequest request = new AutoConvertLeads.ConvertLeadRequest();
            request.leadId = testLeads[i].id;
            request.convertedStatus = 'Converted';
            if(i != 9){
                request.accountId = testLeads[i].Account__c;
                request.contactId = conList[0].Id;
                request.opportunityId = opp.id;
            }else{
                request.createOpportunity = false;
                request.existingContactId = conList[1].Id;
            }
            requestList.add(request);
        }
        
        AutoConvertLeads.convertLeads(requestList);
        Test.stopTest();
        
        //Verify results
        List<AccountContactRelation> acrList = [Select ContactId, AccountId from AccountContactRelation 
                                                where contact.email = 'test2@test.com'];
        system.assertEquals(2, [Select count() from Account]);
        system.assertEquals(2, [Select count() from Contact]);
        system.assertEquals(1, [Select count() from Opportunity]);
        system.assertEquals(2, acrList.size());
        system.assertEquals(10, [Select count() from Lead where isconverted = true]);
    }
}
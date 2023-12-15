@isTest
private class KlaviyoAccountSyncTest {
    /** Tests the KlaviyoAccountSync APEX class as well as trigger. */
    static testMethod void testSyncAccountManager() {
        /** Test that the KlaviyoAccountSync class's syncAccountManager method works. */
        Test.startTest();
        List<User> users = [SELECT Id FROM User WHERE userType='Standard' LIMIT 1];
        Id userId = users.get(0).Id;
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User usr = new User(Id = userId,
                            LastName = 'person',
                            FirstName='Test',
                            Alias = 'tperson',
                            Email = 'test.person@email.com',
                            Username = 'test.person@email.com',
                            ProfileId = p.Id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        Account acct = new Account(Name='### Test Account ###',
                                      Product_Klaviyo_Account_ID__c = 'abc123');
        // Set new fields
        acct.Channel_Manager__c = usr.Id;
        acct.OwnerId = usr.Id;
        acct.Onboarding_Specialist__c = usr.Id;
        acct.SUPPORT_Account_Manager__c = usr.Id;
        // Queue Account for processing
		Set<Account> accountsToSync = new Set<Account>();
        accountsToSync.add(acct);
        KlaviyoAccountSync klAccountSync = new KlaviyoAccountSync(accountsToSync);
        ID jobID = System.enqueueJob(klAccountSync);
        System.debug('Queued new job with jobID' + jobID);

        Test.stopTest();
    }

    static testMethod void testAccountTrigger() {
        /** Test the trigger on an Account for insert & update runs successfully. */
        Test.startTest();

        List<User> users = [SELECT Id FROM User WHERE userType='Standard' LIMIT 1];
        Id userId = users.get(0).Id;
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User usr = new User(Id = userId,
                            LastName = 'person',
                            FirstName='Test',
                            Alias = 'tperson',
                            Email = 'test.person@email.com',
                            Username = 'test.person@email.com',
                            ProfileId = p.Id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        
        Account acct = new Account(Name='### Test Account ###',
                                      Product_Klaviyo_Account_ID__c = 'abc123');
        // Set new account Owner
        acct.OwnerId = usr.Id;
        acct.Onboarding_Specialist__c = usr.Id;
        insert acct;
        // Set new CSM
        acct.Channel_Manager__c = usr.Id;
        update acct;

        Test.stopTest();
    }
}
trigger CSMKlaviyoAccountSync on Account (after insert, after update) {
    /**
     * If an Account's "Account Manager" changes, pass in the new User's info to sync back to Klaviyo.
     */
    if (Trigger.new.size()<=5){
        for (Account account: Trigger.new) { // handle bulk inserts
            if (Trigger.isUpdate && Trigger.oldMap.get(account.Id).SUPPORT_Account_Manager__c ==
                account.SUPPORT_Account_Manager__c) {
                continue; // no change recorded for this field, ignore
            }
    
            String accountManagerId = account.SUPPORT_Account_Manager__c;
            String accountManagerEmail;
            if (accountManagerId == null) {
                accountManagerEmail = '';
            } else {
                List<User> users = [SELECT Email FROM User where Id = :accountManagerId LIMIT 1];
                accountManagerEmail = users.get(0).Email;
            }
    
            String klaviyoAccountId = account.Product_Klaviyo_Account_ID__c;
    
            KlaviyoAccountSync syncAM = new KlaviyoAccountSync();
            syncAM.syncAccountManager(klaviyoAccountId, accountManagerEmail);
        }
    }
}
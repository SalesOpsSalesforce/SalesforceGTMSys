/*
For Accounts WHERE: MRRCalc__c = 0 AND RecordTypeId = '012d0000001YZJK' AND FINANCE_Payment_Method__c = 'Stripe' ﻿AND ﻿Parent is null AND Account Owner != Salesforce API, Core Placeholder, Special Ops Placeholder, or Klaviyo Partners
AND RU_of_Open_Opportunities__c = 0 AND (TODAY - Calculated_Last_Activity_Date__c) > 30 AND (TODAY - Last_Owner_Change_Date__c) > 5 AND FM_Compiled_Ecommerce_Platform__c CONTAINS 'shopify' (not case sensitive)
* AND 31 (or more) ﻿days since calculated last activity date. If no calculated last activity date, 31 (or more) days since last owner change date. If no last owner change date, 31 days (or more) since created date.

Then:
Target_Account_Status__c = Untouched/Cold
Account Owner = Core Placeholder
Untouched Status Change = Date Stamp

For Accounts WHERE:MRRCalc__c = 0 AND RecordTypeId = '012d0000001YZJK' AND FINANCE_Payment_Method__c = 'Stripe' ﻿﻿AND ﻿Parent is null AND Account Owner != Salesforce API, Core Placeholder, Special Ops Placeholder, or Klaviyo Partners
AND RU_of_Open_Opportunities__c = 0 AND (TODAY - Calculated_Last_Activity_Date__c) > 30 AND (TODAY - Last_Owner_Change_Date__c) > 5 AND FM_Compiled_Ecommerce_Platform__c DOES NOT CONTAIN 'shopify' (not case sensitive)
* AND 31 (or more) ﻿days since calculated last activity date. If no calculated last activity date, 31 (or more) days since last owner change date. If no last owner change date, 31 days (or more) since created date.

Then:
Target_Account_Status__c = Untouched/Cold
Account Owner = Special Ops Placeholder
Untouched Status Change = Date Stamp

For Accounts WHERE: MRRCalc__c = 0 AND RecordTypeId = '012d0000001YZJK' AND FINANCE_Payment_Method__c = 'Stripe' AND Account Owner != Salesforce API, Core Placeholder, Special Ops Placeholder, or Klaviyo Partners
Target_Account_Status__c = Untouched/Cold
AND RU_of_Open_Opportunities__c = 0 AND (TODAY - Calculated_Last_Activity_Date__c) <= 30
*AND Calculated Last Activity Date is within last 31 days (if null, does not meet criteria)

Then: 
Target_Account_Status__c = Attempting
*/

global class TargetAccountStatusBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Set<Id> userIds = new Set<id>(); 
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        List<Id> userList = new List<Id>();
        userList.add(System.Label.Salesforce_API_User_Id);
        userList.add(System.Label.Core_Placeholder_Id);
        userList.add(System.Label.Special_Ops_Placeholder_Id);
        userList.add(System.Label.Klaviyo_Partners_Id);
         
        List<User> userExceptionList = [SELECT Id FROM User Where Target_Account_Exception__c = true];
    
        String query = 'SELECT Id, Name, MRRCalc__c, RecordTypeId, FINANCE_Payment_Method__c, OwnerId, Target_Account_Status__c, RU_of_Open_Opportunities__c, Calculated_Last_Activity_Date__c, LastActivityDate, Last_Activity_Date_Custom__c, Parent.Name, Last_Owner_Change_Date__c, CreatedDate, FM_Compiled_Ecommerce_Platform__c, Current_Contract_Expiration_Date__c, Competitor_with_Current_Contract__c, Cancellation_Date__c FROM Account where  MRRCalc__c = 0 AND RecordTypeId = \'012d0000001YZJK\' AND FINANCE_Payment_Method__c = \'Stripe\' AND RU_of_Open_Opportunities__c = 0 AND ParentId = null AND OwnerId NOT in: userList AND OwnerId NOT in: userExceptionList';
        return Database.getQueryLocator(query);   
         
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accts){
        
        KlaviyoAccountSync.isRunFromTAPBatch = true;
        
        for(Account acct: accts){
            if(acct.Target_Account_Status__c == 'Untouched' && acct.Calculated_Last_Activity_Date__c <> null && acct.Calculated_Last_Activity_Date__c.daysBetween(Date.today()) <= 31)
            { 
                acct.Target_Account_Status__c = 'Attempting';
                update acct;
            }
            // [SFDC-2833 VRajapatruni 06/20/2023] Target account Status is not Churned OR (Target account Status IS 'Churned' AND churn date was more than 12 months ago') 
            if(acct.Current_Contract_Expiration_Date__c == null && (acct.Target_Account_Status__c <> 'Churned' || (acct.Target_Account_Status__c == 'Churned' && acct.Cancellation_Date__c != null && acct.Cancellation_Date__c.addMonths(12) < Date.today()))){            
                if((((acct.Last_Owner_Change_Date__c <> null && acct.Calculated_Last_Activity_Date__c <> null && acct.Last_Owner_Change_Date__c > acct.Calculated_Last_Activity_Date__c && acct.Last_Owner_Change_Date__c.daysBetween(Date.today()) > 5)
                            || (acct.Calculated_Last_Activity_Date__c == null && acct.Last_Owner_Change_Date__c <> null && acct.Last_Owner_Change_Date__c.daysBetween(Date.today()) > 5))
                        ||((acct.Last_Owner_Change_Date__c <> null && acct.Calculated_Last_Activity_Date__c <> null && acct.Last_Owner_Change_Date__c < acct.Calculated_Last_Activity_Date__c && acct.Calculated_Last_Activity_Date__c.daysBetween(Date.today()) > 30)
                            || (acct.Calculated_Last_Activity_Date__c <> null && acct.Last_Owner_Change_Date__c == null && acct.Calculated_Last_Activity_Date__c.daysBetween(Date.today()) > 30))
                        ||(acct.Calculated_Last_Activity_Date__c == null && acct.Last_Owner_Change_Date__c == null && acct.CreatedDate <> null && acct.CreatedDate.date().daysBetween(Date.today()) > 5)
                        ||(acct.Last_Owner_Change_Date__c <> null && acct.Calculated_Last_Activity_Date__c <> null && acct.Last_Owner_Change_Date__c == acct.Calculated_Last_Activity_Date__c && acct.Last_Owner_Change_Date__c.daysBetween(Date.today()) > 5 && acct.Calculated_Last_Activity_Date__c.daysBetween(Date.today()) > 30)) //[SFDC-1297 VR] Bug fix when both dates are same 
                        
                    && (acct.FM_Compiled_Ecommerce_Platform__c <> null && acct.FM_Compiled_Ecommerce_Platform__c.containsIgnoreCase('shopify')))
                 {  
                    userIds.add(acct.OwnerId);
                    acct.Target_Account_Status__c = 'Untouched';
                    acct.ownerId = System.Label.Core_Placeholder_Id; 
                    acct.Untouched_Status_Change__c = date.today();
                    update acct;
                 }
                    
                 if((((acct.Last_Owner_Change_Date__c <> null && acct.Calculated_Last_Activity_Date__c <> null && acct.Last_Owner_Change_Date__c > acct.Calculated_Last_Activity_Date__c && acct.Last_Owner_Change_Date__c.daysBetween(Date.today()) > 5)
                            || (acct.Calculated_Last_Activity_Date__c == null && acct.Last_Owner_Change_Date__c <> null && acct.Last_Owner_Change_Date__c.daysBetween(Date.today()) > 5))
                        ||((acct.Last_Owner_Change_Date__c <> null && acct.Calculated_Last_Activity_Date__c <> null && acct.Last_Owner_Change_Date__c < acct.Calculated_Last_Activity_Date__c && acct.Calculated_Last_Activity_Date__c.daysBetween(Date.today()) > 30)
                            || (acct.Calculated_Last_Activity_Date__c <> null && acct.Last_Owner_Change_Date__c == null && acct.Calculated_Last_Activity_Date__c.daysBetween(Date.today()) > 30))
                        ||(acct.Calculated_Last_Activity_Date__c == null && acct.Last_Owner_Change_Date__c == null && acct.CreatedDate <> null && acct.CreatedDate.date().daysBetween(Date.today()) > 5)
                        ||(acct.Last_Owner_Change_Date__c <> null && acct.Calculated_Last_Activity_Date__c <> null && acct.Last_Owner_Change_Date__c == acct.Calculated_Last_Activity_Date__c && acct.Last_Owner_Change_Date__c.daysBetween(Date.today()) > 5 && acct.Calculated_Last_Activity_Date__c.daysBetween(Date.today()) > 30)) //[SFDC-1297 VR] Bug fix when both dates are same 
                    
                    && (acct.FM_Compiled_Ecommerce_Platform__c == null || (!acct.FM_Compiled_Ecommerce_Platform__c.containsIgnoreCase('shopify'))))
                 { 
                    userIds.add(acct.OwnerId);
                    acct.Target_Account_Status__c = 'Untouched';
                    acct.ownerId = System.Label.Special_Ops_Placeholder_Id; 
                    acct.Untouched_Status_Change__c = date.today();
                    update acct;
                 }
            } 
        }     
        
    }    
    
    global void finish(Database.BatchableContext bc){
        
        if(!userIds.isEmpty() && !Test.isRunningTest()){
            Database.executeBatch(new UpdateAssociatedAccountsBatch(userIds), 1);
        }
        
    }  
      
}
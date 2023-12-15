/*
[vrajapatruni August 29 2022] SFDC - 434 and SFDC - 679
Data Deletion Requests project needs an automation to delete or obfuscate data upon request. LWC has a place for an email input

Apex from LWC looks for Leads by matching the Lead’s Email against the input email
-Apex changes Lead Name to “Anonymized User”
-Apex deletes field history that shows the name being changed to “Anonymized User”
-Apex doesn’t delete Klaviyo Account ID
-Apex deletes the values in the following fields on the Lead records found
Address
Email
Fax
Mobile
Name (First/Last)
Phone
Title
Secondary Phone
Corporate Email Address


Apex from LWC looks for Accounts by matching Main POC Email Address and Referral Partner’s Main Email fields on Accounts against the input email
-Apex deletes the following field values on the Account records found. Apex doesn’t delete Klaviyo Account ID
LinkedIn URL
Main POC Email Address
Primary Billing Email Addresss
Referral Partner's Main Email
Phone


Apex finds Contacts by matching Contact’s Email against the email input
-Apex deletes Contact records found

Apex finds Masters Partner SOW Submission records by matching the SOW Submission’s Client Contact Email against the input email
-Apex deletes values in the following fields off of the Masters Partner SOW Submissions records found
Client Contact Email
Client Contact First Name
Client Contact Last Name
Client Contact Name

Apex finds Student (Skilljar Managed Package) by matching the Student Email against the input email:
-Apex deletes records found

Apex finds Activity records by matching the Lead or Contact’s email on the Activity against the input email (Synced Gong calls, Outreach emails, or others)
-Apex deletes all found activity records

Apex finds Contracts where the Counterparty Signer’s Email matches the input email
-Apex deletes the values of the following fields off of the found Contract records
Counterparty Signer Name
Counterparty Signer Email

Data Deletion Records object
-An object called “Data Deletion Records” stores deletion records
-Update apex to stamp date/time, who ran it, and if records found or not in each record

[vrajapatruni August 29 2022] SFDC - 788 Removed all zoominfo field references
*/

public with sharing class DataDeletionController {
    
    @AuraEnabled
    public static String getLeadDataByEmail(String email){
        String message;
        List <String> executionFlow = new List <String> ();
        try {
            
            Boolean Executed;
            Data_Deletion_Record__c ddrecord = new Data_Deletion_Record__c();
            
            // Retrieving the list of object records that match the given email address
            List<Lead> listOfLeads = [Select Id, Name, Email, Fax, FirstName, LastName, Phone, Title, 
                                      Country, Street, City, State, PostalCode,
                                      SALES_Secondary_Phone__c, SALES_Corporate_Email_Address__c, MobilePhone
                                      From Lead 
                                      Where Email =: email];
            
            List<Account> listOfAccounts = [Select Id, Name, Main_POC_Email_Address__c, RP_Referral_Partner_s_Main_Email__c, 
                                            PAYMENT_Primary_Billing_Email_Address__c, LinkedIn_URL__c, Phone
                                            From Account 
                                            Where Main_POC_Email_Address__c =: email OR RP_Referral_Partner_s_Main_Email__c =: email];
            
            List<Contact> listOfContacts = [Select Id, Name, OwnerId
                                            From Contact 
                                            Where Email =: email];
                                            
            List<Case> listOfCases = [Select Id, ownerId, contactId
                                      From Case 
                                      Where ContactEmail =: email];
            
            List<Task> listOfTasks = [Select Id, Subject
                                      From Task 
                                      Where WhoId In: listOfContacts OR WhoId In: listOfLeads];
            
            List<Partner_Program_Information__c> listOFPartnerProgramInformation = [Select Id, Client_Contact_Email__c,
                                                                                    Client_Contact_First_Name__c, Client_Contact_Last_Name__c
                                                                                    From Partner_Program_Information__c 
                                                                                    Where Client_Contact_Email__c =: email];
            
            List<skilljar__Student__c> listOfStudents = [Select Id 
                                                         From skilljar__Student__c 
                                                         Where skilljar__Email__c =: email];
            
            List<Contract__c> listOfContracts = [Select Id 
                                                 From Contract__c 
                                                 Where Counterparty_Signer_Email__c =: email];
            
            // Retrieve the ID of the Anonymoized contact for assignment at a later stage below
            Id anonymizedContactId = [select ID from contact where name = 'Anonymized Contact' limit 1].ID;
            
            // Update the data deletion record 
            ddrecord.Date_Time_Ran__c = dateTime.now();
            ddrecord.User_Who_Ran_DSAR_LWC__c = UserInfo.getUserId();
            
            // No records found that match the given email
            if(listOfLeads.isEmpty() && listOfTasks.isEmpty() && listOfCases.isEmpty() && listOfContacts.isEmpty() && listOfAccounts.isEmpty() 
                && listOFPartnerProgramInformation.isEmpty() && listOfStudents.isEmpty() && listOfContracts.isEmpty()){

                    ddrecord.Were_records_found__c = 'No';
                    insert ddrecord;
                    executionFlow.add('No records found to delete');
                    message = 'No records found';
                    return message;

            }
            // Records found that match the given email
            else{
                
                ddrecord.Were_records_found__c = 'Yes';
                executionFlow.add('Records found to delete');

                if(!listOfTasks.isEmpty())
                    delete listOfTasks;
            
                if(!listOfCases.isEmpty()){
                    for(Case caseRecord : listOfCases){
                        caseRecord.ContactId =  anonymizedContactID;
                    }
                    update listofCases;
                }
                
                if(!listOfContacts.isEmpty())
                    delete listOfContacts;
                
                for(Account accountRecord : listOfAccounts){
                    accountRecord.Main_POC_Email_Address__c = null;
                    accountRecord.RP_Referral_Partner_s_Main_Email__c = null;
                    accountRecord.PAYMENT_Primary_Billing_Email_Address__c = null;
                    accountRecord.LinkedIn_URL__c = null;
                    accountRecord.Phone = null;
                }
                
                if(!listOfAccounts.isEmpty())
                    update listOfAccounts;
                
                if(!String.isEmpty(email) && !listOfLeads.isEmpty()){
                    updateLead(email);
                    Executed = true;
                }
                
                for(Partner_Program_Information__c partnerProgramInformationRecord : listOFPartnerProgramInformation){
                    partnerProgramInformationRecord.Client_Contact_Email__c = null;
                    partnerProgramInformationRecord.Client_Contact_First_Name__c = null;
                    partnerProgramInformationRecord.Client_Contact_Last_Name__c = null;
                    partnerProgramInformationRecord.Client_Contact_Name__c = null;
                }
                
                if(!listOFPartnerProgramInformation.isEmpty())
                    update listOFPartnerProgramInformation;
                
                if(!listOfStudents.isEmpty())
                    delete listOfStudents;
                
                if(!listOfContracts.isEmpty()){
                    for(Contract__c contractRecord : listOfContracts){
                        contractRecord.Counterparty_Signer_Name__c = null;
                        contractRecord.Counterparty_Signer_Email__c = null;
                    }
                    update listOfContracts;
                }
                
                if(!String.isEmpty(email) && Executed == true){
                    clearLeadHistory(email);
                    executionFlow.add('Lead History deleted');
                }
                
                insert ddrecord;
                
                message = 'Success';
                return message;
            }
            
            
        } catch (Exception e) {
            ExceptionHandling.performExceptionHandling(e, 'DataDeletionController', executionFlow);
            return e.getMessage();
        }
    }
    
    // Update the leads 
    //@future
    public static void updateLead(String email){
        List<Lead> listOfLeads = [Select Id, Name, Email, Fax, FirstName, LastName, Phone, Title, 
                                  Country, Street, City, State, PostalCode,
                                  SALES_Secondary_Phone__c, SALES_Corporate_Email_Address__c, MobilePhone
                                  From Lead 
                                  Where Email =: email];
        
        for(Lead leadRecord : listOfLeads){
            leadRecord.SALES_Corporate_Email_Address__c = false;
            leadRecord.SALES_Secondary_Phone__c = null;
            leadRecord.Title = null;
            leadRecord.Phone = null;
            leadRecord.Country = null;
            leadRecord.Street = null;
            leadRecord.City = null;
            leadRecord.State = null;
            leadRecord.PostalCode = null;
            leadRecord.Fax = null;
            leadRecord.Email = null;
            leadRecord.MobilePhone = null;
            leadRecord.FirstName = 'Anonymized';
            leadRecord.LastName = 'User';
        }
        
        if(!listOfLeads.isEmpty())
            update listOfLeads;
        
        }
        
        // Clear lead history of updating the name
        @future
        public static void clearLeadHistory(String email){
            
            List<Lead> leadList = new List<Lead> ();
            leadList.addAll([SELECT Id FROM Lead WHERE Email =: null and name = 'Anonymized User']);
            
            List<LeadHistory> leadHistory = new List<sObject> ();
            leadHistory.addAll([SELECT Id FROM LeadHistory WHERE createdDate >: Datetime.now().addMinutes(-30) and (Field = 'FirstName' OR Field = 'LastName') and LeadId IN :leadList]);
            Database.delete(leadHistory);
        
        }
}
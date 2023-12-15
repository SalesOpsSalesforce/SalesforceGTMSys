/* *********
*  Date:            10/2019
*  Description:     
*  Developer:       OpFocus
* *********/
public with sharing class PartnerPayment {

    //Override the current month in tests if this is not null
    @testVisible private static Integer monthOverride = null;
    @testVisible private static Boolean paymentMethodOverride = null;

    public PartnerPayment() {
    }

    // UnpaidName
    // formula field from flow:
    //
    // "No Payment: "&
    // {!sobjAccount.Name} & 
    // " Payout Payment: " &
    // IF(MONTH(TODAY())>2,TEXT(YEAR(TODAY())),TEXT(YEAR(TODAY())-1)) &
    //
    // " - " &
    //
    // IF(
    // MONTH(TODAY())<3,"Q4",
    // IF(
    // MONTH(TODAY())<6,"Q1",
    // IF(
    // MONTH(TODAY())<9,"Q2",
    // IF(
    // MONTH(TODAY())<9,"Q3","ERROR"))))
    public static String getUnpaidName(String accountName) {
        String unpaidName = 'No Payment: ' + accountName + ' Payout Payment: ';
        unpaidName += (getCurrentMonth() > 2 ? Date.today().year() : Date.today().addYears(-1).year());
        unpaidName += ' - ';
        if (getCurrentMonth() < 3) {
            unpaidName += 'Q4';
        }
        else if (getCurrentMonth() < 6) {
            unpaidName += 'Q1';
        }
        else if (getCurrentMonth() < 9) {
            unpaidName += 'Q2';
        }
        else {
            unpaidName += 'Q3';
        }
        return unpaidName;
    }

    // paymentNameFormula
    //
    // formula field from flow:
    //
    // {!sobjAccount.Name} & 
    //
    // " Advisors Payout Payment: " &
    //
    // IF(MONTH(TODAY())>2,TEXT(YEAR(TODAY())),TEXT(YEAR(TODAY())-1)) &
    //
    // " - " &
    //
    // IF(
    // MONTH(TODAY())<3,"Q4",
    // IF(
    // MONTH(TODAY())<6,"Q1",
    // IF(
    // MONTH(TODAY())<9,"Q2",
    // IF(
    // MONTH(TODAY())<9,"Q3","ERROR"))))
    //
    public static String getPaymentNameFormula(String accountName) {
        String paymentNameFormula = accountName + ' Advisors Payout Payment: ' ;
        paymentNameFormula += (getCurrentMonth() > 2 ? Date.today().year() : Date.today().addYears(-1).year());
        paymentNameFormula += ' - ';
        if (getCurrentMonth() < 3) {
            paymentNameFormula += 'Q4';
        }
        else if (getCurrentMonth() < 6) {
            paymentNameFormula += 'Q1';
        }
        else if (getCurrentMonth() < 9) {
            paymentNameFormula += 'Q2';
        }
        else {
            paymentNameFormula += 'Q3';
        }
        return paymentNameFormula;
    }
      
    // How Do Partner Payments get Calculated?
    //
    // The Partner Payment Calculator is triggered quarterly for Partner Payouts and monthly for accruals. This doc shows step 
    //  by step how the calculator works. Prior to running the calculator though, end customer payments are created in Salesforce, 
    //  which are subsequently used to calculate the Partner Payout. The next two paragraphs go over that process.
    //
    // When an Opportunity is created that has a Referral Partner indicated, the field Payout Amount to Referral Partner is 
    //  stamped based on the Referral Partners tier at submission (this field cannot be changed without the approval of 
    //  Sales Operations, this change was made in October 2018). 
    //
    // Once the deal is Closed Won, any subsequent payments that are made on that Account pull details of the Accounts Land 
    // New Account (if payments are made based on any future Upgrades or Downgrades, it will use the customers current payment 
    // against the original Land New Accounts partner payment tier). A formula field on the Payment record identifies if the 
    // Land New Account was in the last 12 months, and if so, it attributes that payment to the Partner and the payout tier that had been identified.
    //
    // How does the Partner Payment Calculator Work?
    //
    // Process Builder to Trigger Flow: Trigger_Partner Payout Payment Calculator
    // https://klaviyo.lightning.force.com/processui/processui.app?retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DWorkflow&setupid=ProcessAutomation
    //
    // Ex. Account that errors: 0010V00002L05UA
    //
    // Pull the following fields from the agency Account record that the Payment Calculator was run on and store in Variable Record
    // Account ID
    // Account Name
    // Accounts Rev Share Payment Method
    // Accounts Referral Partner Main Email
    //
    // Get Metadata table Payout Calculator Date: https://klaviyo.my.salesforce.com/01I0V000002N5Fs?setupid=CustomMetadata
    //
    // Get all Payout Calculator Date Records
    //
    // Pull the following fields from the Payment Object where the Payments the following criteria is true: 
    //     a Partner payout Amount >$0
    //     Partner Payout Payment field is Null
    //     Payment Date less than the Advisors Quarterly Date (see MetaData table)
    //     the Referral Partner Account ID matches the agency Account ID in Step 1
    //     the Status equals Paid
    //     Payout Amount to Referral Partner does not equal Yes - Influencers Silver - 5%, Yes - Influencers Gold - 10%, 
    //         Yes - Influencers Platinum - 15%, or Attributed to Agency, No Payment
    //
    // Store following values in Variable Record
    //     Payment ID
    //     Payment Amount
    //     Partner Payout Amount
    //     Payment Date
    //
    // Create a Payment on the agency Account record with the following information:
    //     Account is the agency Account that started process
    //     Payment Date = NOW (we will mass update this when Payment is actually paid)
    //     Payment Type is Partner Rev Share Payout
    //     Record Type is Partner Rev Share Payout (0120V000001pNjV)
    //
    // The Flow loops through all payments that were indicated in Step 2 and assigns the following information to the Payment that was created in Step 3
    // Attribute the created Payment ID to the end customer Payment by attaching the ID in the field Partner_Payout_Payment__c
    // List the end customer Payments in the Notes section of the payment created in step 3
    // Compile the Partner Payout Amount from all eligible Payments into the Amount Owed field
    // Store the Earliest Payment date of the oldest unpaid payment and store that information in  the flow
    // If Payments were not found that relate to the agency Account, delete the Payment that was created in step 3
    // If a Payment is found the record is then evaluated to deem if it is either >$200 OR the Earliest Payment Date is less than the first day of the month that started the prior quarter
    // If Payout does not meet the above criteria, the Payment will update with a Status that reads Payout Amount Did Not Meet Minimum Criteria
    // All related Payments will be aggregated in the Notes field (see following example for reference: https://klaviyo.my.salesforce.com/a160V000009hB7p)
    // If the Partner does not meet minimum, Payment Name indicates Non Payment
    // No Payment: {Partner Name} Payout Payment: 20XX - QX
    // If the Partner has a Payment Method indicated, the Payment is updated with the following information
    // Final Amount totaled on the Payment
    // Referral Partners Email Address is added
    // Payment Method is added
    // Payment Name is added
    // {Partner Name} Advisors Payout Payment: 20XX - QX
    // Status = Payment Generated
    // If the Partner does not have a Payment Method indicated, the Payment is updated similarly to step 7 except:
    // Payment Name indicates Non Payment
    // No Payment: {Partner Name} Payout Payment: 20XX - QX
    // Status = Partner Has Not Submitted Payment Info 
    //
    //
    // Link to Calculator Button:
    // Link to Calculator Flow: https://klaviyo.my.salesforce.com/3000V0000019OZm 
    // Link in sandbox: https://klaviyo--partialsb.cs68.my.salesforce.com/3000V0000019OZm
    //
    //
    // Example Partner Referred Opps Report: https://klaviyo.my.salesforce.com/00O0V000005Lgyk
    // 131 Q3 Payment Details (Unpaid, use Links in Payment Notes section): https://klaviyo.my.salesforce.com/a160V00000B8W76 
    // Arctic Leaf Q3 Payment Details: https://klaviyo.my.salesforce.com/a16?rlid=00N0V000009Np8C&id=a160V00000B8Wgk
    //
    public static List <String> calculatePartnerPayments(Id accountId) {
        List <String> lstMessages = new List <String> ();
        lstMessages.add('starting calculatePartnerPayments on account ID ' + accountId);

        try {
            // Lookup Referral Partners
            Account referralPartner = [select Id, Name, RP_Partner_Rev_Share_Payment_Method__c, RP_Referral_Partner_s_Main_Email__c from Account where Id = :accountId];
            lstMessages.add('selected Referral Partner Account: ' + referralPartner.Name);

            // Get metadata table
            List <Payout_Calculator_Dates__mdt> lstPayoutDates = [select Advisors_Prev_Quarter_Date__c, Advisors_Quarterly_Date__c, Influencers_Monthly_Calc_Date__c, Masters_Annual_Date__c from Payout_Calculator_Dates__mdt];
            lstMessages.add('Advisors_Quarterly_Date__c: ' + lstPayoutDates[0].Advisors_Quarterly_Date__c);

            // Lookup payments
            Set <String> setFlowAmounts = new Set <String> {
                                                'Yes - Influencers Silver - 5%',
                                                'Yes - Influencers Gold - 10%',
                                                'Yes - Influencers Platinum - 15%',
                                                'Attributed to Agency, No Payment'
                                            };

            List <Payment__c> lstPayments = [
                                    select Id, Amount__c, FM_Partner_Payout_Amount__c, Payment_Date__c 
                                    from Payment__c 
                                    where
                                        Account_MRR_0__c = true
                                        and FLOW_Payout_Amount_to_Referral_Partner__c not in :setFlowAmounts
                                        and FM_Partner_Payout_Amount__c > 0
                                        and Partner_Payout_Payment__c = null
                                        and Payment_Date__c < :lstPayoutDates[0].Advisors_Quarterly_Date__c
                                        and Referral_Partner_Account__c = :accountId
                                        and (Status__c = 'paid' or Status__c = 'succeeded') // Update vr
                                    order by Payment_Date__c asc
                                    ];

            Datetime earliestPayment;

            if (lstPayments.size() > 0) {
                earliestPayment = lstPayments[0].Payment_Date__c;
                lstMessages.add('found ' + lstPayments.size() + ' Payments: ' + lstPayments);                
            }
            else {
                lstMessages.add('no Payments found');
            }

            // Create Partner Payout Payment
            RecordType rt = [select Id from RecordType where DeveloperName='Partner_Payout' limit 1];

            String paymentNotes = 'Did not meet minimum threshold for quarterly payouts ($200). Payment generated on ' + Datetime.now();
            //lstMessages.add('paymentNotes: ' + paymentNotes);

            // IF(ISBLANK(TEXT({!sobjAccount.RP_Partner_Rev_Share_Payment_Method__c})),"Partner Has Not Submitted Payment Info",TEXT({!sobjAccount.RP_Partner_Rev_Share_Payment_Method__c}))
            String partnerpaymentmethodtext = (String.isBlank(referralPartner.RP_Partner_Rev_Share_Payment_Method__c) ? 'Partner Has Not Submitted Payment Info' : referralPartner.RP_Partner_Rev_Share_Payment_Method__c);
            lstMessages.add('partnerpaymentmethodtext: ' + partnerpaymentmethodtext);

            // payout notes line:
            // "Payout Amount: $" &
            // TEXT({!colPayments.FM_Partner_Payout_Amount__c})&
            // " | Link in SF: https://na51.salesforce.com/"&
            // {!colPayments.Id}
            String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

            // first day of the month that started the prior quarter 
            //
            Integer year = (getCurrentMonth() > 3 ? Date.today().year() : Date.today().addYears(-1).year());
            Map <Integer, Integer> mapMonths = new Map <Integer, Integer> {1=>10, 2=>10, 3=>10, 4=>1, 5=>1, 6=>1, 7=>4, 8=>4, 9=>4, 10=>7, 11=>7, 12=>7};
            Date firstDay = Date.newInstance(year, mapMonths.get(getCurrentMonth()), 1);
    
            Payment__c payment = new Payment__c();
            payment.Name = getPaymentNameFormula(referralPartner.Name);
            payment.Customers_Email_Address__c = referralPartner.RP_Referral_Partner_s_Main_Email__c;
            payment.Account__c = accountId;
            payment.Payment_Date__c = Datetime.now();
            payment.Payment_Type__c = 'Partner Rev Share Payout';
            payment.RecordTypeId = rt.Id;
            lstMessages.add('payment: ' + payment);
            insert payment;

            // Loop through payments
            Decimal amountOwed = 0.0;
            String paymentList = '';
            for (Payment__c p : lstPayments) {
                p.Partner_Payout_Payment__c = payment.Id;

                String pnotesLine = 'Payout Amount: $' + p.FM_Partner_Payout_Amount__c + ' | Link in SF: ' + baseUrl + '/' + p.Id;
                paymentList += pnotesLine + '\n';
                amountOwed += p.FM_Partner_Payout_Amount__c;
                lstMessages.add(pnotesLine);
            }
            payment.Payment_Notes__c = paymentList;

            lstMessages.add('Earliest payment: ' + earliestPayment);
            lstMessages.add('Amount owed: ' + amountOwed);

            if (amountOwed <= 0.0) {
                lstMessages.add('No payment');
                delete payment;
            }
            else if (amountOwed < 200.0 && earliestPayment > firstDay) {

                // eligible update payout payment?
                lstMessages.add('Not eligible for payment');
                payment.Amount__c = amountOwed;
                payment.Method__c = referralPartner.RP_Partner_Rev_Share_Payment_Method__c;
                payment.Name = getUnpaidName(referralPartner.Name);
                payment.Status__c = 'Payout Amount Did Not Meet Minimum Threshold';
                update payment;
            }
            else if (doesNotHavePaymentInfo(referralPartner.RP_Partner_Rev_Share_Payment_Method__c)) {
                // Has payment information?
                lstMessages.add('Does not have payment information');
                payment.Amount__c = amountOwed;
                payment.Name = getUnpaidName(referralPartner.Name);
                payment.Status__c = partnerpaymentmethodtext;
                update payment;
            }
            else {
                // update payments
                update lstPayments;

                // Update payout payment 
                payment.Amount__c = amountOwed;
                payment.Method__c = referralPartner.RP_Partner_Rev_Share_Payment_Method__c;
                payment.Status__c = 'Partner Payment Generated';
                lstMessages.addAll(getEligibilityMessages());
                update payment;
            }
    
            lstMessages.add('completed processing ' + accountId);
        }
        catch (Exception e) {
            lstMessages.addAll(logExceptions('partner payments', e));
        }

        return lstMessages;
    }




    // How does the Influencers One-Time Bounty Calculator Work?
    //
    // Lookup Referral Partner
    //     Grabs ID from the account upon button click
    //     Takes Partners Name, Payment Method & Main Email
    // Lookup Payment Dates from Metadata table
    //     Finds the influencer date
    //     **eliminates the need to update flow every month
    // Lookup Payments
    //     Finds paid payments of non-canceled accounts (MRR != 0) w/ a payout amount above 0 that is associated with the Referral Partner 
    //     Limits payments to those w/ a tagged tier that contains Influencers, Meets the 4-month threshold, and have not already been paid out before (i.e. not tagged w/ a Bounty & within the first 4 months)
    // Create One-Time Bounty
    //     Creates a payment w/ a payment type of Influencers One-time Bounty that will be logged as a partner payout on the RPs account
    // Loop Through Payments
    //     Loops through payments saved in step 3s collection variable, First - Last
    //     Assign Amount and ID   sums the Partner Payout Amount logged on the payment & tags the new bounty created in step 4 onto the payment
    //     Assign Updated Payments  adds payments to a new collection variable once theyve been counted to be updated in later steps
    // Has Payment?
    //     Makes sure that the amount owed (the sum of the partner payout amount) is greater than 0
    //     Delete Payment - 
    //     If above not true, the payment gets deleted (rare)
    // Has Payment Information?
    //     Makes sure the RP has an email & payment method
    //     No Payment Info
    //     Generates a payment w/ an error message
    // Fast Update Payments
    //     Updates the payments in the Updated Payments collection variable (i.e. looped payments) 
    // Update Payout Payment
    //     Updates the amount owed, status, name, email & payment method of the bounty generated
    //
    // Link to Calculator Flow: https://klaviyo.lightning.force.com/builder_platform_interaction/flowBuilder.app?isFromAloha=true&flowId=3010V000001DvJQ
    // sandbox link: https://klaviyo--partialsb.cs68.my.salesforce.com/3000V000001Yaeb
    //
    public static List <String> calculateOneTimeBounty(Id accountId) {
        List <String> lstMessages = new List <String> ();
        lstMessages.add('starting calculateOneTimeBounty on account ID ' + accountId);

        try {

            // Lookup Referral Partners
            Account referralPartner = [select Id, Name, RP_Partner_Rev_Share_Payment_Method__c, RP_Referral_Partner_s_Main_Email__c from Account where Id = :accountId];
            lstMessages.add('selected Referral Partner ' + account.Name);

            // find calc dates from metadata
            List <Payout_Calculator_Dates__mdt> lstPayoutDates = [select Advisors_Prev_Quarter_Date__c, Advisors_Quarterly_Date__c, Influencers_Monthly_Calc_Date__c, Masters_Annual_Date__c from Payout_Calculator_Dates__mdt];

            // lookup payments
            lstMessages.add('looking up payments where:');
            lstMessages.add('Account_MRR_0__c = true' + account.Name);
            lstMessages.add('and FLOW_Payout_Amount_to_Referral_Partner__c like %Influencers%');
            lstMessages.add('and FM_Days_Since_New_Account_Close_Date__c <= 120');
            lstMessages.add('and FM_Partner_Payout_Amount__c > 0');
            lstMessages.add('and Influencer_s_One_Time_Bounty__c = null');
            lstMessages.add('and Meets_4mo_Threshold__c = true');
            lstMessages.add('and Payment_Date__c < ' + lstPayoutDates[0].Influencers_Monthly_Calc_Date__c);
            lstMessages.add('and Status__c = paid or Status__c = succeeded'); //update vr
            List <Payment__c> lstPayments = [
                                    select Id, Amount__c, FM_Partner_Payout_Amount__c, Payment_Date__c 
                                    from Payment__c 
                                    where
                                        Account_MRR_0__c = true
                                        and FLOW_Payout_Amount_to_Referral_Partner__c like '%Influencers%'
                                        and FM_Days_Since_New_Account_Close_Date__c <= 120
                                        and FM_Partner_Payout_Amount__c > 0
                                        and Influencer_s_One_Time_Bounty__c = null
                                        and Meets_4mo_Threshold__c = true
                                        and Payment_Date__c < :lstPayoutDates[0].Influencers_Monthly_Calc_Date__c
                                        and Referral_Partner_Account__c = :accountId
                                        and (Status__c = 'paid' or Status__c = 'succeeded') //update vr
                                    order by Payment_Date__c asc
                                    ];
            if (lstPayments.size() > 0) {
                lstMessages.add('found ' + lstPayments.size() + ' Payments: ' + lstPayments);
            }
            else {
                lstMessages.add('no Payments found');
            }

            // "Payout Amount: $" &
            // TEXT({!colPayments.FM_Partner_Payout_Amount__c})&
            // " | Link in SF: https://na51.salesforce.com/"&
            // {!colPayments.Id}
            String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

            // first day of the month that started the prior quarter 
            //
            Integer year = (getCurrentMonth() > 3 ? Date.today().year() : Date.today().addYears(-1).year());
            Map <Integer, Integer> mapMonths = new Map <Integer, Integer> {1=>10, 2=>10, 3=>10, 4=>1, 5=>1, 6=>1, 7=>4, 8=>4, 9=>4, 10=>7, 11=>7, 12=>7};
            Date firstDay = Date.newInstance(year, mapMonths.get(getCurrentMonth()), 1);
    
            // Create Partner Payout Payment
            RecordType rt = [select Id from RecordType where DeveloperName='Partner_Payout' and SobjectType='Payment__c' limit 1];

            Payment__c payment = new Payment__c();
            payment.Account__c = accountId;
            payment.Payment_Date__c = Datetime.now();
            payment.Payment_Type__c = 'Influencer One-Time Bounty';
            payment.RecordTypeId = rt.Id;
            lstMessages.add('payment: ' + payment);
            insert payment;

            // Loop through payments
            Decimal amountOwed = 0.0;
            String paymentList = '';
            for (Payment__c p : lstPayments) {
                p.Partner_Payout_Payment__c = payment.Id;

                String pnotesLine = 'Payout Amount: $' + p.FM_Partner_Payout_Amount__c + ' | Link in SF: ' + baseUrl + '/' + p.Id;
                paymentList += pnotesLine + '\n';
                amountOwed += p.FM_Partner_Payout_Amount__c;
            }

            lstMessages.add('Amount owed: ' + amountOwed);

            if (amountOwed <= 0.0) {
                lstMessages.add('No payment');
                delete payment;
            }
            else if (doesNotHavePaymentInfo(referralPartner.RP_Partner_Rev_Share_Payment_Method__c)) {
                // Has payment information?
                lstMessages.add('Does not have payment information');
                payment.Amount__c = amountOwed;
                payment.Customers_Email_Address__c = referralPartner.RP_Referral_Partner_s_Main_Email__c;
                payment.Name = getUnpaidName(referralPartner.Name);
                payment.Payment_Notes__c = paymentList;
                payment.Status__c = 'Partner Has Not Submitted Payment Info';
                update payment;
            }
            else {
                // update payments
                update lstPayments;

                // Update payout payment 
                payment.Amount__c = amountOwed;
                payment.Customers_Email_Address__c = referralPartner.RP_Referral_Partner_s_Main_Email__c;
                payment.Method__c = referralPartner.RP_Partner_Rev_Share_Payment_Method__c;
                payment.Name = getPaymentNameFormula(referralPartner.Name);
                payment.Status__c = 'Partner Payment Generated';
                lstMessages.addAll(getEligibilityMessages());
                update payment;
            }

            lstMessages.add('completed processing ' + accountId);
        }
        catch (Exception e) {
            lstMessages.addAll(logExceptions('one-time bounty', e));
        }

        return lstMessages;
    }






    
    // How does the Masters Payment Calculator Work?
    //
    // Pull the following fields from the agency Account record that the Payment Calculator was run on and store in Variable Record
    //     Account ID
    //     Account Name
    //     Accounts Rev Share Payment Method
    //     Accounts Referral Partner Main Email
    //     Accounts Experts Tier
    // Get Metadata table Payout Calculator Date: https://klaviyo.my.salesforce.com/01I0V000002N5Fs?setupid=CustomMetadata
    //     Get Masters Annual Date
    // Create Payment on the Agency Account with the following information: 
    //     Account = Agency Account
    //     Payment Date = Now
    //     Payment Type = Masters Partner Rev Share Payout
    //     Record Type Id = 0120V000001pNjV
    // Pull the following fields from Account Object where the following criteria is true: 
    //     Experts Partner Account = Agency Account Id
    //     Agency Retainer Status = Active 
    // Store following values in Variable Record
    //     ID
    //     Experts Partner Account
    //     Agency Retainer Status
    // Loop through Accounts
    //     Sets counting variable Total Opp Amt = 0 
    // Pull the following fields from Opportunity Object where the following criteria is true:
    //     Account Id = Loop Accounts ID
    //     Close Date < Metadata Tables  Masters Annual Date
    // Stores following values in variable record
    //     Id
    //     Amount
    //     Close Date
    //     AccountId
    // Loop Through Opps
    //     Loops through opps found above and sums the total opportunity amount within the time period of the Masters Annual Date
    //     Assigns total Opps amount to a variable to total all opp amount for all accounts being managed by this agency
    // If no MRR was found that relate to the agency Account, delete the Payment that was created in step 3
    // If the Partner has a Payment Method indicated, the Payment is updated with the following information
    //         Final Amount totaled on the Payment
    //         Referral Partners Email Address is added
    //         Payment Method is added
    //         Payment Name is added
    //         {Partner Name} Advisors Payout Payment: 20XX - QX
    //     Status = Payment Generated
    // If the Partner does not have a Payment Method indicated, the Payment is updated similarly to step 7 except:
    //     Payment Name indicates Non Payment
    //     No Payment: {Partner Name} Payout Payment: 20XX - QX
    //     Status = Partner Has Not Submitted Payment Info 
    // Update Payout Payment
    //     Updates the amount owed, status, name, email & payment method of the payment created in step 3
    //
    // Link to Calculator Flow: https://klaviyo.lightning.force.com/builder_platform_interaction/flowBuilder.app?isFromAloha=true&flowId=3010V000001DvJR
    // sandbox: https://klaviyo--partialsb.lightning.force.com/builder_platform_interaction/flowBuilder.app?isFromAloha=true&flowDefId=3000V000001YaQP&flowId=3010V000001DvJRQA0
    
    public static List <String> calculateMastersPayment(Id accountId) {
        List <String> lstMessages = new List <String> ();
        lstMessages.add('starting calculateMastersPayment on account ID ' + accountId);

        try {

            // IF(
            // ISPICKVAL({!sobjAccount.Experts_Tier__c}, "Silver"),
            // {!TotalMRRofAcct}*0.02,
            // IF(ISPICKVAL({!sobjAccount.Experts_Tier__c}, "Gold"),
            // {!TotalMRRofAcct}*0.03,
            // IF(ISPICKVAL({!sobjAccount.Experts_Tier__c}, "Platinum"),
            // {!TotalMRRofAcct}*0.04, 
            // NULL)))
            Map <String, Decimal> mapFMManagedPayoutAmt = new Map <String, Decimal> {'Silver'=>0.02, 'Gold'=>0.03, 'Platinum'=>0.04};

            // Lookup Referral Partners
            Account referralPartner = 
                [
                    select Id, Name, RP_Partner_Rev_Share_Payment_Method__c, RP_Referral_Partner_s_Main_Email__c, Experts_Tier__c, FM_Salesforce_Account_ID__c 
                    from Account 
                    where 
                        Id = :accountId 
                        and Experts_Tier__c in :mapFMManagedPayoutAmt.keySet()
                ];
            lstMessages.add('selected Referral Partner Account: ' + referralPartner.Name);

            // Get metadata table
            List <Payout_Calculator_Dates__mdt> lstPayoutDates = [select Advisors_Prev_Quarter_Date__c, Advisors_Quarterly_Date__c, Influencers_Monthly_Calc_Date__c, Masters_Annual_Date__c from Payout_Calculator_Dates__mdt];
            lstMessages.add('Masters Annual Date: ' + lstPayoutDates[0].Masters_Annual_Date__c);

            // List <Partner_Program_Information__c> lstPPI = [select Id, Account__c from Partner_Program_Information__c where Masters_SOW_Agreement_End_Date__c = :Date.today()];

            List <Account> lstAccounts = 
                [
                    select 
                        Id, Name, Experts_Partner_Account__c, RP_Agency_Experts_Accounts_Status__c,
                        (select Id, Amount, CloseDate, AccountId
                         from Opportunities
                         where CloseDate < :lstPayoutDates[0].Masters_Annual_Date__c.date() and Amount <> null)
                    from Account 
                    where 
                        Experts_Partner_Account__c = :accountId 
                        and RP_Agency_Experts_Accounts_Status__c = 'Active' 
                ];

            lstMessages.add('found ' + lstAccounts.size() + ' related accounts where RP_Agency_Experts_Accounts_Status__c = Active');

            Decimal totalMRRofAccount = 0.0;
            for (Account a : lstAccounts) {
                lstMessages.add('account ' + a.Name + ' has ' + a.Opportunities.size() + ' Opportunities');
                for (Opportunity o : a.Opportunities) {
                    totalMRRofAccount += o.Amount;
                }
            }
            if (totalMRRofAccount <= 0.0) {
                lstMessages.add('Total Opportunities amount is zero, not creating payment');
            }
            else {
                Decimal fmManagedPayoutAmt = mapFMManagedPayoutAmt.get(referralPartner.Experts_Tier__c) * totalMRRofAccount;

                // IF(ISBLANK(TEXT({!sobjAccount.RP_Partner_Rev_Share_Payment_Method__c})),"Partner Has Not Submitted Payment Info",TEXT({!sobjAccount.RP_Partner_Rev_Share_Payment_Method__c}))
                String partnerpaymentmethodtext = (String.isBlank(referralPartner.RP_Partner_Rev_Share_Payment_Method__c) ? 'Partner Has Not Submitted Payment Info' : referralPartner.RP_Partner_Rev_Share_Payment_Method__c);
                lstMessages.add('partnerpaymentmethodtext: ' + partnerpaymentmethodtext);

                lstMessages.add('Total Opportunities amount: ' + totalMRRofAccount);
                // Create Partner Payout Payment
                RecordType rt = [select Id from RecordType where DeveloperName='Partner_Payout' limit 1];
                Payment__c payment = new Payment__c();
                payment.Account__c = accountId;
                payment.Payment_Date__c = Datetime.now();
                payment.Payment_Type__c = 'Masters Partner Rev Share Payout';
                payment.RecordTypeId = rt.Id;
                payment.Amount__c = fmManagedPayoutAmt;
                payment.Customers_Email_Address__c = referralPartner.RP_Referral_Partner_s_Main_Email__c;
                lstMessages.add('created payment: ' + payment);

                if (doesNotHavePaymentInfo(referralPartner.RP_Partner_Rev_Share_Payment_Method__c)) {
                    // Has payment information?
                    lstMessages.add('Does not have payment information');
                    payment.Name = getUnpaidName(referralPartner.Name);
                    payment.Status__c = partnerpaymentmethodtext;
                    insert payment;
                }
                else {
                    lstMessages.add('Has payment information');
                    payment.Method__c = referralPartner.RP_Partner_Rev_Share_Payment_Method__c;
                    payment.Name = getPaymentNameFormula(referralPartner.Name);
                    payment.Status__c = 'Partner Payment Generated';
                    lstMessages.add('Partner Payment Generated');
                    insert payment;
                }
            }

            lstMessages.add('completed processing ' + accountId);
        }
        catch (Exception e) {
            lstMessages.addAll(logExceptions('partner payments', e));
        }

        return lstMessages;
    }

    @testVisible
    private static List<String> getEligibilityMessages() {
        String msg0 = 'Updating payments';
        String msg1 = 'Eligible for payment';
        String msg2 = 'Has payment information';
        String msg3 = 'Partner Payment Generated';

        List<String> messages = new LIst<String>();
        messages.add(msg0);
        messages.add(msg1);
        messages.add(msg2);
        messages.add(msg3);

        return messages;
    }

    @testVisible
    private static List<String> logExceptions(String action, Exception e) {
        List<String> exceptionMessages = new List<String>();

        String exception1 = 'Exception while calculating ';
        exception1 += action;
        exception1 += ' : ';
        exception1 += e.getMessage();

        String exception2 = 'Stack trace: ';
        exception2 += e.getStackTraceString();

        exceptionMessages.add(exception1);
        exceptionMessages.add(exception2);

        return exceptionMessages;
    }

    private static Boolean doesNotHavePaymentInfo(String paymentMethod) {
        return paymentMethodOverride != null ? paymentMethodOverride : String.isBlank(paymentMethod) || paymentMethod == 'Payment information incorrect - reaching out';
    }

    private static Integer getCurrentMonth() {
        if (monthOverride != null) {
            return monthOverride;
        }

        return Date.today().month();
    }
}
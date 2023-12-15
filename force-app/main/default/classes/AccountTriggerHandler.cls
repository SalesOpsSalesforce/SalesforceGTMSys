/* *********
*  Date:            1/2020
*  Description:     Handler to update Account for trigger actions
*  Developer:   OpFocus
* *********/
public with sharing class AccountTriggerHandler extends TriggerHandler {

    @TestVisible private static Boolean isFirstTimeUpdate = true;
    @testVisible private static Boolean overrideHasReferralPartnerPayments = false;
    @testVisible private static Boolean overrideReferralPartnerPayments = false;
    @testVisible private static Boolean overrideMapAccount = false;

    private List<Account> triggerNew = (Account[]) Trigger.new;
    private List<Account> triggerOld = (Account[]) Trigger.old;
    private Map<Id, Account> triggerNewmap = (Map<Id, Account>) Trigger.newMap;
    private Map<Id, Account> triggerOldmap = (Map<Id, Account>) Trigger.oldMap;

    // ----------- OVERRIDE METHODS ----------------
    
    public override void afterInsert()
    {
        alexaRankUpdate(Trigger.new); 
    }
    
    public override void afterUpdate()
    {
        if (isFirstTimeUpdate) {
            runPaymentCalculators();
            isFirstTimeUpdate = false;
        }

    }

    public override void beforeInsert() {
        linkToKPU();
    }

    public override void beforeUpdate() {
        linkToKPU();
    }

    // ----------- PRIVATE METHODS ----------------

    private void runPaymentCalculators() {

        List <Id> lstAccountIds = new List <Id> ();
        for (Account a : triggerNew) {
            if (a.Trigger_Partner_Payout_Payment_New__c && triggerOldmap.get(a.Id).Trigger_Partner_Payout_Payment_New__c == false) {
                lstAccountIds.add(a.Id);
            }
        }

        if (lstAccountIds.size() > 0) {

            List <Account> lstPaymentAccounts = [
                                    select Id, Name, RP_Partner_Rev_Share_Payment_Method__c, RP_Referral_Partner_s_Main_Email__c,
                                        (
                                        select Id, Amount__c, FM_Partner_Payout_Amount__c, Payment_Date__c 
                                        from RefferalPartnerPayments__r
                                        where
                                            Account_MRR_0__c = true
                                            and FLOW_Payout_Amount_to_Referral_Partner__c not in :setFlowAmounts
                                            and FM_Partner_Payout_Amount__c > 0
                                            and Partner_Payout_Payment__c = null
                                            and Payment_Date__c < :lstPayoutDates[0].Advisors_Quarterly_Date__c
                                            //and Referral_Partner_Account__c = :accountId
                                            and (Status__c = 'paid' or Status__c = 'succeeded') //update vr
                                        order by Payment_Date__c asc
                                        ) 
                                    from Account
                                    where Id in :lstAccountIds
                                    order by Name
                                    ];

            calculatePartnerPayments(lstPaymentAccounts);


            List <Account> lstOneTimeAccounts = [
                                    select Id, Name, RP_Partner_Rev_Share_Payment_Method__c, RP_Referral_Partner_s_Main_Email__c,
                                        (
                                        select Id, Amount__c, FM_Partner_Payout_Amount__c, Payment_Date__c 
                                        from RefferalPartnerPayments__r 
                                        where
                                            Account_MRR_0__c = true
                                            and FLOW_Payout_Amount_to_Referral_Partner__c like '%Influencers%'
                                            and FM_Days_Since_New_Account_Close_Date__c <= 120
                                            and FM_Partner_Payout_Amount__c > 0
                                            and Influencer_s_One_Time_Bounty__c = null
                                            and Meets_4mo_Threshold__c = true
                                            and Payment_Date__c < :lstPayoutDates[0].Influencers_Monthly_Calc_Date__c
                                            and Referral_Partner_Account__c in :triggerNewmap.keySet()
                                            and (Status__c = 'paid' or Status__c = 'succeeded') //update vr
                                        order by Payment_Date__c asc
                                        )
                                    from Account
                                    where Id in :lstAccountIds
                                    order by Name
                                    ];

            calculateOneTimeBounty(lstOneTimeAccounts);


            Map <Id, Account> mapAccounts = new Map <Id, Account> ();
            for (Account a : triggerNew) {
                if (String.isNotBlank(a.Experts_Tier__c) && mapFMManagedPayoutAmt.keySet().contains(a.Experts_Tier__c)) {
                    mapAccounts.put(a.Id, a);
                }
            }
            if (mapAccounts.keySet().size() > 0) {
                calculateMastersPayment(mapAccounts);
            }

        }
    }


    // Get metadata table
    public static List <Payout_Calculator_Dates__mdt> lstPayoutDates = [select Advisors_Prev_Quarter_Date__c, Advisors_Quarterly_Date__c, Influencers_Monthly_Calc_Date__c, Masters_Annual_Date__c from Payout_Calculator_Dates__mdt];

    public static RecordType rt = [select Id from RecordType where DeveloperName='Partner_Payout' and SobjectType='Payment__c' limit 1];

    public static String getUnpaidName(String accountName) {
        String unpaidName = 'No Payment: ' + accountName + ' Payout Payment: ';
        unpaidName += (Date.today().month() > 2 ? Date.today().year() : Date.today().addYears(-1).year());
        unpaidName += ' - ';
        if (Date.today().month() < 6) {
            unpaidName += Date.today().month() < 3 ? 'Q4' : 'Q1';
        }
        else {
            unpaidName += Date.Today().month() < 9 ? 'Q2' : 'Q3';
        }
        return unpaidName;
    }

    public static String getPaymentNameFormula(String accountName) {
        String paymentNameFormula = accountName + ' Advisors Payout Payment: ' ;
        paymentNameFormula += (Date.today().month() > 2 ? Date.today().year() : Date.today().addYears(-1).year());
        paymentNameFormula += ' - ';
        if (Date.today().month() < 6) {
            paymentNameFormula += Date.today().month() < 3 ? 'Q4' : 'Q1';
        }
        else {
            paymentNameFormula += Date.Today().month() < 9 ? 'Q2' : 'Q3';
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

    public static Set <String> setFlowAmounts = new Set <String> {
                                        'Yes - Influencers Silver - 5%',
                                        'Yes - Influencers Gold - 10%',
                                        'Yes - Influencers Platinum - 15%',
                                        'Attributed to Agency, No Payment'
                                    };

    public static String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

    // first day of the month that started the prior quarter 
    //
    public static Integer year = (Date.today().month() > 3 ? Date.today().year() : Date.today().addYears(-1).year());
    public static Map <Integer, Integer> mapMonths = new Map <Integer, Integer> {1=>10, 2=>10, 3=>10, 4=>1, 5=>1, 6=>1, 7=>4, 8=>4, 9=>4, 10=>7, 11=>7, 12=>7};
    public static Date firstDay = Date.newInstance(year, mapMonths.get(Date.today().month()), 1);

    public static List <String> calculatePartnerPayments(List <Account> lstAccounts) {
        List <String> lstMessages = new List <String> ();
        System.debug(LoggingLevel.INFO, '=========>>>> calculatePartnerPayments, lstAccounts: '+lstAccounts);

        List <Payment__c> lstInsertPayments = new List <Payment__c> ();
        Map <Id, Payment__c> mapAccountIdPayment = new Map <Id, Payment__c> ();

        for (Account a : lstAccounts) {
            System.debug(LoggingLevel.INFO, '=========>>>> calculatePartnerPayments, account: '+a);
            System.debug(LoggingLevel.INFO, '=========>>>> calculatePartnerPayments, RefferalPartnerPayments__r: '+a.RefferalPartnerPayments__r);

            Datetime earliestPayment;

            if (hasReferralPartnerPayments(a.RefferalPartnerPayments__r)) {
                earliestPayment = getFirstPaymentDate(a.RefferalPartnerPayments__r);
                System.debug(LoggingLevel.INFO, 'found ' + a.RefferalPartnerPayments__r.size() + ' Payments: ' + a.RefferalPartnerPayments__r);                
            }
            else {
                continue;
                System.debug(LoggingLevel.INFO, 'no Payments found');
            }

            // Create Partner Payout Payment
            //RecordType rt = [select Id from RecordType where DeveloperName='Partner_Payout' limit 1];

            String paymentNotes = 
                'Did not meet minimum threshold for quarterly payouts ($200). Payment generated on '
                + Datetime.now();
            //System.debug(LoggingLevel.INFO, 'paymentNotes: ' + paymentNotes);

            // IF(ISBLANK(TEXT({!sobjAccount.RP_Partner_Rev_Share_Payment_Method__c})),"Partner Has Not Submitted Payment Info",TEXT({!sobjAccount.RP_Partner_Rev_Share_Payment_Method__c}))
            String partnerpaymentmethodtext = (String.isBlank(a.RP_Partner_Rev_Share_Payment_Method__c) ? 'Partner Has Not Submitted Payment Info' : a.RP_Partner_Rev_Share_Payment_Method__c);
            System.debug(
                LoggingLevel.INFO,
                'partnerpaymentmethodtext: '
                    + partnerpaymentmethodtext);

            // payout notes line:
            // "Payout Amount: $" &
            // TEXT({!colPayments.FM_Partner_Payout_Amount__c})&
            // " | Link in SF: https://na51.salesforce.com/"&
            // {!colPayments.Id}
    
            Payment__c payment = new Payment__c();
            payment.Name = getPaymentNameFormula(a.Name);
            payment.Customers_Email_Address__c = a.RP_Referral_Partner_s_Main_Email__c;
            payment.Account__c = a.Id;
            payment.Payment_Date__c = Datetime.now();
            payment.Payment_Type__c = 'Partner Rev Share Payout';
            payment.RecordTypeId = rt.Id;
            System.debug(LoggingLevel.INFO, 'payment: ' + payment);
            lstInsertPayments.add(payment);
            mapAccountIdPayment.put(a.Id, payment);
        }

        insert lstInsertPayments;
        List <Payment__c> lstUpdatePayments = new List <Payment__c> ();
        List <Payment__c> lstDeletePayments = new List <Payment__c> ();

        for (Account a : lstAccounts) {
            Payment__c payment = mapAccountIdPayment.get(a.Id);
            if (payment == null) {
                continue;
            }

            // Loop through payments
            Decimal amountOwed = 0.0;
            String paymentList = '';
            Datetime earliestPayment = getFirstPaymentDate(a.RefferalPartnerPayments__r);
            for (Payment__c p : getReferralPartnerPayments(a)) {
                String pnotesLine = 'Payout Amount: $' + getFMPartnerPayoutAmount(p) + ' | Link in SF: ' + baseUrl + '/' + p.Id;
                paymentList += pnotesLine + '\n';
                amountOwed += getFMPartnerPayoutAmount(p);
                System.debug(LoggingLevel.INFO, pnotesLine);
            }

            System.debug(LoggingLevel.INFO, 'Earliest payment: ' + earliestPayment);
            System.debug(LoggingLevel.INFO, 'Amount owed: ' + amountOwed);

            if (amountOwed <= 0.0) {
                System.debug(LoggingLevel.INFO, 'No payment');
                lstDeletePayments.add(new Payment__c(Id=payment.Id));
            }
            else if (amountOwed < 200.0 && earliestPayment > firstDay) {

                // eligible update payout payment?
                System.debug(LoggingLevel.INFO, 'Not eligible for payment');
                payment.Amount__c = amountOwed;
                payment.Method__c = a.RP_Partner_Rev_Share_Payment_Method__c;
                payment.Name = getUnpaidName(a.Name);
                payment.Status__c = 'Payout Amount Did Not Meet Minimum Threshold';
                payment.Payment_Notes__c = paymentList;
                lstUpdatePayments.add(payment);
            }
            else if (String.isBlank(a.RP_Partner_Rev_Share_Payment_Method__c) || a.RP_Partner_Rev_Share_Payment_Method__c == 'Payment information incorrect - reaching out') {
                // Has payment information?
                System.debug(LoggingLevel.INFO, 'Does not have payment information');
                payment.Amount__c = amountOwed;payment.Name = getUnpaidName(a.Name); payment.Status__c = 'Partner Has Not Submitted Payment Info';payment.Payment_Notes__c = paymentList;
                lstUpdatePayments.add(payment);
            }
            else {
                // update payments
                System.debug(LoggingLevel.INFO, 'updating Payments');
                for (Payment__c p : a.RefferalPartnerPayments__r) {
                    lstUpdatePayments.add(new Payment__c(Id=p.Id, Partner_Payout_Payment__c = payment.Id));
                }

                // Update payout payment 
                System.debug(LoggingLevel.INFO, 'Eligible for payment');
                System.debug(LoggingLevel.INFO, 'Has payment information');
                payment.Amount__c = amountOwed;payment.Method__c = a.RP_Partner_Rev_Share_Payment_Method__c;payment.Status__c = 'Partner Payment Generated';
                System.debug(LoggingLevel.INFO, 'Partner Payment Generated');
                lstUpdatePayments.add(payment);
            }
        }            

        //[RGaokar 2/7/2023 SFDC-1778 Payment record synchrounous update throwing apex cpu timeout error for large number of payment records. So using asynchronous call for payment records >200]
        if (lstUpdatePayments.size() > 0) {
            if(lstUpdatePayments.size() <= 200 && !Test.isRunningTest()){
                update lstUpdatePayments; 
            }else{
                system.enqueueJob(new PaymentUpdateProcessor(lstUpdatePayments));
            }
        }

        if (lstDeletePayments.size() > 0) {
            delete lstDeletePayments;
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
    public static List <String> calculateOneTimeBounty(List <Account> lstAccounts) {
        List <String> lstMessages = new List <String> ();

        List <Payment__c> lstInsertPayments = new List <Payment__c> ();
        Map <Id, Payment__c> mapAccountIdPayment = new Map <Id, Payment__c> ();

        for (Account a : lstAccounts) {
            List<Payment__c> referralPartnerPayments = getReferralPartnerPayments(a);
            if (referralPartnerPayments.size() > 0) {
                lstMessages.add('found ' + referralPartnerPayments.size() + ' Payments: ' + referralPartnerPayments);
            }
            else {
                continue;
            }

            // first day of the month that started the prior quarter 
            //
            Integer year = (Date.today().month() > 3 ? Date.today().year() : Date.today().addYears(-1).year());
            Map <Integer, Integer> mapMonths = new Map <Integer, Integer> {1=>10, 2=>10, 3=>10, 4=>1, 5=>1, 6=>1, 7=>4, 8=>4, 9=>4, 10=>7, 11=>7, 12=>7};
            Date firstDay = Date.newInstance(year, mapMonths.get(Date.today().month()), 1);
    
            // Create Partner Payout Payment
            //RecordType rt = [select Id from RecordType where DeveloperName='Partner_Payout' and SobjectType='Payment__c' limit 1];

            Payment__c payment = new Payment__c();
            payment.Account__c = a.Id;
            payment.Payment_Date__c = Datetime.now();
            payment.Payment_Type__c = 'Influencer One-Time Bounty';
            payment.RecordTypeId = rt.Id;

            lstInsertPayments.add(payment);
            mapAccountIdPayment.put(a.Id, payment);
        }

        insert lstInsertPayments;
        List <Payment__c> lstUpdatePayments = new List <Payment__c> ();
        List <Payment__c> lstDeletePayments = new List <Payment__c> ();

        for (Account a : lstAccounts) {
            Payment__c payment = mapAccountIdPayment.get(a.Id);
            if (payment == null) {
                continue;
            }

            Decimal amountOwed = 0.0;
            String paymentList = '';
            List<Payment__c> referralPartnerPayments = getReferralPartnerPayments(a);
            for (Payment__c p : referralPartnerPayments) {
                p.Influencer_s_One_Time_Bounty__c = payment.Id;

                String pnotesLine = 'Payout Amount: $' + getFMPartnerPayoutAmount(p) + ' | Link in SF: ' + baseUrl + '/' + p.Id;
                paymentList += pnotesLine + '\n';
                amountOwed += getFMPartnerPayoutAmount(p);
            }

            lstMessages.add('Amount owed: ' + amountOwed);

            if (amountOwed <= 0.0) {
                lstMessages.add('No payment');
                lstDeletePayments.add(payment);
            }
            else if (String.isBlank(a.RP_Partner_Rev_Share_Payment_Method__c) || a.RP_Partner_Rev_Share_Payment_Method__c == 'Payment information incorrect - reaching out') {
                // Has payment information?
                lstMessages.add('Does not have payment information');
                payment.Amount__c = amountOwed;
                payment.Customers_Email_Address__c = a.RP_Referral_Partner_s_Main_Email__c;
                payment.Name = getUnpaidName(a.Name);
                payment.Payment_Notes__c = paymentList;
                payment.Status__c = 'Partner Has Not Submitted Payment Info';
                lstUpdatePayments.add(payment);
            }
            else {
                // update payments
                lstMessages.add('updating Payments');
                for (Payment__c p : a.RefferalPartnerPayments__r) {
                    lstUpdatePayments.add(new Payment__c(Id=p.Id, Influencer_s_One_Time_Bounty__c = payment.Id));
                }

                // Update payout payment 
                lstMessages.add('Eligible for payment');
                lstMessages.add('Has payment information');
                payment.Amount__c = amountOwed;
                payment.Customers_Email_Address__c = a.RP_Referral_Partner_s_Main_Email__c;
                payment.Method__c = a.RP_Partner_Rev_Share_Payment_Method__c;
                payment.Name = getPaymentNameFormula(a.Name);
                payment.Status__c = 'Partner Payment Generated';
                lstMessages.add('Partner Payment Generated');
                lstUpdatePayments.add(payment);
            }
        }

        try {
        update lstUpdatePayments;
        delete lstDeletePayments;
        }
        catch (Exception e) {
            system.debug('error');
            system.debug(e.getMessage());
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

    public static Map <String, Decimal> mapFMManagedPayoutAmt = new Map <String, Decimal> {'Klaviyo Partner'=>0.02, 'Silver'=>0.02, 'Gold'=>0.03, 'Platinum'=>0.04, 'Elite'=>0.04};//[RGaokar 09/15/2022 SFDC-785 Added 'Klaviyo Partner'=>0.02]//[RGaokar 04/17/2023 SFDC-2256 Added 'Elite'=>0.04]

    public static List <String> calculateMastersPayment(Map <Id, Account> mapAccounts) {
        List <String> lstMessages = new List <String> ();

        List <Account> lstPartnerAccounts = 
            [
                select 
                    Id, Name, Experts_Partner_Account__c, RP_Agency_Experts_Accounts_Status__c,
                    (select Id, Amount, CloseDate, AccountId
                    from Opportunities
                    where CloseDate < :lstPayoutDates[0].Masters_Annual_Date__c.date() and Amount <> null AND StageName =: 'Closed Won')
                from Account
                where 
                    Experts_Partner_Account__c in :mapAccounts.keySet() 
                    and RP_Agency_Experts_Accounts_Status__c = 'Active' 
            ];

        Map <Id, List <Account>> mapAccountIdPartnerAccounts = new Map <Id, List <Account>> ();
        for (Account a : lstPartnerAccounts) {
            mapAccountIdPartnerAccounts.put(a.Experts_Partner_Account__c, new List <Account> ());
        }
        for (Account a : lstPartnerAccounts) {
            List <Account> lstPartAcc = getMapAccount(mapAccountIdPartnerAccounts, a.Experts_Partner_Account__c);
            lstPartAcc.add(a);
        }

        List <Payment__c> lstInsertPayments = new List <Payment__c> ();

        for (Account a : mapAccounts.values()) {
            Decimal totalMRRofAccount = 0.0;
            List <Account> lstPartAcc = mapAccountIdPartnerAccounts.get(a.Id);
            if (lstPartAcc == null || lstPartAcc.size() < 1) {
                continue;
            }

            for (Account pa : lstPartAcc) {
                lstMessages.add('account ' + pa.Name + ' has ' + pa.Opportunities.size() + ' Opportunities');
                for (Opportunity o : pa.Opportunities) {
                    totalMRRofAccount += o.Amount;
                }
            }
            if (totalMRRofAccount <= 0.0) {
                lstMessages.add('Total Opportunities amount is zero, not creating payment');
            }
            else {
                Decimal fmManagedPayoutAmt = mapFMManagedPayoutAmt.get(a.Experts_Tier__c) * totalMRRofAccount;

                // IF(ISBLANK(TEXT({!sobjAccount.RP_Partner_Rev_Share_Payment_Method__c})),"Partner Has Not Submitted Payment Info",TEXT({!sobjAccount.RP_Partner_Rev_Share_Payment_Method__c}))
                String partnerpaymentmethodtext = (String.isBlank(a.RP_Partner_Rev_Share_Payment_Method__c) ? 'Partner Has Not Submitted Payment Info' : a.RP_Partner_Rev_Share_Payment_Method__c);
                lstMessages.add('partnerpaymentmethodtext: ' + partnerpaymentmethodtext);

                lstMessages.add('Total Opportunities amount: ' + totalMRRofAccount);
                // Create Partner Payout Payment
                //RecordType rt = [select Id from RecordType where DeveloperName='Partner_Payout' limit 1];
                Payment__c payment = new Payment__c();
                payment.Account__c = a.Id;
                payment.Payment_Date__c = Datetime.now();
                payment.Payment_Type__c = 'Masters Partner Rev Share Payout';
                payment.RecordTypeId = rt.Id;
                payment.Amount__c = fmManagedPayoutAmt;
                payment.Customers_Email_Address__c = a.RP_Referral_Partner_s_Main_Email__c;
                lstMessages.add('created payment: ' + payment);

                if (String.isBlank(a.RP_Partner_Rev_Share_Payment_Method__c) || a.RP_Partner_Rev_Share_Payment_Method__c == 'Payment information incorrect - reaching out') {
                    // Has payment information?
                    lstMessages.add('Does not have payment information');
                    payment.Name = getUnpaidName(a.Name);
                    payment.Status__c = partnerpaymentmethodtext;
                }
                else {
                    lstMessages.add('Has payment information');
                    payment.Method__c = a.RP_Partner_Rev_Share_Payment_Method__c;
                    payment.Name = getPaymentNameFormula(a.Name);
                    payment.Status__c = 'Partner Payment Generated';
                    lstMessages.add('Partner Payment Generated');
                }
                lstInsertPayments.add(payment);
            }
        }

        if (lstInsertPayments.size() > 0) {
            insert lstInsertPayments;
        }

        return lstMessages;
    }

    private static DateTime getFirstPaymentDate(List<Payment__c> items) {
        if (overrideHasReferralPartnerPayments) {
            return DateTime.now();
        } else {
            return items[0].Payment_Date__c;
        }
    }

    private static Decimal getFMPartnerPayoutAmount(Payment__c payment) {
        if (overrideReferralPartnerPayments) {
            return 2;
        } else {
            return payment.FM_Partner_Payout_Amount__c;
        }
    }

    private static List<Payment__c> getReferralPartnerPayments(Account a) {
        List<Payment__c> payments = new List<Payment__c>();
        Payment__c payment = new Payment__c();
        payments.add(payment);
        if (overrideReferralPartnerPayments) {
            return payments;
        } else {
            return a.RefferalPartnerPayments__r;
        }
    }

    private static Boolean hasReferralPartnerPayments(List<Object> items) {
        if (overrideHasReferralPartnerPayments)  {
            return true;
        } else {
            return items != null && !items.isEmpty();
        }
    }

    private static List<Account> getMapAccount(Map<Id, List<Account>> acctMap, Id value) {
        if (overrideMapAccount) {
            return new List<Account> {new Account()};
        } else {
            return acctMap.get(value);
        }
    }

    // When an Account is created with a non-blank Klaviyo_Account_Id__c or a Account is updated and its Product_Klaviyo_Account_ID__c is changed and is non-blank, a trigger should:
    //   Create a Klaviyo Product Usage record with that Klaviyo Account Id if one does not already exist.
    //   Update the Account to set its Klaviyo Product Usage field to look up to the new or existing record.
    private void linkToKPU() {

        // If this functionality is disabled, don't do it
        if (TriggerDisablementSwitchHelper.isDisabled('Klaviyo_Product_Usage_Creation_Triggers')) {
            return;
        }

        List<Account> lstProcess = new List<Account>();
        Set<String> kaIds = new Set<String>();
        for(Account a : triggerNew) {
            if(a.Product_Klaviyo_Account_ID__c != null &&
                    (Trigger.isInsert ||
                            (Trigger.isUpdate && triggerOldmap.get(a.Id).Product_Klaviyo_Account_ID__c != a.Product_Klaviyo_Account_ID__c))){
                lstProcess.add(a);
                kaIds.add(a.Product_Klaviyo_Account_ID__c);
            }
        }

        if(lstProcess.isEmpty()) return;

        // find existing KPU records
        Klaviyo_Product_Usage__c[] lstKPU = [Select Id, Klaviyo_Account_ID__c from Klaviyo_Product_Usage__c where Klaviyo_Account_ID__c in :kaIds];
        Map<String, Klaviyo_Product_Usage__c> mapKPU = new Map<String, Klaviyo_Product_Usage__c>();
        for(Klaviyo_Product_Usage__c kpu : lstKPU) {
            mapKPU.put(kpu.Klaviyo_Account_ID__c, kpu);
            kaIds.remove(kpu.Klaviyo_Account_ID__c);
        }

        // now the only KPU keys left are ones that don't exist. Insert the new records
        List<Klaviyo_Product_Usage__c> newKPUS = new List<Klaviyo_Product_Usage__c>();
        for(String ka : kaIds) {
            Klaviyo_Product_Usage__c kpu = new Klaviyo_Product_Usage__c();
            kpu.Klaviyo_Account_ID__c = ka;
            mapKPU.put(kpu.Klaviyo_Account_ID__c, kpu);
            newKPUS.add(kpu);
        }
        insert newKPUS;

        // link the KPU record to the account
        for(Account a : lstProcess) {
            Klaviyo_Product_Usage__c kpu = mapKPU.get(a.Product_Klaviyo_Account_ID__c);
            if(kpu == null) continue;
            a.Klaviyo_Product_Usage__c = kpu.Id;
        }
    }
    
     //[RGaokar 11/12/2021 TP #90961] Alexa api bulk callout optimization, this TP is for bulkification of original code for future method and callouts 
    //During account insertion if website is not blank then update etailinsights_Alexa_Rank__c, Alexa_Rank_at_Last_Owner_Change__c on the account.
    public static void alexaRankUpdate(List<Account> newAccList){
        Set <Id> accIds = new Set<Id>();
        for(Account a:newAccList){
            if(a.Website <> Null){
                   accIds.add(a.id);
            }
        }
        
        if(accIds.size() > 0 && !System.isBatch() && !System.isFuture()){
            system.debug('accIds.size()--'+ accIds.size());
            //Process bulk callouts
            //Database.executeBatch(new AlexaRankBatch(accIds, 'Account'), 50);//[RGaokar 08/10/2022 SFDC-608 Apex job holding - Shutting down batch jobs from trigger]
        } 
    }
    
}
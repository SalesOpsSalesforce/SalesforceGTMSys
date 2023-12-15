public with sharing class PaymentCalculatorController {


    public Opportunity theopp {public get; public set;}
    public List <String> output {public get; public set;}

    public Opportunity theopp2 {public get; public set;}
    public List <String> output2 {public get; public set;}

    public Opportunity theopp3 {public get; public set;}
    public List <String> output3 {public get; public set;}

    public PaymentCalculatorController() {
        theopp = new Opportunity();
        theopp2 = new Opportunity();
        theopp3 = new Opportunity();
    }

    public Pagereference calculatePartnerPayments() {
        if (theopp.AccountId != null) {
            output = PartnerPayment.calculatePartnerPayments(theopp.AccountId);
        }
        else {
            output = new List <String> {'please select an Account to process'};
        }
        return null;
    }

    public Pagereference calculateOneTimeBounty() {
        if (theopp2.AccountId != null) {
            output2 = PartnerPayment.calculateOneTimeBounty(theopp2.AccountId);
        }
        else {
            output2 = new List <String> {'please select an Account to process'};
        }
        return null;
    }

    public Pagereference calculateMastersPayment() {
        if (theopp3.AccountId != null) {
            output3 = PartnerPayment.calculateMastersPayment(theopp3.AccountId);
        }
        else {
            output3 = new List <String> {'please select an Account to process'};
        }
        return null;
    }

}
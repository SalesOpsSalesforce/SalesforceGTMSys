/* *********
*  Date:        06/16/2022
*  Description: Handler to update Contract__c for trigger actions
*  Developer:   RGaokar
* *********/
public class ContractsTriggerHandler extends TriggerHandler {
    @TestVisible private List<Contract__c> triggerNew = (List<Contract__c>) Trigger.new;
    @TestVisible private List<Contract__c> triggerOld = (List<Contract__c>) Trigger.old;
    @TestVisible private Map<Id, Contract__c> triggerNewmap = (Map<Id, Contract__c>) Trigger.newMap;
    @TestVisible private Map<Id, Contract__c> triggerOldmap = (Map<Id, Contract__c>) Trigger.oldMap;
    
    // ----------- OVERRIDE METHODS ----------------

    public override void beforeInsert() {
        requiredBillingApprovalDate();//[RGaokar 06/16/2022 TP #125634 ZAB Project: Billing Approval Date Required Before Contract Approval]
    }
    public override void beforeUpdate() {
        requiredBillingApprovalDate();//[RGaokar 06/16/2022 TP #125634 ZAB Project: Billing Approval Date Required Before Contract Approval]
    }
    
    // ----------- PRIVATE METHODS -----------------
    //[RGaokar 06/16/2022 TP #125634 ZAB Project: Billing Approval Date Required Before Contract Approval]
    //If approver approves the contract without filling billing approval date, throw the error message. 
    private void requiredBillingApprovalDate(){
        for(Contract__c contr:triggerNew){
            if((Trigger.isInsert || (Trigger.isUpdate && contr.Contract__c != triggerOldmap.get(contr.Id).Contract__c))
               && contr.Contract__c == 'Completed' && contr.Billing_Approval_Date__c == null
               && Trigger_Disablement_Switch__mdt.getInstance('Approved_Contract_Billing_Approval_Date').Is_Disabled__c == false){
                   contr.addError('Please enter the Billing Approval Date before approving the contract!');
            }
        }
    }

}
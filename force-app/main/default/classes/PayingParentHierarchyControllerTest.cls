@isTest
public class PayingParentHierarchyControllerTest {
    @testSetup
    static void dataSetup(){
        //Create accounts
        List<Account> accList = new List<Account>();
        Map <String,Schema.RecordTypeInfo> accRecordTypeMap = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        //Paying Parent
        Account parentAccount = new Account(Name = 'Parent Account', recordTypeId = accRecordTypeMap.get('Klaviyo Account').getRecordTypeId(),
                                            Product_Klaviyo_Account_ID__c  = 'parent1');
        
        insert parentAccount;
        //Billed Under Parent Children
        for(Integer i=0;i<2;i++) {
            accList.add(new Account(Name = 'Child Account'+i, recordTypeId = accRecordTypeMap.get('Klaviyo Account').getRecordTypeId(),
                                    Product_Klaviyo_Account_ID__c  = 'child'+i, Paying_Parent__c = parentAccount.id));
        }
        insert accList;  
    }
    
    @isTest
    private static void testPayingParentHierarchy(){
        Id parentAccountId = [Select id from Account where name = 'Child Account1' limit 1].id;
        string payingParentHierarchy = PayingParentHierarchyController.getPayingParentHierarchy(parentAccountId);
    } 
}
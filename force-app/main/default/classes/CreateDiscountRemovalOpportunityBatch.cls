// Batch Job for Creating opportunities for all discount expired OLIs
// Runs Daily
// Manual Run: Database.executeBatch(new CreateDiscountRemovalOpportunityBatch(), 10);
global class CreateDiscountRemovalOpportunityBatch implements Database.Batchable<sObject> {  
    
    // Trigger automation for OLIS with only closed won Opportunities where Sales method is Contracted, Discount End date + 1 is today
    global Database.QueryLocator start(Database.BatchableContext BC) {   
        Set<Id> setOfOLIIds = new Set<Id>();
        //Get all discount records where end date + 1 = today and Account.MRR > 0 and Sales Method is Contracted.
        List<Discount__c> listOfExpiredDiscount = [Select Id, Account__c, Opportunity_Line_Item__c,Opportunity_Line_Item__r.Product2Id From Discount__c Where End_Date__c =: System.today().addDays(-1) And Account__r.MRRCalc__c > 0 And Sales_Method__c =: 'Contracted'];
        Set<Id> setOfProductId = new Set<Id>();
        Set<Id> setOfAccountId = new Set<Id>();
        Set<Id> setOfSelectedProductId = new Set<Id>();
        for(Discount__c discountRecord : listOfExpiredDiscount){
            setOfProductId.add(discountRecord.Opportunity_Line_Item__r.Product2Id);
            setOfAccountId.add(discountRecord.Account__c);
        }
        
        for(Subscription__c subscriptionRecord : [Select Product__c From Subscription__c Where Contract__r.AccountId IN: setOfAccountId And Product__c IN: setOfProductId And (End_Date__c = null OR End_Date__c >: System.today())]){
            setOfSelectedProductId.add(subscriptionRecord.Product__c);
        } 
        
        for(Discount__c discountRecord : listOfExpiredDiscount){
            if(setOfSelectedProductId.contains(discountRecord.Opportunity_Line_Item__r.Product2Id)){
                setOfOLIIds.add(discountRecord.Opportunity_Line_Item__c);
            }
        }
        String query = 'Select Id, OpportunityId, Discount_Expiration_Date__c, Discount_Length_of_Months__c From OpportunityLineItem Where Opportunity.IsClosed = true And Id IN: setOfOLIIds';
        return Database.getQueryLocator(query);
    } 
    
    // Execute method    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // Create new and separate opportunities for all discount expired OLIs
        Set<Id> setOfOpportunityIds = new Set<Id>();
        Set<Id> setOfOLIIds = new Set<Id>();
        Map<Id, Id> mapOfMapping = new Map<Id, Id>();
        for(OpportunityLineItem oliRecord : (List<OpportunityLineItem>) scope){
            setOfOpportunityIds.add(oliRecord.OpportunityId);
            setOfOLIIds.add(oliRecord.Id);
            mapOfMapping.put(oliRecord.Id, oliRecord.OpportunityId);
        }
        if(!setOfOpportunityIds.isEmpty()){
            List<Opportunity> listOfOpportunity = (List<Opportunity>) Database.query(getAllOpportunityFields(setOfOpportunityIds));
            Map<Id, Opportunity> mapOfOpportunity = new Map<Id, Opportunity>();
            List<OpportunityLineItem> listOfOpportunityLineItemForInsert = new List<OpportunityLineItem>();
            Opportunity optyRecord = new Opportunity();
            for(Opportunity opportunityRecord : listOfOpportunity){
                optyRecord = new Opportunity(CloseDate = System.today(), Auto_Generated_Discount_Removal_Opp__c = true, PriceBook2Id = opportunityRecord.PriceBook2Id, Name = opportunityRecord.Name, StageName = 'Closed Won', AccountId = opportunityRecord.AccountId);
                //optyRecord.CloseDate = System.today().addDays(1);
                mapOfOpportunity.put(opportunityRecord.Id, optyRecord);
            }
            System.debug('OP Record : ' + mapOfOpportunity.size());
            insert mapOfOpportunity.values();
            List<OpportunityLineItem> listOfOpportunityLineItem = (List<OpportunityLineItem>) Database.query(getAllOpportunityLIFields(setOfOLIIds));
            Map<Id, OpportunityLineItem> mapOfOLI = new Map<Id, OpportunityLineItem>();
            OpportunityLineItem oliRecord = new OpportunityLineItem();
            for(OpportunityLineItem opportunityLineItemRecord : listOfOpportunityLineItem){
                oliRecord = new OpportunityLineItem(OpportunityId = mapOfOpportunity.get(opportunityLineItemRecord.OpportunityId).Id, Discount_Length_of_Months__c = 0, PriceBookEntryId = opportunityLineItemRecord.PriceBookEntryId, Product2Id = opportunityLineItemRecord.Product2Id, Product2Id__c = opportunityLineItemRecord.Product2Id__c);
                oliRecord.Usage_Limit__c = opportunityLineItemRecord.Usage_Limit__c;
                oliRecord.Quantity = opportunityLineItemRecord.Quantity;
                oliRecord.TotalPrice = opportunityLineItemRecord.Total_List_Price__c - opportunityLineItemRecord.TotalPrice;
                listOfOpportunityLineItemForInsert.add(oliRecord);
            }
            System.debug('OLI Record : ' + listOfOpportunityLineItemForInsert.size());
            insert listOfOpportunityLineItemForInsert;
        }
    }   
    
    // Finish Method
    global void finish(Database.BatchableContext BC) {
    }
    
    public static String getAllOpportunityFields(Set<Id> setOfOpportunityIds){
        Set<String> setOfFields = new Set<String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();
        for(String fieldName : fieldMap.keySet()) {
            if(fieldMap.get(fieldName).getDescribe().isUpdateable() && fieldName.toLowerCase() != 'contract__c') {
                setOfFields.add(fieldName);
            }
        }
        list<String> lstFieldNames = new List<String>(setOfFields);
        return 'SELECT ' + String.join(lstFieldNames, ',') + ' FROM Opportunity Where Id IN : setOfOpportunityIds';
    }
    
    public static String getAllOpportunityLIFields(Set<Id> setOfOLIIds){
        Set<String> setOfFields = new Set<String>{'pricebookentryid','opportunityid','Product2Id','Total_List_Price__c'};
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.OpportunityLineItem.fields.getMap();
        for(String fieldName : fieldMap.keySet()) {
            if(fieldMap.get(fieldName).getDescribe().isUpdateable() /*&& fieldName.toLowerCase() != 'totalprice'*/) {
                setOfFields.add(fieldName);
            }
        }
        list<String> lstFieldNames = new List<String>(setOfFields);
        return 'SELECT ' + String.join(lstFieldNames, ',') + ' FROM OpportunityLineItem Where Id IN : setOfOLIIds';
    }
}
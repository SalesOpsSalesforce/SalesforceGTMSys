public without sharing class OrderCreation {
    /*@future
    public static void createOrder(String jsonString){
        Map<Id, Opportunity> mapOfNewOpportunity = new Map<Id, Opportunity>();
        Map<String, Object> mapOfJSon = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        for(String key : mapOfJSon.keyset()){
            mapOfNewOpportunity.put((Id)key, (Opportunity)JSON.deserialize(JSON.serialize(mapOfJSon.get(key)), Opportunity.class));
        }*/
    public static void createOrder(Map<Id, Opportunity> mapOfNewOpportunity){
        Set<Id> setOfOpportunityIds = new Set<Id>();
        Set<Id> setOfQuoteIds = new Set<Id>();
        Set<Id> setOfAccountIds = new Set<Id>();
        Set<Id> setOfContractIds = new Set<Id>();
        Map<Id, Contract> mapOfContract = new Map<Id, Contract>();
        Map<Id, Order> mapOfOrder = new Map<Id, Order>();
        Map<Id, Quote> mapOfQuote = new Map<Id, Quote>();
        Map<Id, Account> mapOfAccount = new Map<Id, Account>();
        Map<Id, List<OpportunityLineItem>> mapOfOpportunityLineItem = new Map<Id, List<OpportunityLineItem>>();
        List<OrderItem> listOfOrderLineItem = new List<OrderItem>();
        List<String> contractFields = new List<String>{'Id'};
        List<String> accountFields = new List<String>{'Id'};
        List<String> quoteFields = new List<String>{'Id'};
        List<String> optyProductFields = new List<String>{'Id', 'OpportunityId', 'Opportunity.Primary_Quote__c'};
        String accountQuery = 'SELECT ';
        String quoteQuery = 'SELECT ';
        String contractQuery = 'SELECT ';
        String optyProductQuery = 'SELECT ';
        Map<String, String> mapOfOpportunityContract = new Map<String, String>();
        for(Id key : mapOfNewOpportunity.keySet()){
            setOfOpportunityIds.add(key);
        }
        List<Order_Field_Mapping__mdt> listOfOrderMapping = [SELECT Order_Field_API_Name__c, Reference_Field_API_Name__c, Reference_Object__c FROM Order_Field_Mapping__mdt];
        List<Order_Line_Item_Field_Mapping__mdt> listOfOrderLineMapping = [SELECT Order_Line_Item_Field_API_Name__c, Reference_Field_API_Name__c, Reference_Object__c FROM Order_Line_Item_Field_Mapping__mdt Where Reference_Field_API_Name__c != null];
        if(!listOfOrderMapping.isEmpty()){
            for(Order_Field_Mapping__mdt fieldMapping : listOfOrderMapping){
                if(fieldMapping.Reference_Object__c == 'Account' && !accountFields.contains(fieldMapping.Reference_Field_API_Name__c)){
                    accountFields.add(fieldMapping.Reference_Field_API_Name__c);
                }else if(fieldMapping.Reference_Object__c == 'Primary_Quote' && !quoteFields.contains(fieldMapping.Reference_Field_API_Name__c)){
                    quoteFields.add(fieldMapping.Reference_Field_API_Name__c);
                }else if(fieldMapping.Reference_Object__c == 'Contract' && !contractFields.contains(fieldMapping.Reference_Field_API_Name__c)){
                    contractFields.add(fieldMapping.Reference_Field_API_Name__c);
                }
            }
            for(Order_Line_Item_Field_Mapping__mdt fieldMapping : listOfOrderLineMapping){
                if(fieldMapping.Reference_Object__c == 'Primary_Quote' && !quoteFields.contains(fieldMapping.Reference_Field_API_Name__c)){
                    quoteFields.add(fieldMapping.Reference_Field_API_Name__c);
                }
            }
            if(!mapOfNewOpportunity.isEmpty()){
                for(Opportunity opoortunityRecord : mapOfNewOpportunity.values()){
                    setOfQuoteIds.add(opoortunityRecord.Primary_Quote__c);
                    setOfAccountIds.add(opoortunityRecord.AccountId);
                    setOfContractIds.add(opoortunityRecord.Contract__c);
                    mapOfOpportunityContract.put(opoortunityRecord.Contract__c, opoortunityRecord.Id);
                }
                if(!contractFields.isEmpty()){
                    contractQuery = contractQuery + string.join(contractFields, ',');
                    contractQuery = contractQuery + ' From Contract Where Id IN: setOfContractIds';
                    List<Contract> listOfContract = Database.query(contractQuery);
                    for(Contract contractRecord : listOfContract){
                        mapOfContract.put(mapOfOpportunityContract.get(contractRecord.Id), contractRecord);
                    }
                    if(mapOfContract.isEmpty() && !Test.isRunningTest()){
                        throw new IllegalArgumentException('Contract record is not available on Opportunity.');
                    }
                }
                if(!accountFields.isEmpty()){
                    accountQuery = accountQuery + string.join(accountFields, ',');
                    accountQuery = accountQuery + ' From Account Where Id IN: setOfAccountIds';
                    List<Account> listOfAccount = Database.query(accountQuery);
                    for(Account accountRecord : listOfAccount){
                        mapOfAccount.put(accountRecord.Id, accountRecord);
                    }
                }
                if(!quoteFields.isEmpty()){
                    quoteQuery = quoteQuery + string.join(quoteFields, ',');
                    quoteQuery = quoteQuery + ' From Quote Where Id IN: setOfQuoteIds';
                    List<Quote> listOfQuote = Database.query(quoteQuery);
                    for(Quote quoteRecord : listOfQuote){
                        mapOfQuote.put(quoteRecord.Id, quoteRecord);
                    }
                }
                Order orderRecord;
                for(Id key : mapOfNewOpportunity.keySet()){
                    orderRecord = new Order();
                    for(Order_Field_Mapping__mdt fieldMapping : listOfOrderMapping){
                        if(fieldMapping.Reference_Object__c == 'Opportunity' && mapOfNewOpportunity.containskey(key)){
                            orderRecord.put(fieldMapping.Order_Field_API_Name__c, mapOfNewOpportunity.get(key).get(fieldMapping.Reference_Field_API_Name__c));
                        }else if(fieldMapping.Reference_Object__c == 'Account' && mapOfNewOpportunity.containskey(key) && !String.isEmpty(mapOfNewOpportunity.get(key).AccountId) && mapOfAccount.containskey(mapOfNewOpportunity.get(key).AccountId)){
                            orderRecord.put(fieldMapping.Order_Field_API_Name__c, mapOfAccount.get(mapOfNewOpportunity.get(key).AccountId).get(fieldMapping.Reference_Field_API_Name__c));
                        }else if(fieldMapping.Reference_Object__c == 'Primary_Quote' && mapOfNewOpportunity.containskey(key) && !String.isEmpty(mapOfNewOpportunity.get(key).Primary_Quote__c) && mapOfQuote.containskey(mapOfNewOpportunity.get(key).Primary_Quote__c)){
                            orderRecord.put(fieldMapping.Order_Field_API_Name__c, mapOfQuote.get(mapOfNewOpportunity.get(key).Primary_Quote__c).get(fieldMapping.Reference_Field_API_Name__c));
                        }else if(fieldMapping.Reference_Object__c == 'Contract' && mapOfContract.containskey(key)){
                            orderRecord.put(fieldMapping.Order_Field_API_Name__c, mapOfContract.get(key).get(fieldMapping.Reference_Field_API_Name__c));
                        }else if(fieldMapping.Reference_Object__c == 'Default'){
                            orderRecord.put(fieldMapping.Order_Field_API_Name__c, fieldMapping.Reference_Field_API_Name__c);
                        }
                        mapOfOrder.put(key, orderRecord);
                    }
                }
                
                List<Order> listOfOrderToDelete = [Select Id From Order Where OpportunityId In: setOfOpportunityIds];
                delete listOfOrderToDelete;
                insert mapOfOrder.values();
                if(!mapOfOrder.isEmpty()){
                    if(!listOfOrderLineMapping.isEmpty()){
                        for(Order_Line_Item_Field_Mapping__mdt fieldMapping : listOfOrderLineMapping){
                            if(fieldMapping.Reference_Object__c == 'OpportunityLineItem' && !optyProductFields.contains(fieldMapping.Reference_Field_API_Name__c)){
                                optyProductFields.add(fieldMapping.Reference_Field_API_Name__c);
                            }
                        }
                        Set<String> setOfOptyKey = new Set<String>();
                        for(String key : mapOfOrder.keySet()){
                            setOfOptyKey.add(key);
                        }
                        if(!optyProductFields.isEmpty()){
                            optyProductQuery = optyProductQuery + string.join(optyProductFields, ',');
                            optyProductQuery = optyProductQuery + ' From OpportunityLineItem Where OpportunityId IN: setOfOptyKey';
                            List<OpportunityLineItem> listOfOptyProduct = Database.query(optyProductQuery);
                            for(OpportunityLineItem opportunityLineItemRecord : listOfOptyProduct){
                                if(mapOfOpportunityLineItem.containskey(opportunityLineItemRecord.OpportunityId)){
                                    mapOfOpportunityLineItem.get(opportunityLineItemRecord.OpportunityId).add(opportunityLineItemRecord);
                                }else{
                                    mapOfOpportunityLineItem.put(opportunityLineItemRecord.OpportunityId, new List<OpportunityLineItem>{opportunityLineItemRecord});
                                }
                            }
                        }
                        OrderItem orderLineItemRecord;
                        for(String key : mapOfOrder.keySet()){
                            if(mapOfOpportunityLineItem.containskey(key)){
                                for(OpportunityLineItem oliRecord : mapOfOpportunityLineItem.get(key)){
                                    orderLineItemRecord = new OrderItem(OrderId = mapOfOrder.get(key).Id);
                                    for(Order_Line_Item_Field_Mapping__mdt fieldMapping : listOfOrderLineMapping){
                                        if(fieldMapping.Reference_Object__c == 'OpportunityLineItem'){
                                            orderLineItemRecord.put(fieldMapping.Order_Line_Item_Field_API_Name__c, oliRecord.get(fieldMapping.Reference_Field_API_Name__c));
                                        }else if(fieldMapping.Reference_Object__c == 'Primary_Quote' && oliRecord.Opportunity.Primary_Quote__c != null){
                                            orderLineItemRecord.put(fieldMapping.Order_Line_Item_Field_API_Name__c, mapOfQuote.get(oliRecord.Opportunity.Primary_Quote__c).get(fieldMapping.Reference_Field_API_Name__c));
                                        }
                                    }
                                    listOfOrderLineItem.add(orderLineItemRecord);
                                }
                            }
                        }
                        if(!listOfOrderLineItem.isEmpty()){
                            insert listOfOrderLineItem;
                        }
                    }
                }
            }
        }
    }
}
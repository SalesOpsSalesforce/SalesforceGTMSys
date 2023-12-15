//[vrajapatruni 02/16/2023 SFDC-1742/1880] Built to dynamically take in Field Set (OpportunityMPOFieldSet for Opp's Add/Update products wizard)
//Code coverage in UpdateOpportunityProductTest

public without sharing class UpdateOpportunityProduct {
    public static Set<String> setOfString = new Set<String>{'Product2Id', 'OpportunityId'};
    public static Set<String> setOfStage = new Set<String>();
    public static Map<String, String> mapOfSize = new Map<String, String>{'Product2Id__c' => '2','Discount_Coupon__c' => '2'};
    
    @AuraEnabled
    //Method for reading the field set
    public static List<FieldDetails> readFieldSet(String fieldSetName, String ObjectName){
        List<FieldDetails> listOfFieldDetails = new List<FieldDetails>();
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetObj.getFields()){
            if(String.valueOf(fieldSetMemberObj.getType()) == 'REFERENCE'){
                if(mapOfSize.containsKey(fieldSetMemberObj.getFieldPath())){
                    listOfFieldDetails.add(new FieldDetails(fieldSetMemberObj.getFieldPath(), fieldSetMemberObj.getLabel(), fieldSetMemberObj.getRequired(), 'slds-col slds-size_' + mapOfSize.get(fieldSetMemberObj.getFieldPath()) + '-of-12', String.valueOf(fieldSetMemberObj.getType())));
                }else{
                    listOfFieldDetails.add(new FieldDetails(fieldSetMemberObj.getFieldPath(), fieldSetMemberObj.getLabel(), fieldSetMemberObj.getRequired(), 'slds-col slds-size_1-of-12', String.valueOf(fieldSetMemberObj.getType())));
                }
            }else{
                listOfFieldDetails.add(new FieldDetails(fieldSetMemberObj.getFieldPath(), fieldSetMemberObj.getLabel(), fieldSetMemberObj.getRequired(), 'slds-col slds-size_1-of-12', String.valueOf(fieldSetMemberObj.getType())));
            }
        }
        listOfFieldDetails.add(new FieldDetails('Action', 'Action', false, 'slds-col slds-size_1-of-12', ''));
        return listOfFieldDetails;
    } 
    
    @AuraEnabled
    //Method to get the opportunity product
    public static WrapperInstance getOpportunityProduct(String opportunityId, String fieldSetName, String ObjectName){
        for(String ss : System.Label.Opportunity_Stage.split(',')){
            setOfStage.add(ss);
        }
        List<OpportunityLineItem> listOfOpportunityLineItem = new List<OpportunityLineItem>();
        List<FieldDetails> listOfFieldDetails = readFieldSet(fieldSetName, ObjectName);
        String query = 'Select Id, OpportunityId, Amended_Subscription__c, Opportunity.IsClosed, Product2Id ';
        for(FieldDetails fdRecord : listOfFieldDetails){
            if(fdRecord.fieldAPI != 'Action' && fdRecord.fieldAPI != 'OpportunityId' && fdRecord.fieldAPI != 'Amended_Subscription__c')
                query = query + ', ' + fdRecord.fieldAPI;
        }
        query = query + ' From OpportunityLineItem Where OpportunityId = \'' +  opportunityId + '\'';
        listOfOpportunityLineItem = Database.query(query);
        List<LineItemVariables> listOfItemVariables = new List<LineItemVariables>();
        for(OpportunityLineItem oli : listOfOpportunityLineItem){
            listOfItemVariables.add(new LineItemVariables(oli, true, oli.Id, 'slds-col slds-size_1-of-12'));
        }
        if(listOfItemVariables.isEmpty()){
            listOfItemVariables.add(new LineItemVariables(new OpportunityLineItem(), true, '11', 'slds-col slds-size_1-of-12'));
        }
        Opportunity optyRecord = [Select Id, IsClosed, StageName, Sales_Method__c, Discount_Approval_Status__c From Opportunity Where Id =: opportunityId];
        String paymentMethod = 'Not Stripe';
        if(optyRecord.Sales_Method__c == 'In App'){
            paymentMethod = 'Stripe';
        }
        WrapperInstance wrapperInstanceDetails = new WrapperInstance(listOfOpportunityLineItem, listOfFieldDetails, listOfItemVariables, optyRecord.IsClosed, paymentMethod);
        wrapperInstanceDetails.opportunityStage = setOfStage.contains(optyRecord.StageName);
        wrapperInstanceDetails.opportunityId = optyRecord.Id;
        if(optyRecord.Discount_Approval_Status__c == 'Pending'){
            wrapperInstanceDetails.isApprovalPending = true;
        }
        List<Product2> listOfProduct = [Select Id, Name, Quantity_Type__c, Disable_Discount__c, Exclude_from_Usage_Period_Validation__c, Default_Usage_Period__c, Locked_Usage_to_Default__c From Product2];
        wrapperInstanceDetails.mapOfProducts = new Map<String, String>();
        wrapperInstanceDetails.mapOfProductsDiscount = new Map<String, Boolean>();
        wrapperInstanceDetails.mapOfProductsUsage = new Map<String, Boolean>();
        wrapperInstanceDetails.mapOfLockedUsage = new Map<String, Boolean>();
        wrapperInstanceDetails.mapOfDefaultUsage = new Map<String, String>();
        for(Product2 prRecord : listOfProduct){
            wrapperInstanceDetails.mapOfProducts.put(prRecord.Id, prRecord.Quantity_Type__c);
            wrapperInstanceDetails.mapOfProductsDiscount.put(prRecord.Id, prRecord.Disable_Discount__c);
            wrapperInstanceDetails.mapOfProductsUsage.put(prRecord.Id, prRecord.Exclude_from_Usage_Period_Validation__c);
            if(prRecord.Locked_Usage_to_Default__c){
                wrapperInstanceDetails.mapOfLockedUsage.put(prRecord.Id, prRecord.Locked_Usage_to_Default__c);
            }
            if(prRecord.Default_Usage_Period__c != null){
                wrapperInstanceDetails.mapOfDefaultUsage.put(prRecord.Id, prRecord.Default_Usage_Period__c);
            }
        }
        List<Opportunity_Product_Delete_Validations__mdt> listOfProductDelete = [Select Id, Deleted_Product_Id__c, Existing_Product_Id__c, Not_Available_Product_ID__c, DeveloperName From Opportunity_Product_Delete_Validations__mdt];
        List<Product_Question_Mapping__mdt> listOfQuestions = [Select Id,Product_Id__c, Question_Field_API_Name__c, Trigger_Action__c From Product_Question_Mapping__mdt ORDER BY Question_Field_API_Name__c DESC];
        Map<String, List<UpdateWrapper>> mapOfProductOptyValues = new Map<String, List<UpdateWrapper>>();
        for(Product_Question_Mapping__mdt pqmRecord : listOfQuestions){
            if((checkProductForDelete(listOfProductDelete, listOfOpportunityLineItem, pqmRecord.Product_Id__c) && pqmRecord.Trigger_Action__c == 'Delete') || pqmRecord.Trigger_Action__c == 'New'){
                if(!mapOfProductOptyValues.containskey(pqmRecord.Product_Id__c)){
                    mapOfProductOptyValues.put(pqmRecord.Product_Id__c, new List<UpdateWrapper>{new UpdateWrapper(pqmRecord.Question_Field_API_Name__c, '', pqmRecord.Trigger_Action__c)});
                }else{
                    mapOfProductOptyValues.get(pqmRecord.Product_Id__c).add(new UpdateWrapper(pqmRecord.Question_Field_API_Name__c, '', pqmRecord.Trigger_Action__c));
                }
            }
        }
        wrapperInstanceDetails.mapOfProductOptyValues = mapOfProductOptyValues;
        wrapperInstanceDetails.mapOfDiscount = new Map<String, Discount_Coupon__c>([Select Id,Discount__c, Length_of_Months__c, Name, Is_Active__c  From Discount_Coupon__c Where Is_Active__c = true]);
        wrapperInstanceDetails.mapOfOriginalOpportunity = new Map<String, Boolean>();
        List<Opportunity> listOfOriginalOpportunity = [Select Id, Original_Opportunity__c, External_Original_Opportunity__c From Opportunity Where Original_Opportunity__c =: opportunityId];
        for(Opportunity oppRecord : listOfOriginalOpportunity){
            wrapperInstanceDetails.mapOfOriginalOpportunity.put(oppRecord.External_Original_Opportunity__c, true);
        }
        return wrapperInstanceDetails;
    }
    
    public static Boolean checkProductForDelete(List<Opportunity_Product_Delete_Validations__mdt> listOfProductDelete, List<OpportunityLineItem> listOfOpportunityLineItem, String deletedRecordId){
        Boolean validateProductForDelete = true;
        if(System.Label.Ignore_Delete_Validations_MPO == 'Yes'){
            Set<String> setOfProductIds = new Set<String>();
            for(OpportunityLineItem oliRecord : listOfOpportunityLineItem){
                setOfProductIds.add(oliRecord.Product2Id);
            }
            for(Opportunity_Product_Delete_Validations__mdt opdvRecord : listOfProductDelete){
                if(opdvRecord.Deleted_Product_Id__c == deletedRecordId){
                    if(!String.isBlank(opdvRecord.Existing_Product_Id__c) && opdvRecord.Existing_Product_Id__c.contains(',')){
                        List<String> listOfIds = opdvRecord.Existing_Product_Id__c.split(',');
                        if(listOfIds.size() == 2 && setOfProductIds.contains(deletedRecordId) && setOfProductIds.contains(listOfIds[0]) && setOfProductIds.contains(listOfIds[1])){
                            validateProductForDelete = false;
                        }
                    }else if(!String.isBlank(opdvRecord.Existing_Product_Id__c) && !String.isBlank(opdvRecord.Not_Available_Product_ID__c)){
                        if(setOfProductIds.contains(deletedRecordId) && setOfProductIds.contains(opdvRecord.Existing_Product_Id__c) && !setOfProductIds.contains(opdvRecord.Not_Available_Product_ID__c)){
                            validateProductForDelete = false;
                        }
                    }else if(String.isBlank(opdvRecord.Existing_Product_Id__c) && String.isBlank(opdvRecord.Not_Available_Product_ID__c)){
                        if(setOfProductIds.contains(deletedRecordId)){
                            validateProductForDelete = false;
                        }
                    }
                }
            }
        }
        return validateProductForDelete;
    }
    
    public class FieldDetails{
        @AuraEnabled public String fieldAPI;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public Boolean fieldIsRequired;
        @AuraEnabled public String classDetails;
        @AuraEnabled public String fieldType;
        
        public FieldDetails(String fieldAPI, String fieldLabel, Boolean fieldIsRequired, String classDetails, String fieldType){
            this.fieldAPI = fieldAPI;
            this.fieldLabel = fieldLabel;
            this.fieldIsRequired = fieldIsRequired;
            this.classDetails = classDetails;
            this.fieldType = fieldType;
        }
    }
    
    public class WrapperInstance{
        @AuraEnabled public List<OpportunityLineItem> listOfOpportunityLineItem;
        @AuraEnabled public List<FieldDetails> listOfFieldDetails;
        @AuraEnabled public List<LineItemVariables> listOfItemVariables;
        @AuraEnabled public OpportunityLineItem blankOli;
        @AuraEnabled public Boolean isOpportunityClosed;
        @AuraEnabled public String paymentMethod;
        @AuraEnabled public Map<String, String> mapOfProducts;
        @AuraEnabled public Map<String, Boolean> mapOfProductsDiscount;
        @AuraEnabled public Map<String, List<UpdateWrapper>> mapOfProductOptyValues;
        @AuraEnabled public Boolean opportunityStage;
        @AuraEnabled public String opportunityId;
        @AuraEnabled public Map<String, Discount_Coupon__c> mapOfDiscount;
        @AuraEnabled public Boolean isApprovalPending;
        @AuraEnabled public Map<String, Boolean> mapOfProductsUsage;
        @AuraEnabled public Map<String, Boolean> mapOfOriginalOpportunity;
        @AuraEnabled public Map<String, String> mapOfDefaultUsage;
        @AuraEnabled public Map<String, Boolean> mapOfLockedUsage;
        
        public WrapperInstance(List<OpportunityLineItem> listOfOpportunityLineItem, List<FieldDetails> listOfFieldDetails, List<LineItemVariables> listOfItemVariables, Boolean isOpportunityClosed, String paymentMethod){
            this.listOfOpportunityLineItem = listOfOpportunityLineItem;
            this.listOfFieldDetails = listOfFieldDetails;
            this.listOfItemVariables = listOfItemVariables;
            this.isOpportunityClosed = isOpportunityClosed;
            this.paymentMethod = paymentMethod;
            this.blankOli = new OpportunityLineItem(Product2Id__c = null, Product2Id = null,Amended_Subscription__c = null, Id = null, Usage_Limit__c = 0, Discount__c = 0, List_Price__c = 0, UnitPrice = 0, TotalPrice = 0);
        }
    }
    
    public class LineItemVariables{
        @AuraEnabled public OpportunityLineItem oli;
        @AuraEnabled public Boolean disableValue;
        @AuraEnabled public String recordId;
        @AuraEnabled public String classDetails;
        
        public LineItemVariables(OpportunityLineItem oli, Boolean disableValue, String recordId, String classDetails){
            this.oli = oli;
            this.disableValue = disableValue;
            this.recordId = recordId;
            this.classDetails = classDetails;
        }
    }
    
    @AuraEnabled
    //Method for updating products
    public static String updateProduct(String mapOfString){
        Savepoint sp = Database.setSavepoint();
        try{
            List<UpdateWrapper> listOfUpdateWrapper = (List<UpdateWrapper>) System.JSON.deserialize(mapOfString, List<UpdateWrapper>.class);
            OpportunityLineItem oliRecord = new OpportunityLineItem();
            Boolean isExistingRecord = false;
            String productId;
            for(UpdateWrapper uwRecord : listOfUpdateWrapper){
                if(!String.isEmpty(uwRecord.key) && uwRecord.key == 'Id' && uwRecord.value.length() > 10){
                    oliRecord.put(uwRecord.key, uwRecord.value);
                    isExistingRecord = true;
                }if(!String.isEmpty(uwRecord.key) && uwRecord.key == 'Product2Id' && uwRecord.value.length() > 10){
                    productId = uwRecord.value;
                }
            }
            List<Product2> productRecord = [Select Id, IsActive, Name, Family, Pricing_Type__c, Standard_Pricebook_Entry_Id__c From Product2 Where Id =: productId];
            if(!productRecord.isEmpty()){
                if(!productRecord[0].IsActive){
                    return 'Product is not active.';
                }
                for(UpdateWrapper uwRecord : listOfUpdateWrapper){
                    if(uwRecord.key != 'Id' && ((isExistingRecord && !setOfString.contains(uwRecord.key)) || !isExistingRecord)){
                        if(uwRecord.fieldType == 'REFERENCE' || uwRecord.fieldType == 'STRING' || uwRecord.fieldType == 'PICKLIST'){
                            oliRecord.put(uwRecord.key, uwRecord.value);
                        }else if(uwRecord.fieldType == 'INTEGER' || uwRecord.fieldType == 'DOUBLE' || uwRecord.fieldType == 'CURRENCY' || uwRecord.fieldType == 'PERCENT'){
                            if(String.isEmpty(uwRecord.value))
                                uwRecord.value = '0';
                            oliRecord.put(uwRecord.key, Decimal.valueOf(uwRecord.value));
                        }else if(uwRecord.fieldType == 'DATE' && !String.isEmpty(uwRecord.value)){
                            oliRecord.put(uwRecord.key, Date.valueOf(uwRecord.value));
                        }else if(uwRecord.fieldType == 'DATETIME' && !String.isEmpty(uwRecord.value)){
                            oliRecord.put(uwRecord.key, DateTime.valueOf(uwRecord.value));
                        }else if(uwRecord.fieldType == 'BOOLEAN' && !String.isEmpty(uwRecord.value)){
                            oliRecord.put(uwRecord.key, Boolean.valueOf(uwRecord.value));
                        }
                    }
                }
                if(isExistingRecord){
                    update oliRecord;
                }else{
                    oliRecord.put('Quantity', 1);
                    //oliRecord.put('TotalPrice', 0);
                    oliRecord.put('PriceBookEntryId', productRecord[0].Standard_Pricebook_Entry_Id__c);
                    insert oliRecord;
                }            
                return 'Success';
            }else{
                return 'Product not found.';
            }
            
        }catch(Exception e){
            Database.rollback(sp);
            return e.getMessage();
        }
    }
    
    public class UpdateWrapper{
        @AuraEnabled public String key;
        @AuraEnabled public String value;
        @AuraEnabled public String fieldType;
        
        public UpdateWrapper(String key, String value, String fieldType){
            this.key = key;
            this.value = value;
            this.fieldType = fieldType;
        }
    }
    
    public class UpdateAllWrapper{
        @AuraEnabled public String key;
        @AuraEnabled public List<UpdateWrapper> lineItemData;
        
        public UpdateAllWrapper(String key, List<UpdateWrapper> lineItemData){
            this.key = key;
            this.lineItemData = lineItemData;
        }
    }
    
    @AuraEnabled
    //Method for deleting products
    public static String deleteProduct(String recordIdForDelete, String mapOfProductOptyValues, String opportunityId){
        Savepoint sp = Database.setSavepoint();
        try{
            Map<String, List<UpdateWrapper>> mapOfValuesForOpp = (Map<String, List<UpdateWrapper>>) System.JSON.deserialize(mapOfProductOptyValues, Map<String, List<UpdateWrapper>>.class);
            if(!String.isEmpty(recordIdForDelete) && recordIdForDelete.length() > 5){
                if(!Test.isRunningTest()){
                    List<Opportunity_Product_Delete_Validations__mdt> listOfProductDelete = new List<Opportunity_Product_Delete_Validations__mdt>();
                    listOfProductDelete = [Select Id,Deleted_Product_Id__c, Existing_Product_Id__c, Not_Available_Product_ID__c, DeveloperName From Opportunity_Product_Delete_Validations__mdt];
                    List<OpportunityLineItem> listOfOLI = new List<OpportunityLineItem>();
                    listOfOLI = [Select Id, Product2Id From OpportunityLineItem Where OpportunityId =: opportunityId];
                    String deletedProductId;
                    for(OpportunityLineItem oliRecords : listOfOLI){
                        if(oliRecords.Id == recordIdForDelete){
                            deletedProductId = oliRecords.Product2Id;
                        }
                    }
                    if(checkProductForDelete(listOfProductDelete, listOfOLI, deletedProductId)){
                        Opportunity optyRecordExist = Database.query(getAllOpportunityFields(opportunityId));
                        Opportunity opp = optyRecordExist.clone(false, true, true, false);
                        //Opportunity opp = new Opportunity(Id = opportunityId);
                        for(String ss : mapOfValuesForOpp.keyset()){
                            for(UpdateWrapper uwInstance : mapOfValuesForOpp.get(ss)){
                                if(!String.isEmpty(uwInstance.value)){
                                    opp.put(uwInstance.key, uwInstance.value);
                                }
                            }
                        }
                        //opp.put('StageName', 'Closed Lost');
                        opp.External_Original_Opportunity__c = opportunityId + deletedProductId;
                        opp.Original_Opportunity__c = opportunityId;
                        opp.Primary_Quote__c = null;
                        opp.StageName = 'Closed Lost';
                        opp.Ignore_Validations__c = true; 
                        upsert opp External_Original_Opportunity__c;
                        OpportunityLineItem optyLIRecordExist = Database.query(getAllOpportunityLIFields(recordIdForDelete));
                        OpportunityLineItem oppLI = optyLIRecordExist.clone(false, true, true, false);
                        oppLI.OpportunityId = opp.Id;
                        insert oppLI;
                        //opp.StageName = 'Closed Lost';
                        //opp.Ignore_Validations__c = true; 
                        //update opp;
                    }
                    OpportunityLineItem oliRecord = new OpportunityLineItem(Id = recordIdForDelete);
                    delete oliRecord;
                }
                return 'Success';
            }else{
                return 'Success';
            }
        }catch(Exception e){
            Database.rollback(sp);
            return e.getStackTraceString();
        }
        
    }
    
    public static String getAllOpportunityFields(String opportunityId){
        Set<String> setOfFields = new Set<String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();
        for(String fieldName : fieldMap.keySet()) {
            if(fieldMap.get(fieldName).getDescribe().isUpdateable() && fieldName.toLowerCase() != 'lead_flip_owner__c' && fieldName.toLowerCase() != 'lead_flip_channel__c' && fieldName.toLowerCase() != 'lead_flip_date_time__c' && fieldName.toLowerCase() != 'lead_flip_list_size_by_bucket__c' && fieldName.toLowerCase() != 'flip_owner_title_at_time_of_flip__c' && fieldName.toLowerCase() != 'flip_platform_bucket__c' && fieldName.toLowerCase() != 'lead_flip_recipient__c' && fieldName.toLowerCase() != 'flip_owner_manager__c') {
                setOfFields.add(fieldName);
            }
        }
        list<String> lstFieldNames = new List<String>(setOfFields);
        return 'SELECT ' + String.join(lstFieldNames, ',') + ' FROM Opportunity Where Id = \'' + opportunityId + '\'';
    }
    
    public static String getAllOpportunityLIFields(String recordId){
        Set<String> setOfFields = new Set<String>{'pricebookentryid'};
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.OpportunityLineItem.fields.getMap();
        for(String fieldName : fieldMap.keySet()) {
            if(fieldMap.get(fieldName).getDescribe().isUpdateable() && fieldName.toLowerCase() != 'totalprice') {
                setOfFields.add(fieldName);
            }
        }
        list<String> lstFieldNames = new List<String>(setOfFields);
        return 'SELECT ' + String.join(lstFieldNames, ',') + ' FROM OpportunityLineItem Where Id = \'' + recordId + '\'';
    }
    
    @AuraEnabled
    //Method for updating multiple products at once
    public static String updateAllProduct(String mapOfString, String mapOfProductOptyValues, String opportunityId){
        Savepoint sp = Database.setSavepoint();
        try{
            System.debug('opportunityId : ' + opportunityId);
            List<OpportunityLineItem> listOfOpportunityLineItemForUpdate = new List<OpportunityLineItem>();
            List<UpdateAllWrapper> listOfUpdateAllWrapper = (List<UpdateAllWrapper>) System.JSON.deserialize(mapOfString, List<UpdateAllWrapper>.class);
            Map<String, List<UpdateWrapper>> mapOfValuesForOpp = (Map<String, List<UpdateWrapper>>) System.JSON.deserialize(mapOfProductOptyValues, Map<String, List<UpdateWrapper>>.class);
            OpportunityLineItem oliRecord = new OpportunityLineItem();
            Set<String> setOfProductId = new Set<String>();
            for(UpdateAllWrapper wrapperInstance : listOfUpdateAllWrapper){
                for(UpdateWrapper uwRecord : wrapperInstance.lineItemData){
                    if(!String.isEmpty(uwRecord.key) && (uwRecord.key == 'Product2Id' || uwRecord.key == 'Product2Id__c') && uwRecord.value.length() > 10){
                        setOfProductId.add(uwRecord.value);
                    }
                }
            }
            //Removed discounting_disabled for non-dev env
            Map<Id, Product2> mapOfProducts = new Map<Id, Product2>([Select Id, IsActive, Name, Family, Pricing_Type__c, Standard_Pricebook_Entry_Id__c From Product2 Where Id IN: setOfProductId]);
            if(!mapOfProducts.isEmpty()){
                for(Product2 productRecord : mapOfProducts.values()){
                    if(!productRecord.IsActive){
                        return 'Product (' + productRecord.Name + ') is not active.';
                    }
                }
                Boolean isNew = false;
                for(UpdateAllWrapper wrapperInstance : listOfUpdateAllWrapper){
                    isNew = false;
                    oliRecord = new OpportunityLineItem();
                    for(UpdateWrapper uwRecord : wrapperInstance.lineItemData){
                        if(!String.isEmpty(uwRecord.key) && uwRecord.key == 'Id' && uwRecord.value.length() > 10){
                            oliRecord.put(uwRecord.key, uwRecord.value);
                            // oliRecord.put('Pricing_Override__c', false);
                        }else if(!String.isEmpty(uwRecord.key) && uwRecord.key == 'Id' && uwRecord.value.length() < 10){
                            oliRecord.put('Quantity', 1);
                            isNew = true;
                        }
                        if(uwRecord.key != 'Id' && ((!isNew && !setOfString.contains(uwRecord.key)) || isNew)){
                            if(uwRecord.fieldType == 'REFERENCE' || uwRecord.fieldType == 'STRING' || uwRecord.fieldType == 'PICKLIST'){
                                oliRecord.put(uwRecord.key, uwRecord.value);
                            }else if(uwRecord.fieldType == 'INTEGER' || uwRecord.fieldType == 'DOUBLE' || uwRecord.fieldType == 'CURRENCY' || uwRecord.fieldType == 'PERCENT'){
                                if(String.isEmpty(uwRecord.value))
                                    uwRecord.value = '0';
                                oliRecord.put(uwRecord.key, Decimal.valueOf(uwRecord.value));
                            }else if(uwRecord.fieldType == 'DATE' && !String.isEmpty(uwRecord.value)){
                                oliRecord.put(uwRecord.key, Date.valueOf(uwRecord.value));
                            }else if(uwRecord.fieldType == 'DATETIME' && !String.isEmpty(uwRecord.value)){
                                oliRecord.put(uwRecord.key, DateTime.valueOf(uwRecord.value));
                            }else if(uwRecord.fieldType == 'BOOLEAN' && !String.isEmpty(uwRecord.value)){
                                oliRecord.put(uwRecord.key, Boolean.valueOf(uwRecord.value));
                            }
                            if(isNew && (uwRecord.key == 'Product2Id' || uwRecord.key == 'Product2Id__c') && mapOfProducts.containsKey(uwRecord.value)){
                                oliRecord.put('PriceBookEntryId', mapOfProducts.get(uwRecord.value).Standard_Pricebook_Entry_Id__c);
                            }
                        }
                    }
                    listOfOpportunityLineItemForUpdate.add(oliRecord);
                }
                for(OpportunityLineItem oliRecordT : listOfOpportunityLineItemForUpdate){
                    System.debug('oliRecordT : ' + oliRecordT);
                    //oliRecordT.put('Product2Id', oliRecordT.Product2Id__c);
                    if(oliRecordT.Product2Id == System.Label.Klaviyo_One && oliRecordT.Usage_Limit__c > 1){
                        return 'Usage limit for Klaviyo One cannot be more than 1. Please update the value and retry';
                    }
                    if(oliRecordT.UnitPrice == null){
                        //oliRecordT.TotalPrice = 0;
                    }
                    if(oliRecordT.Discount__c != null && oliRecordT.Discount__c > 0 && (oliRecordT.Discount_Length_of_Months__c == null || oliRecordT.Discount_Length_of_Months__c <= 0)){
                        return 'Discount Length (# of months) cannot be null or 0 when Discount is greater than 0 for ' + mapOfProducts.get(oliRecordT.Product2Id__c).Name;
                    }
                }
                System.debug('listOfOpportunityLineItemForUpdate : ' + listOfOpportunityLineItemForUpdate);
                // Database.upsert(listOfOpportunityLineItemForUpdate, false);
                upsert listOfOpportunityLineItemForUpdate;
                
                if(!Test.isRunningTest()){
                    Opportunity opp = new Opportunity(Id = OpportunityId);
                    for(String ss : mapOfValuesForOpp.keyset()){
                        for(UpdateWrapper uwInstance : mapOfValuesForOpp.get(ss)){
                            if(!String.isEmpty(uwInstance.value)){
                                opp.put(uwInstance.key, uwInstance.value);
                            }
                        }
                    }
                    update opp;
                }
                return 'Success';
            }else{
                return 'Products not found.';
            }
            
        }catch(Exception e){
            Database.rollback(sp);
            return e.getMessage();
        }  
    }
}
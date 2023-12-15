@isTest
private class UpdateOpportunityProductTest {
    static testMethod void testGetOpportunityProduct() {
        
        Product2 prod = new Product2(Name = 'Klaviyo SMS', Family = 'SMS', Public_Facing_Name__c = 'Klaviyo SMS', Pricing_Type__c = 'Block Pricing');
        insert prod;

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;

        PricebookEntry customPrice = new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = prod.Id, UnitPrice = 12000, IsActive = true);
        insert customPrice;
        
        // Create test opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'S2: Validation', CloseDate = System.today().addDays(2), Pricebook2Id = customPB.Id);
        insert opp;
        
        // Create test product
        Product2 testProduct = new Product2(Name = 'Klaviyo Email', IsActive = true, StockKeepingUnit = 'TEST001', Public_Facing_Name__c = 'Klaviyo Email', Pricing_Type__c = 'Block Pricing');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Klaviyo SMS', IsActive = true, StockKeepingUnit = 'TEST002', Standard_Pricebook_Entry_Id__c = customPrice.Id, Public_Facing_Name__c = 'Klaviyo SMS3', Pricing_Type__c = 'Block Pricing');
        insert testProduct2;

        // Create test opportunity line item
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Quantity = 1, Usage_Limit__c = 10000, Discount = 5, Product2Id = testProduct.Id, TotalPrice= 10000, PricebookEntryId = customPrice.Id);
        try{                  
        insert oli;
        }catch(Exception ee){
            System.debug('Vinod : ' + ee.getMessage());
            System.debug('Vinod1 : ' + ee.getStackTraceString());
        }
        
        // Call the method to be tested
        Test.startTest();
        UpdateOpportunityProduct.getOpportunityProduct(opp.Id, 'OpportunityMPOFieldSet', 'OpportunityLineItem');
        
        List<UpdateOpportunityProduct.UpdateWrapper> listOfWrapperInstance = new List<UpdateOpportunityProduct.UpdateWrapper>();
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Id', oli.Id, 'REFERENCE'));
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Usage_Limit__c', null, 'INTEGER'));
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Product2Id', testProduct.Id, 'REFERENCE'));
        UpdateOpportunityProduct.updateProduct(JSON.serialize(listOfWrapperInstance));
        
        List<UpdateOpportunityProduct.UpdateAllWrapper> listOfAllWrapperInstance = new List<UpdateOpportunityProduct.UpdateAllWrapper>();
        listOfAllWrapperInstance.add(new UpdateOpportunityProduct.UpdateAllWrapper('1234', listOfWrapperInstance));
        UpdateOpportunityProduct.updateAllProduct(JSON.serialize(listOfAllWrapperInstance), null, opp.Id);
        
        listOfWrapperInstance = new List<UpdateOpportunityProduct.UpdateWrapper>();
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Id', '12345', 'REFERENCE'));
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Usage_Limit__c', null, 'INTEGER'));
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Product2Id', testProduct2.Id, 'REFERENCE'));
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Pricing_Override__c', 'true', 'BOOLEAN'));
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('ServiceDate', String.valueOf(System.today()), 'DATE'));
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Subscription_Refresh__c', String.valueOf(System.now()), 'DATETIME'));
        UpdateOpportunityProduct.updateProduct(JSON.serialize(listOfWrapperInstance));
        
        listOfAllWrapperInstance = new List<UpdateOpportunityProduct.UpdateAllWrapper>();
        listOfAllWrapperInstance.add(new UpdateOpportunityProduct.UpdateAllWrapper('1234', listOfWrapperInstance));
        Map<String, List<UpdateOpportunityProduct.UpdateWrapper>> mockmap1 = new Map<String, List<UpdateOpportunityProduct.UpdateWrapper>>();
        List<UpdateOpportunityProduct.UpdateWrapper> updateWrapperList1 = new List<UpdateOpportunityProduct.UpdateWrapper>{new UpdateOpportunityProduct.UpdateWrapper(oli.Id, 'Test Value', '')};
        mockMap1.put(opp.Id, updateWrapperList1);
        UpdateOpportunityProduct.updateAllProduct(JSON.serialize(listOfAllWrapperInstance), JSON.serialize(mockMap1), opp.Id);
        
        listOfWrapperInstance = new List<UpdateOpportunityProduct.UpdateWrapper>();
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Id', oli.Id, 'REFERENCE'));
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Usage_Limit__c', null, 'INTEGER'));
        listOfWrapperInstance.add(new UpdateOpportunityProduct.UpdateWrapper('Product2Id', '1234567891011', 'REFERENCE'));
        UpdateOpportunityProduct.updateProduct(JSON.serialize(listOfWrapperInstance));
        
        listOfAllWrapperInstance = new List<UpdateOpportunityProduct.UpdateAllWrapper>();
        listOfAllWrapperInstance.add(new UpdateOpportunityProduct.UpdateAllWrapper('1234', listOfWrapperInstance));
        UpdateOpportunityProduct.updateAllProduct(JSON.serialize(listOfAllWrapperInstance), JSON.serialize(mockMap1), opp.Id);
        
        // Create a map of product opportunity values
        Map<String, List<UpdateOpportunityProduct.UpdateWrapper>> mockmap = new Map<String, List<UpdateOpportunityProduct.UpdateWrapper>>();
        List<UpdateOpportunityProduct.UpdateWrapper> updateWrapperList = new List<UpdateOpportunityProduct.UpdateWrapper>{new UpdateOpportunityProduct.UpdateWrapper(oli.Id, 'Test Value', '')};
        mockMap.put(opp.Id, updateWrapperList);

        UpdateOpportunityProduct.deleteProduct(oli.Id, JSON.serialize(mockMap), opp.Id);
        UpdateOpportunityProduct.deleteProduct('1234', JSON.serialize(mockMap), opp.Id);
        UpdateOpportunityProduct.getAllOpportunityFields(opp.Id);
        UpdateOpportunityProduct.getAllOpportunityLIFields(oli.Id);
        Test.stopTest();
        
    }
}
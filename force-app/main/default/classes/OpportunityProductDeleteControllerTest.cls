@isTest
private class OpportunityProductDeleteControllerTest{

    @testSetup
    private static void testDeleteOpportunityProduct() {
        Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware', IsActive = true);
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = System.today(), Pricebook2Id = pricebookId);
        insert opp;
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Quantity = 1, Usage_Limit__c = 10000, Discount = 5, Product2Id = prod.Id, TotalPrice= 10000, PricebookEntryId = standardPrice.Id);
        insert oli;
    }
    
    @isTest
    static void testCheckUserProfile() {
        OpportunityLineItem oliRecord = [Select Id, OpportunityId From OpportunityLineItem Limit 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(oliRecord);
        OpportunityProductDeleteController controller = new OpportunityProductDeleteController(sc);
        PageReference testPage = Page.OpportuntiyProductCustomDelete;
        Test.setCurrentPage(testPage);
        ApexPages.currentPage().getParameters().put('id',oliRecord.Id);
        Test.startTest();
        OpportunityProductDeleteController.Close();
        OpportunityProductDeleteController.checkUserProfile();
        Test.stopTest();
    }
}
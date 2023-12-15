@isTest
public class OrderNetsuiteProcessorTest {
    @isTest
    private static void testOrderSync(){
        List<account>accList = new List<account>();
        List<opportunity>oppList = new List<opportunity>();
        List<Contract>contractList = new List<Contract>();
        List<Quote>quoteList = new List<Quote>();
        List<Order>orderList = new List<Order>();
        List<OrderItem>ordItemList = new List<OrderItem>();
        List<id>orderIds = new List<id>();
        
        //Create accounts
        for(integer i = 0; i<4;i++){
            accList.add(new Account(Name='Test Account' + i, Product_Klaviyo_Account_ID__c = 'ord123' + i));
        }
        insert accList;
        
        //Create Opportunities
        for(integer i = 0; i<4;i++){
            oppList.add(new Opportunity(Name='Test Opp' + i, AccountId=accList[i].Id, StageName='Closed Won', CloseDate=Date.today(), SALES_Ecommerce_Platform__c='Shopify'));
        }
        insert oppList;
        
        //Create Contracts
        //Service Contract
        contractList.add(new Contract(Name='Test Contract1', AccountId=accList[0].Id, Original_Opportunity__c = oppList[0].id, StartDate = Date.today(), Contract_Type__c = 'Service Order'));
        //A&R Contract for term reset
        contractList.add(new Contract(Name='Test Contract2', AccountId=accList[1].Id, Original_Opportunity__c = oppList[1].id, StartDate = Date.today(), Contract_Type__c = 'A&R'));
        //A&R Contract for co-term
        contractList.add(new Contract(Name='Test Contract3', AccountId=accList[2].Id, Original_Opportunity__c = oppList[2].id, StartDate = Date.today(), Contract_Type__c = 'A&R'));
        //Cancellation of Contract
        contractList.add(new Contract(Name='Test Contract4', AccountId=accList[3].Id, Original_Opportunity__c = oppList[3].id, StartDate = Date.today(), Contract_Type__c = 'A&R'));
        
        insert contractList;
        
        //Create Quotes
        quoteList.add(new Quote(Name = 'Test Quote 1', Contract_Type__c = 'Service Order', OpportunityId = oppList[0].id, BillingCountry = 'United States', BillingStreet = '125 Summer Street', BillingCity = 'Boston', BillingState= 'MA', BillingPostalCode = '01110'));
        quoteList.add(new Quote(Name = 'Test Quote 2', Contract_Type__c = 'A&R', OpportunityId = oppList[1].id, Amendment_Behavior__c = 'New Contract Term', BillingCountry = 'United States', BillingStreet = '125 Summer Street', BillingCity = 'Boston', BillingState= 'MA', BillingPostalCode = '01110'));
        quoteList.add(new Quote(Name = 'Test Quote 3', Contract_Type__c = 'A&R', OpportunityId = oppList[2].id, Amendment_Behavior__c = 'Co-Term with Existing', BillingCountry = 'United States', BillingStreet = '125 Summer Street', BillingCity = 'Boston', BillingState= 'MA', BillingPostalCode = '01110'));
        quoteList.add(new Quote(Name = 'Test Quote 4', Contract_Type__c = 'A&R', OpportunityId = oppList[3].id, Amendment_Behavior__c = 'New Contract Term', BillingCountry = 'United States', BillingStreet = '125 Summer Street', BillingCity = 'Boston', BillingState= 'MA', BillingPostalCode = '01110'));
        insert quoteList;
        
        //Create Product
        Product2 pro = new Product2(Name = '[Contract Only] Klaviyo Customer Platform', Pricing_Type__c = 'Unit Price', Public_Facing_Name__c = 'Klaviyo Customer Platform',
                                    Quantity_Type__c = 'Active Profiles');
        Insert pro;
        
        //Instantiate the Pricebook2 record with StandardPricebookId
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        
        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        Update standardPricebook;
        
        //Create the PricebookEntry
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = pro.Id,UnitPrice = 1020,IsActive = true);
        Insert pbe;
        
        //Create Order
        for(integer i = 0; i<4;i++){
            orderList.add(new Order(Name='Test Order'+ i, AccountId=accList[i].Id, OpportunityId = oppList[i].id, Status = 'Draft', 
                                    ContractId = contractList[i].id, EffectiveDate = Date.today(), QuoteId = quoteList[i].id, Pricebook2Id = standardPricebook.id));
        }
        insert orderList;
        
        //Create Order Line Item
        for(integer i = 0; i<4;i++){
            for(integer j = 0; j<2;j++){
                ordItemList.add(new OrderItem(OrderId = orderList[i].id,UnitPrice = 1000, Quantity = 1, Product2Id = pbe.id, Usage_Limit__c = 100));
            }
        }
        insert ordItemList;
        
        for(Order o:orderList){
            orderIds.add(o.id);
        }
        
        OrderNetsuiteProcessor.getOrderDetails(orderIds);
    }
    
}
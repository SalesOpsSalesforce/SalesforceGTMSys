//[RGaokar 10/03/2023 SFDC-3776 Sync order & order items to Netsuite]
//Considering there are less than 100 orders at a time Queueable apex is used
public class OrderNetsuiteProcessor{
    //Invocable method
    @invocableMethod(label = 'Order details for Netsuite Sync')
    public static void getOrderDetails(List<Id>orderIds){
        map <id, List<OrderItem>>orderItemMap = new map <id, List<OrderItem>>();//OrderId & retrieved Order Items
        List<NetsuitePayload> NetsuitePayloadList = new List<NetsuitePayload>();
        
        //Get order & order item fields for Netsuite sync
        List<Schema.FieldSetMember> orderFields = getOrderFields();
        List<Schema.FieldSetMember> ordLineItemFields = getOrderLineItemFields();
        
        //Get related Orders
        String orderQuery = 'SELECT ';
        for(Schema.FieldSetMember orderField : orderFields){
            orderQuery += orderField.getFieldPath() + ',';
        }
        orderQuery += 'Quote.Amendment_Behavior__c,Id FROM Order where id in :orderIds';
        List<Order> orderList = Database.query(orderQuery);
        
        //Get related Order line items
        String ordItemQuery = 'SELECT ';
        for(Schema.FieldSetMember ordLineItemField : ordLineItemFields){
            ordItemQuery += ordLineItemField.getFieldPath() + ',';
        }
        ordItemQuery += ' Id, orderId,Product2.Name FROM OrderItem where OrderId in :orderIds';
        List<OrderItem> orderItemList = Database.query(ordItemQuery);
        
        for(OrderItem oli:orderItemList){
            if (!orderItemMap.containsKey(oli.OrderId)){
                orderItemMap.put(oli.OrderId, new List<OrderItem>()); 
            }
            orderItemMap.get(oli.OrderId).add(oli);
        }
        
        //Event specific filters for line items sync
        //Event 1: Net New Customer / Reactivating / Customer moving from In App to Contracted: Send all OLI
        //Event 2: A&R Term Reset: Send OLI with Usage_Limit__c != 0
        //Event 3: Amendment, Co Term: Send HasCancelled__c & HasChanged__c OLI
        //Event 4: Cancellation of Contract: Send all OLI
        
        for(Order ord:orderList){
            List<OrderItem> NSorderItems = new List<OrderItem>();
            Boolean event4 = ord.Subscription_Cancelled__c && ord.Usage_Limit__c == 0;
            Boolean event1 = ord.Contract_Type__c != null && ord.Contract_Type__c.containsIgnoreCase('Service Order') && !event4;
            Boolean event2 = ord.Contract_Type__c != null && ord.Contract_Type__c == 'A&R' && ord.Quote.Amendment_Behavior__c != 'Co-Term with Existing' && !event4;
            Boolean event3 = ord.Contract_Type__c != null && ord.Contract_Type__c == 'A&R' && ord.Quote.Amendment_Behavior__c == 'Co-Term with Existing' && !event4; 
            
            system.debug('event1 --' +event1 + ', event2--'+event2 + ', event3--'+event3 + ', event4--'+event4);
            
            if((event1 || event4) && orderItemMap.containskey(ord.Id)){//Event 1 OR Event 4 
                NSorderItems.addAll(orderItemMap.get(ord.Id));
            }else if(event2 && orderItemMap.containskey(ord.Id)){//Event 2
                for(OrderItem ordItem :orderItemMap.get(ord.Id)){
                    if(ordItem.Usage_Limit__c != 0){
                        NSorderItems.add(ordItem); 
                    }
                }
            }else if (event3 && orderItemMap.containskey(ord.Id)){//Event 3
                for(OrderItem ordItem :orderItemMap.get(ord.Id)){
                    if(ordItem.HasCancelled__c || ordItem.Has_Changed__c){
                        NSorderItems.add(ordItem); 
                    }
                }
            }else if(ord.Netsuite_Sync_Failed__c && orderItemMap.containskey(ord.Id)){//Failed order recovery
                for(OrderItem ordItem :orderItemMap.get(ord.Id)){
                    if(ordItem.Netsuite_Sync_Failed__c){//add failed ord items
                        NSorderItems.add(ordItem); 
                    }
                }
            }
            
            //Create NS Payload
            NetsuitePayload payload = new NetsuitePayload(ord,NSorderItems);
            NetsuitePayloadList.add(payload); 
        }
        
        //Send Netsuite payload to Workato
        if(!NetsuitePayloadList.isEmpty()){
            system.enqueueJob(new OrderNetsuiteCallout(NetsuitePayloadList));
        }
    }
    
    
    //Wrapper class to hold payload
    public class NetsuitePayload{
        public Order order {get;set;}
        public List<OrderItem> orderItem{get; set;}
        public NetsuitePayload(Order order, List<OrderItem> orderItem) {
            this.order = order;
            this.orderItem = orderItem;
        }  
    }
    
    //Get order fields
    public static List<Schema.FieldSetMember> getOrderFields() {
        return SObjectType.Order.FieldSets.Order_NetSuite_Sync.getFields();
    }
    
    //Get order item fields
    public static List<Schema.FieldSetMember> getOrderLineItemFields() {
        return SObjectType.OrderItem.FieldSets.OrdLineItem_NetSuite_Sync.getFields();
    }
    
}
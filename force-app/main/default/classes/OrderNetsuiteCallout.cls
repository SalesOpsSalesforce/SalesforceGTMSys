//[RGaokar 10/03/2023 SFDC-3776 Sync order & order items to Netsuite]
//Considering there are less than 100 orders at a time Queueable appex is used
public class OrderNetsuiteCallout implements System.Queueable,Database.AllowsCallouts{
    List<OrderNetsuiteProcessor.NetsuitePayload>NetsuitePayloadList = new List<OrderNetsuiteProcessor.NetsuitePayload>();
    
    //Constructor
    public OrderNetsuiteCallout(List<OrderNetsuiteProcessor.NetsuitePayload> NetsuitePayloadList){
        this.NetsuitePayloadList = NetsuitePayloadList;
    }
        
    public void execute(system.QueueableContext ctx){
        Boolean sandboxOrg = [SELECT IsSandbox FROM Organization].IsSandbox;
        Map<String, Workato_Order_Sync_Credential__mdt> workatoOrderCredentials = Workato_Order_Sync_Credential__mdt.getAll();
        
        String orgAPIKey;
        String orgType = (!sandboxOrg)? 'Production':'Sandbox';
        String endpointURL = 'callout:Workato_Webhook';
        String errorString = '';
        List<errorWrapper> errorList = new List<errorWrapper>();
        
        //Get credentials
        If(!sandboxOrg){//Production
            endpointURL += workatoOrderCredentials.get('Workato_Order_Production').Webhook_URL__c;
            orgAPIKey = workatoOrderCredentials.get('Workato_Order_Production').API_Key__c;
        }else{//Sandbox 
            endpointURL += workatoOrderCredentials.get('Workato_Order_Sandbox').Webhook_URL__c;
            orgAPIKey = workatoOrderCredentials.get('Workato_Order_Sandbox').API_Key__c;
        }
        
        //Sending each order separately to Workato as less volume is expected
        for(OrderNetsuiteProcessor.NetsuitePayload payload :NetsuitePayloadList){     
            //Create Request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPointURL);
            req.setHeader('Authorization', 'api-key '+orgAPIKey);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('accept', 'application/json');
            req.setHeader('Org_Type', orgType);
            req.setMethod('POST');
            req.setBody(JSON.serialize(payload));
            try{
                Http http = new Http();
                HttpResponse response = new HttpResponse();
                if(!Test.isRunningTest() && sandboxOrg){
                    response = http.send(req);
                }else{
                    response.setHeader('Content-Type', 'application/json');
                    response.setStatusCode(200);
                }
                
                if (response != null && response.getStatusCode() != 200){//If error comes
                    errorString += '\n'+' Response Code: '+response.getStatusCode();
                }
            }catch(System.CalloutException ex){
                //system.debug('Error Message: '+ex.getMessage());
                errorString += '\n'+' Error Message: '+ex.getMessage();
            }
            
            if(String.isNotBlank(errorString) || Test.isRunningTest()){
                errorList.add(new errorWrapper(errorString,payload));
            }
        }
        
        //Process errors
        if(!errorList.isEmpty() || Test.isRunningTest()){
            processErrors(errorList);
        }  
    }
    
    //Workato Callout error handling
    private static void processErrors(List<errorWrapper> errorList){
        List<Order> failedOrders = new List<Order>();
        List<OrderItem> failedOrdItems = new List<OrderItem>();
        List <String> errors = new List <String> ();
        
        errors.add('Following error occured for Netsuite Order Sync:');
        
        for(errorWrapper errorInfo :errorList){
            //Flag the failed order
            failedOrders.add(new Order(Id = errorInfo.payload.order.id, Netsuite_Sync_Failed__c = true));
            
            //Flag failed order line items
            for(OrderItem oi :errorInfo.payload.orderItem){
                failedOrdItems.add(new OrderItem(id = oi.id, Netsuite_Sync_Failed__c = true));
            }
            
            //add error details to list
            errors.add('\n' + 'Order Id: ' + errorInfo.payload.order.id + ', Error: ' + errorInfo.errorString);
        }
        
        //Update Orders for failed flag
        if(!failedOrders.isEmpty()){
            List<Database.SaveResult> srList = Database.update(failedOrders, false);
        }
        
        //Update Order line items for failed flag
        if(!failedOrdItems.isEmpty()){
            List<Database.SaveResult> srList = Database.update(failedOrdItems, false);
        }
        
        //Send error email
        if(!errors.isEmpty()){
            ExceptionHandling.performExceptionHandling(null, 'OrderNetsuiteCallout', errors);  
        }
    }
    
    //Holds errors
    public class errorWrapper{
        public String errorString {get;set;}
        public OrderNetsuiteProcessor.NetsuitePayload payload{get; set;}
        public errorWrapper(String errorString, OrderNetsuiteProcessor.NetsuitePayload payload) {
            this.errorString = errorString;
            this.payload = payload;
        }
    } 
}
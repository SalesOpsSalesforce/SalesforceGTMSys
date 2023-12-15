/* [vrajapatruni 03/02/2021] This is a batch class for Stamp_Sales_Initial_Touch_Time */

public class Stamp_Sales_Initial_Touch_Time_Batch implements Database.Batchable<sObject> {
        
        public List<Id> listLeadIds;
       
        public Stamp_Sales_Initial_Touch_Time_Batch(List<Id> listLeadIds){
        
            this.listLeadIds = listLeadIds;
            
        }

        public Database.QueryLocator start(Database.BatchableContext bc) {
        
            return Database.getQueryLocator('SELECT Id, Status, CreatedDate, FLOW_Time_of_Initial_Touch__c from Lead where Id in :listLeadIds');
            
        }
        public void execute(Database.BatchableContext bc, List<Lead> leadList){
                     
                for (Lead l : leadList) {
                      if(l.Status <> 'Untouched' && l.FLOW_Time_of_Initial_Touch__c == Null &&  l.CreatedDate <> Null && l.CreatedDate >= datetime.valueOf('2016-01-20 00:00:00')){
                                   
                        l.FLOW_Time_of_Initial_Touch__c = DateTime.now();
                        
                    }
                }    
                
                List <String> executionFlow = new List <String> ();
                try{      
                    
                    update leadList;
                    
                }
                
                catch(Exception e){
                
                     ExceptionHandling.performExceptionHandling(e, 'Stamp_Sales_Initial_Touch_Time_Batch', executionFlow);
                     
                }    
           
            }
           
        public void finish(Database.BatchableContext bc){
            
        }
}
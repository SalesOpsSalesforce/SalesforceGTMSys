//[RGaokar 04/28/2023 SFDC-2516 This batch associate partner payouts with aggregate payouts. 
//Keeping associataion in batches to avoid too many DML rows error 10001, as there could be large number of payouts]
//[RGaokar 09/05/2023 SFDC-3349 10K DML row error resolution]
public class PartnerAggregatePayoutAssociationBatch implements Database.Batchable<sObject>{
    set<id> partnerPayoutIds = new set<id>();
    map<id, Map<String, Id>> partnerAccAggregatePayoutMap = new map<id, Map<String, Id>>();
    set<id>aggregatePayoutIds = new set<id>();
    
    public PartnerAggregatePayoutAssociationBatch(set<id> partnerPayoutIds, map<id, Map<String, Id>> partnerAccAggregatePayoutMap, set<id>aggregatePayoutIds){
        this.partnerPayoutIds = partnerPayoutIds;
        this.partnerAccAggregatePayoutMap = partnerAccAggregatePayoutMap;
        this.aggregatePayoutIds = aggregatePayoutIds;
    }
    public Database.QueryLocator start (Database.BatchableContext bc){
        String query = 'Select id, Partner_Account__c,Partner_Split__r.Partner_Type__c from Partner_Payout__c where id in :partnerPayoutIds';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        List<Partner_Payout__c> updatePayouts = new List<Partner_Payout__c>();
        string errorString = '';
        
        for(Partner_Payout__c payout:(List<Partner_Payout__c>)scope){
            if(partnerAccAggregatePayoutMap.containsKey(payout.Partner_Account__c) && partnerAccAggregatePayoutMap.get(payout.Partner_Account__c).containsKey(payout.Partner_Split__r.Partner_Type__c)){
                payout.Partner_Aggregate_Payout__c = partnerAccAggregatePayoutMap.get(payout.Partner_Account__c).get(payout.Partner_Split__r.Partner_Type__c);
                updatePayouts.add(payout);
            }
        }
        
        if(!updatePayouts.isEmpty()){
            List<Database.SaveResult> srList = Database.update(updatePayouts, false);
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    errorString += '\n' + 'The following error occurred when associating Partner Payout with Aggregate Payout';
                    for(Database.Error err: result.getErrors()){
                        errorString += ' Partner Payout: ' +result.getId() +' Error Message: ' +err.getMessage()+'\n';
                    }
                }   
            }
        }
        
        //Error handling
        if(String.isNotBlank(errorString) || Test.isRunningTest()){
            List<string>errorList = new List<string>();
            errorList.add('Errors occured during Aggregate Payouts Association with Aggregate Payout: ');
            errorList.add(errorString);
            ExceptionHandling.performExceptionHandling(null, 'PartnerAggregatePayoutAssociationBatch', errorList);  
        }
    }
    
    public void finish(Database.BatchableContext bc){
        //Call batch job to calculate aggregate payout per partner per partner type
        PartnerAggregateAmountCalculationBatch aggAmtCalculationBatch = new PartnerAggregateAmountCalculationBatch(aggregatePayoutIds);
        Database.executeBatch(aggAmtCalculationBatch);
    }
    
}
//[RGaokar 04/28/2023 SFDC-2516 This batch creates partner aggregate payouts]
//[RGaokar 09/05/2023 SFDC-3349 10K DML row error resolution]
public class PartnerAggregatePayoutBatch implements Database.Batchable<sObject>, Database.Stateful{
    //Stores partner account id & related partner payouts
    set<id> referralPartnerAccountIds = new set<id>();
    set<id> managedPartnerAccountIds = new set<id>();
    set<id> platformPartnerAccountIds = new set<id>();
    map<Id, Partner_Payout__c> partnerPayoutMap = new map<Id, Partner_Payout__c>();
    
    public Database.QueryLocator start (Database.BatchableContext bc){
        String query = 'Select id,Partner_Account__c,Payment_Date__c,Payout_Amount__c,Partner_Split__r.Partner_Type__c from Partner_Payout__c';
        query += ' where Payment_Date__c = Last_Month Order By Partner_Account__c, Partner_Split__r.Partner_Type__c';
        return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext bc, List<sObject>scope){
        //Seperate Partner account per Partner type
        partnerPayoutMap.putAll((List<Partner_Payout__c>)scope);
        for(Partner_Payout__c payout:(List<Partner_Payout__c>)scope){
            if(payout.Partner_Split__r.Partner_Type__c == 'Referral Partner'){
                referralPartnerAccountIds.add(payout.Partner_Account__c);  
            }else if(payout.Partner_Split__r.Partner_Type__c == 'Managed'){
                managedPartnerAccountIds.add(payout.Partner_Account__c);  
            }else if(payout.Partner_Split__r.Partner_Type__c == 'Platform Partner'){
                platformPartnerAccountIds.add(payout.Partner_Account__c); 
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        //Create Partner Aggregate Payouts
        List<Partner_Aggregate_Payout__c> aggregatePayouts = new List<Partner_Aggregate_Payout__c>();
        string errorString = '';
        //Stores Partner Account & related Aggregate Payout id per partner type
        map<id, Map<String, Id>> partnerAccAggregatePayoutMap = new map<id, Map<String, Id>>();// map<Partner account id, map<Partner Type, Partner aggregate payout id>>
        set<id>aggregatePayoutIds = new set<id>();
        
        if(!referralPartnerAccountIds.isEmpty()){
            aggregatePayouts.addAll(createAggregatePayouts(referralPartnerAccountIds, 'Referral Partner'));
        }
        
        if(!managedPartnerAccountIds.isEmpty()){
            aggregatePayouts.addAll(createAggregatePayouts(managedPartnerAccountIds, 'Managed'));
        }
        
        if(!platformPartnerAccountIds.isEmpty()){
            aggregatePayouts.addAll(createAggregatePayouts(platformPartnerAccountIds, 'Platform Partner'));
        }
        
        if(!aggregatePayouts.isEmpty()){
            List<Database.SaveResult> srList = Database.insert(aggregatePayouts, false);
            for(Database.SaveResult result:srList){
                if(!result.isSuccess()){
                    errorString += '\n' + 'The following error occurred during Partner Aggregate Payout record creation';
                    for(Database.Error err: result.getErrors()){
                        errorString += ' Error Message: ' +err.getMessage()+'\n';
                    } 
                }
            }
            
            //Associate payouts with partner aggregate payouts & send for batch processing to avoid DML rows error 10001.
            for(Partner_Aggregate_Payout__c aggPayout: aggregatePayouts){
                aggregatePayoutIds.add(aggPayout.id);
                if(!partnerAccAggregatePayoutMap.containsKey(aggPayout.Partner_Account__c)){
                    partnerAccAggregatePayoutMap.put(aggPayout.Partner_Account__c,new Map<String, Id>());
                }
                if(aggPayout.Partner_Type__c == 'Referral Partner'){
                    partnerAccAggregatePayoutMap.get(aggPayout.Partner_Account__c).put('Referral Partner',aggPayout.id);// As there is only one aggregate payout per type, type is key for inner map   
                }else if(aggPayout.Partner_Type__c == 'Managed'){
                    partnerAccAggregatePayoutMap.get(aggPayout.Partner_Account__c).put('Managed',aggPayout.id);   
                }else if(aggPayout.Partner_Type__c == 'Platform Partner'){
                    partnerAccAggregatePayoutMap.get(aggPayout.Partner_Account__c).put('Platform Partner',aggPayout.id);   
                }
            }  
        }
        
        if(String.isNotBlank(errorString) || Test.isRunningTest()){
            List<string>errorList = new List<string>();
            errorList.add('Errors occured during Aggregate Payouts Processing: ');
            errorList.add(errorString);
            ExceptionHandling.performExceptionHandling(null, 'PartnerAggregatePayoutBatch', errorList);  
        }
        
        if(!partnerAccAggregatePayoutMap.isEmpty()){
            PartnerAggregatePayoutAssociationBatch aggPayoutAssociationBatch = new PartnerAggregatePayoutAssociationBatch(partnerPayoutMap.keyset(),partnerAccAggregatePayoutMap,aggregatePayoutIds);
            Database.executeBatch(aggPayoutAssociationBatch);
        }
    }
    
    public static List<Partner_Aggregate_Payout__c> createAggregatePayouts(Set<id>partnerAccIds, string partnerType){
        List<Partner_Aggregate_Payout__c> aggregatePayoutList = new List<Partner_Aggregate_Payout__c>();
        for(id partnerAccId : partnerAccIds){
            Partner_Aggregate_Payout__c aggPayout = new Partner_Aggregate_Payout__c(Partner_Account__c = partnerAccId, Partner_Type__c = partnerType, 
                                                                                    Payment_Date__c = Date.today());
            aggregatePayoutList.add(aggPayout);   
        }
        
        return aggregatePayoutList;
    }
    
}
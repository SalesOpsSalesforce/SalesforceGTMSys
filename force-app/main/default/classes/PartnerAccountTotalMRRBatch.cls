//Batch manual run command from dev console: Database.executeBatch(new PartnerAccountTotalMRRBatch(), 10);
//[RGaokar 03/21/2022 112401 Scheduler for Partner Splits Totals Calulation on Related Partner Accounts]
//Runs every night on eligible Partner Account records
//[RGaokar 06/23/2023 SFDC-2898 Changes related to Reviews MRR Attributed to Agency Last Year]
public class PartnerAccountTotalMRRBatch implements Database.Batchable<sObject>{
    
    // [vrajapatruni 06/21/2023 SFDC-3016] Commented the below line as its no longer needed
    // public static final Set<String> SMS_Product_Family = new Set<String>{'SMS Subscription', 'US Short Code', 'US Vanity Short Code', 'CA Short Code', 'CA Vanity Short Code', 'Short Code Subscription'};
    
    //[vrajapatruni 10/12/2022 SFDC-889] Added partner types Technology Partner and Investment Firm. Dint include Platform Partner as Shopify Inc account have 50k+ query results.
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Get eligible partner accounts
        String query = 'select Id, ParentId, Actual_MRR_Attributed__c, Credited_MRR__c, Managed_MRR__c from Account';
        query += ' where (Partner_Type__c = \'Advisors\' OR Partner_Type__c = \'Influencers\' OR Partner_Type__c = \'Masters\' OR Partner_Type__c = \'Technology Partner\' OR Partner_Type__c = \'Investment Firm\')';
        query += ' AND First_Partner_Split_Created__c != null'; //[jrodden 11/03/2022 SFDC-1140] Replaced Max_Partner_Split_Created_Date__c with First_Partner_Split_Created__c 
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account>scope){
        List<Account> parentIds = (List<Account>)scope;
        Map<Id, Decimal> mapOfOptyAmount = new Map<Id, Decimal>();
        Map<Id, Decimal> mapOfSMSOptyAmount = new Map<Id, Decimal>();
        Map<Id, Decimal> mapOfReviewsOptyAmount = new Map<Id, Decimal>();
        Map<Id, Decimal> mapOfCDPOptyAmount = new Map<Id, Decimal>();
        Map<Id, Account> mapOfAccount = new Map<Id, Account>();
        Map<Id, AggregateResult> mapOfAggregate = new Map<Id, AggregateResult>();
        
        //Get Partner MRR totals from partner splits related to eligible partners
        List<AggregateResult> aggrResults = [SELECT Partner_Account__c, SUM(Actual_MRR__c)sumActual, SUM(Credited_MRR__c)sumCredited, SUM(Managed_MRR__c)sumManaged FROM Partner_Split__c
                                             where Partner_Account__c in :(List<Account>)scope AND
                                             ((Eligible_for_Attribution_Credit__c = true AND (Actual_MRR__c != 0 OR Credited_MRR__c != 0))
                                             OR (Eligible_for_Managed_MRR_Credit__c = true AND Managed_MRR__c != 0)) 
                                             Group By Partner_Account__c];
        
        //[vrajapatruni 02/07/2023 SFDC-1581] MRR Attributed in Last Year and SMS MRR in Last Year are best calculated via splits instead of opps (influence opps not attributing correctly)
        //Get sum of all Opportunity Amounts from partner splits related to eligible partners
        //[vrajapatruni 06/21/2023 SFDC-3016] Replace SUM(Opportunity__r.Amount)sumAmount with Credited_MRR__c
        List<AggregateResult> aggrResultsOptyAmount = [SELECT Partner_Account__c, SUM(Credited_MRR__c)sumAmount 
                                                       FROM Partner_Split__c
                                                       WHERE Partner_Account__c in :(List<Account>)scope 
                                                       AND Eligible_for_Attributed_Agency_in_LY__c = true 
                                                       Group By Partner_Account__c];
        
        //Get sum of SMS Opportunity Amounts from partner splits related to eligible partners
        //[vrajapatruni 06/21/2023 SFDC-3016] Replace SUM(Opportunity__r.Amount)sumAmount with Credited_MRR__c
        //Update query to use SMS product family for line items. 
        //Replace AND Opportunity__r.Opportunity_Product__c in: SMS_Product_Family  
        //with AND Product_Family__c = 'SMS'                                                
        List<AggregateResult> aggrResultsSMSOptyAmount = [SELECT Partner_Account__c, SUM(Credited_MRR__c)sumSMSAmount 
                                                          FROM Partner_Split__c
                                                          WHERE Partner_Account__c in :(List<Account>)scope 
                                                          AND Eligible_for_Attributed_Agency_in_LY__c = true
                                                          AND Product_Family__c = 'SMS'  
                                                          Group By Partner_Account__c];
        
        //[RGaokar 06/23/2023 SFDC-2898 Changes related to Reviews MRR Attributed to Agency Last Year]
        //Get total Credited_MRR__c of related Partner splits associated with Klaviyo reviews & eligible for attributed agency in last year
        List<AggregateResult> aggrResultsReviewsOptyAmount = [SELECT Partner_Account__c, SUM(Credited_MRR__c)sumReviewsAmount 
                                                          FROM Partner_Split__c
                                                          WHERE Partner_Account__c in :(List<Account>)scope 
                                                          AND Eligible_for_Attributed_Agency_in_LY__c = true
                                                          AND Product_Family__c = 'Klaviyo Reviews'  
                                                          Group By Partner_Account__c];
        
        //[VRajapatruni 11/20/2023 SFDC-3956 Changes related to CDP MRR Attributed to Agency Last Year]
        //Get total Credited_MRR__c of related Partner splits associated with CDP & eligible for attributed agency in last year
        List<AggregateResult> aggrResultsCDPOptyAmount = [SELECT Partner_Account__c, SUM(Credited_MRR__c)sumCDPAmount 
                                                          FROM Partner_Split__c
                                                          WHERE Partner_Account__c in :(List<Account>)scope 
                                                          AND Eligible_for_Attributed_Agency_in_LY__c = true
                                                          AND Product_Family__c = 'CDP'  
                                                          Group By Partner_Account__c];
        
        for(AggregateResult arRecord : aggrResultsOptyAmount){
            mapOfOptyAmount.put((Id)arRecord.get('Partner_Account__c'), (Decimal)arRecord.get('sumAmount'));
        }
        for(AggregateResult arRecord : aggrResultsSMSOptyAmount){
            mapOfSMSOptyAmount.put((Id)arRecord.get('Partner_Account__c'), (Decimal)arRecord.get('sumSMSAmount'));
        }
        
        for(AggregateResult ar:aggrResults){
            mapOfAggregate.put((Id)ar.get('Partner_Account__c'), ar);
        }
        
        //[RGaokar 06/23/2023 SFDC-2898 Changes related to Reviews MRR Attributed to Agency Last Year]
        //Extending in same line with Vinod's code
        for(AggregateResult arRecord : aggrResultsReviewsOptyAmount){
            mapOfReviewsOptyAmount.put((Id)arRecord.get('Partner_Account__c'), (Decimal)arRecord.get('sumReviewsAmount'));
        }
        
        //[VRajapatruni 11/20/2023 SFDC-3956 Changes related to CDP MRR Attributed to Agency Last Year]
        for(AggregateResult arRecord : aggrResultsCDPOptyAmount){
            mapOfCDPOptyAmount.put((Id)arRecord.get('Partner_Account__c'), (Decimal)arRecord.get('sumCDPAmount'));
        }
        
        
        Account a = new Account();
        //Given an eligible partner account has an eligible partner split, the partner totals are set accordingly otherwise marked as 0
        for(Account accountRecord : parentIds){
            a = new Account();
            a.Id = accountRecord.Id;
            if(mapOfAggregate.containskey(accountRecord.Id)){
                a.Actual_MRR_Attributed__c = (Decimal)(mapOfAggregate.get(accountRecord.Id).get('sumActual'));
                a.Credited_MRR__c = (Decimal)(mapOfAggregate.get(accountRecord.Id).get('sumCredited'));
                a.Managed_MRR__c = (Decimal)(mapOfAggregate.get(accountRecord.Id).get('sumManaged'));
            }else{
                a.Actual_MRR_Attributed__c = 0;
                a.Credited_MRR__c = 0;
                a.Managed_MRR__c = 0;
            }
            a.PartnerTotalsLastRun__c = Date.today();
            if(mapOfOptyAmount.containskey(a.id)){
                a.FLOW_MRRAttributedtoAgencyinLastYear__c = mapOfOptyAmount.get(a.id);
            }else{
                a.FLOW_MRRAttributedtoAgencyinLastYear__c = 0;
            }
            if(mapOfSMSOptyAmount.containskey(a.id)){
                a.SMS_MRR_Attributed_to_Agency_Last_Year__c = mapOfSMSOptyAmount.get(a.id);
            }else{
                a.SMS_MRR_Attributed_to_Agency_Last_Year__c = 0;
            }
            
            //[RGaokar 06/23/2023 SFDC-2898 Changes related to Reviews MRR Attributed to Agency Last Year]
        	//Extending in same line with Vinod's code
            if(mapOfReviewsOptyAmount.containskey(a.id)){
                a.Reviews_MRR_Attributed_to_Agency_Last_Yr__c  = mapOfReviewsOptyAmount.get(a.id);
            }else{
                a.Reviews_MRR_Attributed_to_Agency_Last_Yr__c = 0;
            }
            
            //[VRajapatruni 11/20/2023 SFDC-3956 Changes related to CDP MRR Attributed to Agency Last Year]
            if(mapOfCDPOptyAmount.containskey(a.id)){
                a.CDP_MRR_Attributed_to_Agency_Last_Yr__c  = mapOfCDPOptyAmount.get(a.id);
            }else{
                a.CDP_MRR_Attributed_to_Agency_Last_Yr__c = 0;
            }
            
            mapOfAccount.put(a.Id, a);
        }
        for(String key : mapOfOptyAmount.keySet()){
            if(!mapOfAccount.containskey(key)){
                mapOfAccount.put((Id)key, new Account(Id = (Id)key, FLOW_MRRAttributedtoAgencyinLastYear__c = mapOfOptyAmount.get(key)));
            }
        }
        for(String key : mapOfSMSOptyAmount.keySet()){
            if(!mapOfAccount.containskey(key)){
                mapOfAccount.put((Id)key, new Account(Id = (Id)key, SMS_MRR_Attributed_to_Agency_Last_Year__c = mapOfSMSOptyAmount.get(key)));
            }
        }
        for(String key : mapOfSMSOptyAmount.keySet()){
            if(!mapOfAccount.containskey(key)){
                mapOfAccount.put((Id)key, new Account(Id = (Id)key, CDP_MRR_Attributed_to_Agency_Last_Yr__c = mapOfCDPOptyAmount.get(key)));
            }
        }
        
        //[RGaokar 06/23/2023 SFDC-2898 Changes related to Reviews MRR Attributed to Agency Last Year]
        //The above for loop is not required as the all aggregate queries are run against all partners retrieved in start method, 
        //& there is already looping for those retreievd partner, so not adding this additional for loop for review
        
        
        //Update the database with the new MRR totals 
        if(!mapOfAccount.isEmpty()){            
            List<Database.SaveResult> srList = Database.update(mapOfAccount.values(), false);
            String errorString;
            for(Database.SaveResult sr:srList){
                //Handle errors if update fails
                if(!sr.isSuccess() || Test.isRunningTest()){
                    errorString =+ '\n'+sr.getId();
                    for(Database.Error err : sr.getErrors()) {
                        errorString =+ ': '+err.getMessage()+'\n';
                    }
                    system.debug('errorString--'+errorString);   
                }  
            }
            //Create expection record for errors
            if(String.isNotBlank(errorString) || Test.isRunningTest()){
                List <String> executionFlow = new List <String> ();
                executionFlow.add('Errors occured when updating Partner Split totals on account:');
                executionFlow.add(errorString);
                ExceptionHandling.performExceptionHandling(null, 'PartnerAccountTotalMRRBatch', executionFlow);
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        //[vrajapatruni 02/07/2023 SFDC-603, SFDC-1561, SFDC-1581] Parent-Child roll up for only 1 Level  with volume not more than 10000 accounts
        Map<Id, Account> mapOfParentAccount = new Map<Id, Account>();
        Map<Id, List<Account>> mapOfChildAccount = new Map<Id, List<Account>>();
        
        //Retrieve all the eligible accounts
        List<Account> listAllRelatedParentAccount = [SELECT Id, ParentId, Actual_MRR_Attributed__c, Credited_MRR__c, Managed_MRR__c, 
                                                     FLOW_MRRAttributedtoAgencyinLastYear__c, SMS_MRR_Attributed_to_Agency_Last_Year__c, Reviews_MRR_Attributed_to_Agency_Last_Yr__c, CDP_MRR_Attributed_to_Agency_Last_Yr__c
                                                     FROM Account 
                                                     WHERE Partner_Type__c  IN ('Advisors', 'Influencers', 'Masters', 'Technology Partner', 'Investment Firm') 
                                                     AND First_Partner_Split_Created__c != null];
                                                     
        //List parent and child accounts into two maps separately
        if(!listAllRelatedParentAccount.isEmpty()){
            for(Account accountRecord : listAllRelatedParentAccount){
                if(String.isEmpty(accountRecord.ParentId)){
                    mapOfParentAccount.put(accountRecord.Id, accountRecord);
                }
            }
            for(Account accountRecord : listAllRelatedParentAccount){
                if(!String.isEmpty(accountRecord.ParentId)){
                    if(mapOfChildAccount.containskey(accountRecord.ParentId)){
                        mapOfChildAccount.get(accountRecord.ParentId).add(accountRecord);
                    }else{
                        mapOfChildAccount.put(accountRecord.ParentId, new List<Account>{accountRecord});
                    }
                }
            }
            
            //Roll up child values their corresponding parents
            for(String accountKey : mapOfParentAccount.keyset()){
                if(mapOfChildAccount.containskey(accountKey)){
                    for(Account accountRecord : mapOfChildAccount.get(accountKey)){
                        if(mapOfParentAccount.get(accountKey).Actual_MRR_Attributed__c == null)
                            mapOfParentAccount.get(accountKey).Actual_MRR_Attributed__c = 0;
                        if(accountRecord.Actual_MRR_Attributed__c == null)
                            accountRecord.Actual_MRR_Attributed__c = 0;
                        mapOfParentAccount.get(accountKey).Actual_MRR_Attributed__c = accountRecord.Actual_MRR_Attributed__c + mapOfParentAccount.get(accountKey).Actual_MRR_Attributed__c;
                        if(mapOfParentAccount.get(accountKey).Credited_MRR__c == null)
                            mapOfParentAccount.get(accountKey).Credited_MRR__c = 0;
                        if(accountRecord.Credited_MRR__c == null)
                            accountRecord.Credited_MRR__c = 0;
                        mapOfParentAccount.get(accountKey).Credited_MRR__c = accountRecord.Credited_MRR__c + mapOfParentAccount.get(accountKey).Credited_MRR__c;
                        if(mapOfParentAccount.get(accountKey).Managed_MRR__c == null)
                            mapOfParentAccount.get(accountKey).Managed_MRR__c = 0;
                        if(accountRecord.Managed_MRR__c == null)
                            accountRecord.Managed_MRR__c = 0;
                        mapOfParentAccount.get(accountKey).Managed_MRR__c = accountRecord.Managed_MRR__c + mapOfParentAccount.get(accountKey).Managed_MRR__c;
                        if(accountRecord.FLOW_MRRAttributedtoAgencyinLastYear__c == null)
                            accountRecord.FLOW_MRRAttributedtoAgencyinLastYear__c = 0;
                        mapOfParentAccount.get(accountKey).FLOW_MRRAttributedtoAgencyinLastYear__c = accountRecord.FLOW_MRRAttributedtoAgencyinLastYear__c + mapOfParentAccount.get(accountKey).FLOW_MRRAttributedtoAgencyinLastYear__c;
                        if(accountRecord.SMS_MRR_Attributed_to_Agency_Last_Year__c == null)
                            accountRecord.SMS_MRR_Attributed_to_Agency_Last_Year__c = 0;
                        mapOfParentAccount.get(accountKey).SMS_MRR_Attributed_to_Agency_Last_Year__c = accountRecord.SMS_MRR_Attributed_to_Agency_Last_Year__c + mapOfParentAccount.get(accountKey).SMS_MRR_Attributed_to_Agency_Last_Year__c;
                        
                        //[RGaokar 06/23/2023 SFDC-2898 Changes related to Reviews MRR Attributed to Agency Last Year]
        				//Extending in same line with Vinod's code
                        if(mapOfParentAccount.get(accountKey).Reviews_MRR_Attributed_to_Agency_Last_Yr__c == null)
                            mapOfParentAccount.get(accountKey).Reviews_MRR_Attributed_to_Agency_Last_Yr__c = 0;
                        if(accountRecord.Reviews_MRR_Attributed_to_Agency_Last_Yr__c == null)
                            accountRecord.Reviews_MRR_Attributed_to_Agency_Last_Yr__c = 0;
                        mapOfParentAccount.get(accountKey).Reviews_MRR_Attributed_to_Agency_Last_Yr__c = accountRecord.Reviews_MRR_Attributed_to_Agency_Last_Yr__c + mapOfParentAccount.get(accountKey).Reviews_MRR_Attributed_to_Agency_Last_Yr__c;
                    
                        //[VRajapatruni 11/20/2023 SFDC-3956 Changes related to CDP MRR Attributed to Agency Last Year]
                        if(mapOfParentAccount.get(accountKey).CDP_MRR_Attributed_to_Agency_Last_Yr__c == null)
                            mapOfParentAccount.get(accountKey).CDP_MRR_Attributed_to_Agency_Last_Yr__c = 0;
                        if(accountRecord.CDP_MRR_Attributed_to_Agency_Last_Yr__c == null)
                            accountRecord.CDP_MRR_Attributed_to_Agency_Last_Yr__c = 0;
                        mapOfParentAccount.get(accountKey).CDP_MRR_Attributed_to_Agency_Last_Yr__c = accountRecord.CDP_MRR_Attributed_to_Agency_Last_Yr__c + mapOfParentAccount.get(accountKey).CDP_MRR_Attributed_to_Agency_Last_Yr__c;
                    }
                }
            }
            if(!mapOfParentAccount.isEmpty()){
                PartnerParentMRRRollup parentRollupUpdateBatch = new PartnerParentMRRRollup(mapOfParentAccount);
                Database.executeBatch(parentRollupUpdateBatch, 50);
            }
        }
    }
    
}
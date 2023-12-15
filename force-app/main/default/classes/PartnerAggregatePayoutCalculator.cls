//[RGaokar 04/28/2023 SFDC-2516 This invocable apex runs from Partner_Aggregate_Payout_Calculator_Flow to roll up the Partner Payouts to Parther Aggregate Payouts]
public class PartnerAggregatePayoutCalculator { 
    @invocableMethod(label='Partner Aggregate Payout Calculation')
    public static void calculateAggregatePayout(){
        PartnerAggregatePayoutEOMBatch EOMBatch = new PartnerAggregatePayoutEOMBatch();
        Database.executeBatch(EOMBatch);
    }
}
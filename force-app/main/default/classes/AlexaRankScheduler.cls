global class AlexaRankScheduler implements schedulable
{
    /*
    Class can be called using a cron schedule or by running manually.
    Either initialization type can optionally use an overridable soql query
     (to use the default, call the constructor without arguments)
     Note: LIMIT and OFFSET clauses cannot be included in this query

    Call manually:
    List<String> querySelect = new List<String>{'Id','Website'};
    String queryFrom = 'Account';
    String queryWhere = 'Website != \'\' AND MRRCalc__c = 0 AND RecordTypeId = \'012d0000001YZJK\' AND FINANCE_Payment_Method__c = \'Stripe\' LIMIT 1';
        AlexaRankScheduler alexaClient = new AlexaRankScheduler(
      querySelect,
      queryFrom,
      queryWhere
    );
        alexaClient.manualRun();
    OR
        AlexaRankScheduler alexaClient = new AlexaRankScheduler();
        alexaClient.manualRun();

    Call using schedule:
    List<String> querySelect = new List<String>{'Id','Website'};
    String queryFrom = 'Account';
    String queryWhere = 'Website != \'\' AND MRRCalc__c = 0 AND RecordTypeId = \'012d0000001YZJK\' AND FINANCE_Payment_Method__c = \'Stripe\'';
        System.schedule('Periodic Bulk Alexa Rank Fetch', '0 0 0 ? * SUN#2 *', new AlexaRankScheduler(
      querySelect,
      queryFrom,
      queryWhere
    ));
    OR
        System.schedule('Periodic Bulk Alexa Rank Fetch', '0 0 0 ? * SUN#2 *', new AlexaRankScheduler());

    */
  private List<String> querySelect = new List<String>{'Id','Website'};
  private String queryFrom = 'Account';
  private String queryWhere = 'Website != \'\' AND MRRCalc__c = 0 AND RecordTypeId = \'012d0000001YZJK\' AND FINANCE_Payment_Method__c = \'Stripe\'';

    // Initialize without a query
    public AlexaRankScheduler() {}

    // In case we want to run this with a custom query
    public AlexaRankScheduler(List<String> querySelect, String queryFrom, String queryWhere) {
        this.querySelect = querySelect;
        this.queryFrom = queryFrom;
        this.queryWhere = queryWhere;
    }

    // Run as scheduled task
    global void execute(SchedulableContext sc) {
    AlexaRankScheduler.startJob(
      this.querySelect,
      this.queryFrom,
      this.queryWhere
    );
    }
    // Run manually from an anonymous execution window
    public void manualRun() {
        AlexaRankScheduler.startJob(
      this.querySelect,
      this.queryFrom,
      this.queryWhere
    );
    }
    // Start the actual job
    private static void startJob(List<String> querySelect, String queryFrom, String queryWhere){
    AlexaRankRefreshBulk bulkAlexaClient = new AlexaRankRefreshBulk();
        bulkAlexaClient.startBulkAlexaRankFetch(querySelect, queryFrom, queryWhere);
    }
}
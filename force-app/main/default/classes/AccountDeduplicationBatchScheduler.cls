// This class is used to schedule Account Deduplication Batch class
// Test Class: AccountDeduplicationBatchTest 

global class AccountDeduplicationBatchScheduler implements schedulable
{
    global void execute(SchedulableContext sc)
    {
      AccountDeduplicationBatch b = new AccountDeduplicationBatch(); 
      database.executebatch(b, 20);
    }
}
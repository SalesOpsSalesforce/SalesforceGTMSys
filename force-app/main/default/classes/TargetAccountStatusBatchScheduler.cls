/*
    Call manually:
        TargetAccountStatusBatch b = new TargetAccountStatusBatch();
        database.executebatch(b, 1);

    Schedule:
        System.schedule('Weekly TAP - Attempting Status', '0 0 * * 1', new TargetAccountStatusBatchScheduler());

*/

global class TargetAccountStatusBatchScheduler implements schedulable
{
    global void execute(SchedulableContext sc)
    {
      TargetAccountStatusBatch b = new TargetAccountStatusBatch();
      database.executebatch(b, 20);
    }
}
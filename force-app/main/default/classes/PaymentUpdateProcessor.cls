//[RGaokar 2/7/2023 SFDC-1778 Payment record synchrounous update throwing apex cpu timeout error for large number of payment records. So using asynchronous call for payment records >201]
public class PaymentUpdateProcessor implements system.Queueable {
    private List <Payment__c> lstUpdatePayments = new List <Payment__c> ();
    
    public PaymentUpdateProcessor(List <Payment__c> lstUpdatePayments){
        this.lstUpdatePayments = lstUpdatePayments;
    }
    
    public void execute(system.QueueableContext ctx){
        List<Database.SaveResult> srList = Database.update(lstUpdatePayments, false);
        string updateErrors = '';
        for(Database.SaveResult result:srList){
            if(!result.isSuccess()){
                updateErrors += '\n'+'Record Id: '+result.getId();
                for(Database.Error err : result.getErrors()){
                    updateErrors += ' Error Message: ' +err.getMessage()+'\n';
                }
            }
        }
        
        if(string.isNotBlank(updateErrors) || Test.isRunningTest()){
            List <String> errorList = new List <String> ();
            errorList.add('Errors occured during payments update for following records:');
            errorList.add(updateErrors);
            ExceptionHandling.performExceptionHandling(null, 'PaymentUpdateProcessor', errorList);
        }
    }

}
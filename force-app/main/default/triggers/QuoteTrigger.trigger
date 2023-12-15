trigger QuoteTrigger on Quote (after update) {
    Organization Org = [Select Id, Name, IsSandbox from Organization];
    if((!Org.isSandbox || Test.isRunningTest()) && Trigger.isAfter && Trigger.isUpdate && !System.isBatch() && !System.isQueueable() && !System.isScheduled() && !System.isFuture()){
        Map<String, String> mapOfQuote = new Map<String, String>();
        for(Quote quoteRecord : (List<Quote>)Trigger.new){
            if(quoteRecord.Approver_Level_Number_Backend__c != null && quoteRecord.Approver_Level_Number_Backend__c != 0 && ((Map<Id, Quote>)Trigger.oldMap).containskey(quoteRecord.Id) && quoteRecord.Approver_Level_Number_Backend__c != ((Map<Id, Quote>)Trigger.oldMap).get(quoteRecord.Id).Approver_Level_Number_Backend__c){
                mapOfQuote.put(quoteRecord.Id, quoteRecord.Name);
            }
        }
        if(!mapOfQuote.isEmpty()){
            SendMessageToSlackForQuoteApproval.SendMessage(mapOfQuote);
        }
    }
}
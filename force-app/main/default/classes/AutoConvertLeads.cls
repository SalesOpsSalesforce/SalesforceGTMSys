//[RGaokar 02/14/2022 TP #106769] Called from Lead after save flow for platform purchased leads or leads billed under the parent
//onLeadAPIAutoConvertTest test class for test coverage
public class AutoConvertLeads {
    @InvocableMethod(label='Convert Leads')
    public static void convertLeads(List<ConvertLeadRequest> requests) {
        List<Database.LeadConvert> leadConvertList = new List<Database.LeadConvert>();
        Map<Id,Id>LeadExistingContactMap = new Map<Id,Id>();
        Map<Id,DuplicateRecordInfo>MasterDuplicateRecords = new Map<Id,DuplicateRecordInfo>();
        
        for (ConvertLeadRequest request : requests) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(request.leadId);
            lc.setConvertedStatus(request.convertedStatus);
            
            if (String.isNotBlank(request.accountId)) {
                lc.setAccountId(request.accountId);
            }
            
            if (String.isNotBlank(request.contactId)) {
                lc.setContactId(request.contactId);
            }
            
            if (String.isNotBlank(request.opportunityId)) {
                lc.setOpportunityId(request.opportunityId);
            }
            
            if (request.createOpportunity != null && !request.createOpportunity) {
                lc.setDoNotCreateOpportunity(!request.createOpportunity);
            }
            
            if (String.isNotBlank(request.existingContactId)){
                LeadExistingContactMap.put(request.leadId,request.existingContactId);
            }
            
            leadConvertList.add(lc);
        }
        system.debug('leadConverts size --'+leadConvertList.size());
        
        if (leadConvertList.size() > 0) 
        {
            //Convert Leads
            List<Database.LeadConvertResult> lcr = Database.convertLead(leadConvertList);
            
            String errorString;
            for(Database.LeadConvertResult result:lcr){
                if(result.isSuccess() && LeadExistingContactMap.containsKey(result.getLeadId())){
                    MasterDuplicateRecords.put(LeadExistingContactMap.get(result.getLeadId()), 
                                               new DuplicateRecordInfo(result.getContactId(), result.getAccountId()));     
                }else if(!result.isSuccess()){
                    errorString =+ '\n'+result.getLeadId();
                    for(Database.Error err : result.getErrors()) {
                        errorString =+ ': '+err.getMessage()+'\n';
                    }
                    system.debug('errorString--'+errorString);
                }
            }
            
            //Process contacts for merge if there is an existing email matching contact and new contact is created.
            if(MasterDuplicateRecords.size()>0){
                MergesObjectRecordsBatch contactMergeBatch = new MergesObjectRecordsBatch(MasterDuplicateRecords,'Contact');
                Database.executeBatch(contactMergeBatch, 100);
            }
            
            //Create excecption record for errors
            if(String.isNotBlank(errorString)){
                List <String> executionFlow = new List <String> ();
                executionFlow.add('Errors occured when converting following leads:');
                executionFlow.add(errorString);
                ExceptionHandling.performExceptionHandling(null, 'AutoConvertLeads', executionFlow);
            }   
        }
    }
    
    public class ConvertLeadRequest {
        @InvocableVariable(required=true)
        public ID leadId;
        
        @InvocableVariable(required=true)
        public String convertedStatus;
        
        @InvocableVariable
        public string accountId;
        
        @InvocableVariable
        public string contactId;
        
        @InvocableVariable
        public string opportunityId;
        
        @InvocableVariable
        public Boolean createOpportunity;
        
        @InvocableVariable
        public string existingContactId;
        
    }
    
    //To pass newly created contact id and its account id to MergesObjectRecordsBatch class for merge/deduplication.
    public class DuplicateRecordInfo{
        public Id duplicateContactId{get; set;}
        public Id duplicateContactAccountId{get; set;}
        public DuplicateRecordInfo(Id contactId, Id accountId) {
            this.duplicateContactId = contactId;
            this.duplicateContactAccountId = accountId;
        }
    }
}
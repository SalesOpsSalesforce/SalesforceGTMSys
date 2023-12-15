trigger onLeadAPIAutoConvert on Lead (after insert, after update) {

    //** Build Acount, Contact and Opportunity from Lead when APEXTRIGGER_Convert_Lead__c = true 
    
    // ** Test class is : onLeadAPIAutoConvertTest 
    
    //list for leads to convert 
    List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();

    //Get converted master status 
    LeadStatus convertStatus = [select MasterLabel From LeadStatus where IsConverted = true limit 1];
         
    for(Lead l: trigger.new)
    {
        if(l.APEXTRIGGER_Convert_Lead__c  == true && l.isConverted== false)
        {
            //New lead convert 
            Database.LeadConvert lc = new Database.LeadConvert();
           
            lc.setLeadId(l.Id);
            lc.getAccountid();                    
            lc.setConvertedStatus(convertStatus.MasterLabel);
            leadConverts.add(lc);            
        }
    }    
    
    //If we have some that do convert
    if (!leadConverts.isEmpty()) 
    {
         List<Database.LeadConvertResult> lcr = Database.convertLead(leadConverts);
    }
}
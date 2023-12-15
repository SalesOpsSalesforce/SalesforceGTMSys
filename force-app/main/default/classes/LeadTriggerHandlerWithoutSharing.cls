public without sharing class LeadTriggerHandlerWithoutSharing {
    //[RGaokar 02/14/2022 TP #106769] This method is moved to AutoConvertLeads class as an Invocable action which is called from lead after save flow.
    //[RGaokar 10/28/2021 TP #92547] This method is from onLeadAPIAutoConvert trigger which is consolidated to lead trigger.
    // And onLeadAPIAutoConvert trigger is inactivated.
    //** Build Acount, Contact and Opportunity from Lead when APEXTRIGGER_Convert_Lead__c = true
    // ** Test class is : onLeadAPIAutoConvertTest
    
   /* public static void onLeadAPIAutoConvert(List<Lead> newLeadList){
        //list for leads to convert 
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        
        //Get converted master status 
        LeadStatus convertStatus = [select MasterLabel From LeadStatus where IsConverted = true limit 1];
        
        for(Lead l: newLeadList)
        {
            if(l.APEXTRIGGER_Convert_Lead__c  == true && l.isConverted== false)
            {
                //New lead convert 
                Database.LeadConvert lc = new Database.LeadConvert();
                
                lc.setLeadId(l.Id);                    
                lc.setConvertedStatus(convertStatus.MasterLabel);
                leadConverts.add(lc);            
            }
        }    
        
        //If we have some that do convert
        if (!leadConverts.isEmpty()) 
        {
            List<Database.LeadConvertResult> lcr = Database.convertLead(leadConverts);
        }
        
    }*/
    
    //[RGaokar 12/06/2021 TP #97229]Matching lead for deduplication logic
    //Get matching leads
    public static void getMatchLead(List<Lead> newLeadList){
        List<lead> matchNewAccLeadList = new List<lead>();
        List<lead> matchNewStdLeadList = new List<lead>();
        Set<String> emailSet = new Set<String>();
        Set<String> cleanWebsiteAccSet = new Set<String>();
        Set<String> cleanWebsiteStdSet = new Set<String>();
        Set<Id> accIdSet = new Set<Id>();
        Map<String,List<lead>> accCleanWebExisingLeadMap = new Map<String,List<lead>>();//Existing Acc lead map
        Map<String,List<lead>> stdCleanWebExisingLeadMap = new Map<String,List<lead>>();//Existing Std lead map
        
        for(Lead l:newLeadList){
            if(l.MatchLead__c == 'AccountLeadMatch' && String.IsNotBlank(l.Clean_Website_Stamp__c) 
               && l.Account__c != null && String.IsNotBlank(l.Email)){
                   matchNewAccLeadList.add(l);
                   cleanWebsiteAccSet.add(l.Clean_Website_Stamp__c);
                   accIdSet.add(l.Account__c);
                   emailSet.add(l.Email);
               }else if (l.MatchLead__c == 'StandardLeadMatch' && String.IsNotBlank(l.Clean_Website_Stamp__c)){ 
                   matchNewStdLeadList.add(l);
                   cleanWebsiteStdSet.add(l.Clean_Website_Stamp__c);
               }
        }
        
        if(cleanWebsiteAccSet.size() > 0){
            List<lead> accMatchingLeads = [Select id,Clean_Website_Stamp__c,Account__c,Email,Klaviyo_Account_ID__c from lead
                                           where Clean_Website_Stamp__c in :cleanWebsiteAccSet AND Account__c in:accIdSet 
                                           AND Email in :emailSet AND isconverted = false
                                           Order By Account__c, Createddate DESC, Klaviyo_Account_ID__c NULLS first];
            
            //Create a Map of clean website and existing lead for account related leads
            for(lead l:accMatchingLeads){
                if(!accCleanWebExisingLeadMap.containsKey(l.Clean_Website_Stamp__c.toLowerCase())){
                    accCleanWebExisingLeadMap.put(l.Clean_Website_Stamp__c.toLowerCase(), new List<lead> {l});
                }else{
                    accCleanWebExisingLeadMap.get(l.Clean_Website_Stamp__c.toLowerCase()).add(l);
                }  
            }
        }
        
        if(cleanWebsiteStdSet.size() > 0){
            List<lead> stdMatchingLeads = [Select id,Clean_Website_Stamp__c,Email,Klaviyo_Account_ID__c,
                                           CreatedDate,Status,FLOW_Flip_Date_Time__c,Flip_Reject_Approval_Status__c,
                                           Owner.UserRole.DeveloperName,Owner.Profile.Name from lead
                                           where Clean_Website_Stamp__c in :cleanWebsiteStdSet AND isconverted = false
                                           AND Owner.IsActive = true Order By Createddate DESC, Klaviyo_Account_ID__c NULLS first];
            
            //Create a Map of clean website and existing lead for std leads
            for(lead l:stdMatchingLeads){
                if(!stdCleanWebExisingLeadMap.containsKey(l.Clean_Website_Stamp__c.toLowerCase())){
                    stdCleanWebExisingLeadMap.put(l.Clean_Website_Stamp__c.toLowerCase(), new List<lead> {l});
                }else{
                    stdCleanWebExisingLeadMap.get(l.Clean_Website_Stamp__c.toLowerCase()).add(l);
                }  
            }
        }
        
        system.debug('accCleanWebExisingLeadMap.size--'+accCleanWebExisingLeadMap.size());
        system.debug('stdCleanWebExisingLeadMap.size--'+stdCleanWebExisingLeadMap.size());
        
        if(accCleanWebExisingLeadMap.size() > 0){
            matchExistingLead(matchNewAccLeadList,accCleanWebExisingLeadMap);
        }
        
        if(stdCleanWebExisingLeadMap.size() > 0){
            matchExistingLead(matchNewStdLeadList,stdCleanWebExisingLeadMap);
        }
    }
    
    //Match with existing leads
    private static void matchExistingLead(List<lead> matchNewLeadList,Map<String,List<lead>> cleanWebExisingLeadMap){
        for(Lead newLead:matchNewLeadList){
            if(newLead.MatchLead__c == 'AccountLeadMatch' && cleanWebExisingLeadMap.containsKey(newLead.Clean_Website_Stamp__c.toLowerCase())){  
                for(Lead existingLead:cleanWebExisingLeadMap.get(newLead.Clean_Website_Stamp__c.toLowerCase())){
                    Boolean accountLead = newLead.Account__c == existingLead.Account__c && newLead.Email == existingLead.Email;
                    if(accountLead && String.IsBlank(newLead.Klaviyo_Account_ID__c)){
                    	   newLead.Matched_Lead__c = existingLead.id;
                           newLead.MergeLead__c = 'Will Merge';
                           break;
                       }else if(accountLead && String.IsNotBlank(newLead.Klaviyo_Account_ID__c) 
                                && String.IsBlank(existingLead.Klaviyo_Account_ID__c)){
                    	   			newLead.Matched_Lead__c = existingLead.id;
                                    newLead.MergeLead__c = 'Will Merge';
                                    break; 
                                }
                }
            }else if(newLead.MatchLead__c == 'StandardLeadMatch' && cleanWebExisingLeadMap.containsKey(newLead.Clean_Website_Stamp__c.toLowerCase())){
                List<Lead> existingInboundLeads = new List<Lead>();
                List<Lead> existingQualifiedLeads = new List<Lead>();
                List<Lead> existingMatchedEmailLeads = new List<Lead>();
                
                //Existing Lead match based on business logic                
                for(Lead existingLead:cleanWebExisingLeadMap.get(newLead.Clean_Website_Stamp__c.toLowerCase())){
                    Boolean inboundLead = (existingLead.Status == 'Untouched' || existingLead.Status == 'Attempted' || existingLead.Status == 'Qualifying' || existingLead.Status == 'Queued')
                    										  && (String.IsNotBlank(existingLead.Owner.UserRole.DeveloperName) 
                                                                  && (existingLead.Owner.UserRole.DeveloperName.containsIgnoreCase('iBDR') || existingLead.Owner.UserRole.DeveloperName.containsIgnoreCase('Product_Specialist')));
                    Boolean qualifiedLead = inboundLead?false:(existingLead.Status == 'Qualified - Passed to Sales Rep' || existingLead.Status == 'Qualified - No Show')
                    							  && ((String.IsNotBlank(existingLead.Owner.UserRole.DeveloperName) && existingLead.Owner.UserRole.DeveloperName.containsIgnoreCase('Product_Specialist'))
                        							  || (existingLead.Owner.Profile.Name.containsIgnoreCase('AE Sales User')
                            							 && existingLead.FLOW_Flip_Date_Time__c >=  Date.Today().addDays(-90)
                            							 && existingLead.Flip_Reject_Approval_Status__c != 'Approved'
                            							 && existingLead.Flip_Reject_Approval_Status__c != 'Waiting for Sales Ops'));
                                        
                    //New lead without Klaviyo account id
                    if(String.IsBlank(newLead.Klaviyo_Account_ID__c)){
						if(inboundLead){
                            existingInboundLeads.add(existingLead);
                        }else if(qualifiedLead){
                            existingQualifiedLeads.add(existingLead);
                        }else if(String.IsNotBlank(newLead.Email) && newLead.Email == existingLead.Email){ //Only Email match
                            existingMatchedEmailLeads.add(existingLead);
                        }
                    }
                    
                    //New lead with Klaviyo account id and existing lead without Klaviyo account id
                    else if(String.IsNotBlank(newLead.Klaviyo_Account_ID__c) && String.IsBlank(existingLead.Klaviyo_Account_ID__c)){
						if(inboundLead){
                            existingInboundLeads.add(existingLead);
                        }else if(qualifiedLead){
                            existingQualifiedLeads.add(existingLead);
                        }else if(String.IsNotBlank(newLead.Email) && newLead.Email == existingLead.Email){ //Only Email match
                            existingMatchedEmailLeads.add(existingLead);
                        }
                    }   
                }//existing lead for loop ends               
                
                //Verify matching email
				if(existingInboundLeads.size() > 0){
                    Lead existingMatchedLead = getEmailMatchedLead(newLead,existingInboundLeads);
                    newLead.Matched_Lead__c = existingMatchedLead.id;
                    //to suspend batch call for mergeing lead during insert and update - alexarank batch & Stamp_Sales_Initial_Touch_Time batch
                    if(String.IsNotBlank(newLead.Email) && existingMatchedLead.Email == newLead.Email){
                        newLead.MergeLead__c = 'Will Merge';
                    }
                    system.debug('Inbound Lead--');
                }else if(existingQualifiedLeads.size() > 0){
                    Lead existingMatchedLead = getEmailMatchedLead(newLead,existingQualifiedLeads);
                    newLead.Matched_Lead__c = existingMatchedLead.id;
                    if(String.IsNotBlank(newLead.Email) && existingMatchedLead.Email == newLead.Email){
                        newLead.MergeLead__c = 'Will Merge';
                    }
                    system.debug('Qualified Lead--');
                }else if(existingMatchedEmailLeads.size() > 0){
                    newLead.Matched_Lead__c = existingMatchedEmailLeads[0].id;
                    newLead.MergeLead__c = 'Will Merge';
                    system.debug('Email Lead--');
                }    
            }//StandardLeadMatch else statement end
        }//new lead for loop ends
    }

    //Get lead with matching email
    private static Lead getEmailMatchedLead(Lead newLead, List<lead>existingMatchingLeads){
        Lead existingMatchedLead = new Lead();
        //Loop through existing lead to get email matched existing lead
        if(String.IsNotBlank(newLead.Email)){
            for(Lead existingLead:existingMatchingLeads){
                if(newLead.Email == existingLead.Email){
                    existingMatchedLead = existingLead; // Email matched
                    break;
                }
            }   
        }
        
        //No email match
        if(existingMatchedLead.Id == null){
            existingMatchedLead = existingMatchingLeads[0];
        }
        
        return existingMatchedLead;   
    }
    
    //[RGaokar 12/09/2021 TP #97066]Merge lead based on deduplication logic
    //Get matching leads
    public static void mergeLead(List<Lead> newLeadList, Map<id, lead> oldLeadMap){
        Set<id> mergeLeadIds = new Set<Id> ();
        for(Lead l:newLeadList){
            if(l.MergeLead__c != oldLeadMap.get(l.id).MergeLead__c && l.MergeLead__c == 'Merge' && l.Matched_Lead__c != null){
                mergeLeadIds.add(l.Id);       
            }   
        }
        if(mergeLeadIds.size() > 0 && !System.isBatch() && !System.isFuture()){
            system.debug('mergeLeadIds.size()--'+ mergeLeadIds.size());
        	//Process callouts using batch of 50
        	Database.executeBatch(new MergeLeadBatch(mergeLeadIds), 50);
        }  
    }
    
    //[RGaokar 04/29/2022 TP #119625] Lead Data Enrichment using SimilarWeb
    // When Lead is created with website populated or Updated for Website then
    // perform HTTP callout to SimilarWeb 'Lead Enrichment' endpoint to retrieve the information for lead enrichment
    public static void getSimilarWebMetrics(List<Lead> newLeadList, Map<Id, lead> oldMap){
        List <Lead> ldList = new List <Lead>();
        Set<Id> ldIds = new Set<Id>();  
        //l.MergeLead__c != 'Will Merge' & 'Merge' is added to avoid record locking for merge lead deduplication method(LeadTriggerHandlerWithoutSharing.mergeLead)
        for(Lead l:newLeadList){
            if(l.Clean_Website__c <> Null && l.MergeLead__c != 'Will Merge' && l.MergeLead__c != 'Merge' 
               && (Trigger.isInsert || (Trigger.isUpdate && l.Website != oldMap.get(l.id).Website))){
                ldList.add(l);
                ldIds.add(l.id);
            }
        }
        
        system.debug('similarWebLeadList size--'+ ldList.size());
        if(ldList.size() > 0){
            //Passing single record to queueable to avoid filling batch flex queue
            //Passing multiple records to batch of size 10 as Similarweb supports 10 Rest API requests/second
            if(ldList.size() == 1){
                system.enqueueJob(new SimilarWebMetricsProcessor(ldList, false));
            }else{
                string query = 'Select id, Clean_Website__c from Lead where id in ';
                SimilarWebBatch swBatch = new SimilarWebBatch(query, ldIds, false);
                System.scheduleBatch(swBatch, 'LeadTriggerSWBatch'+System.now(), 5, 10);//Scheduling after 5 mins to avoid record locking issues //[RGaokar 10/31/2022 SFDC-1102] 
            }
        } 
    }
    
    //[RGaokar 04/27/2022 TP #119370] Lead Data Enrichment using Charm io api
    // When Lead is created with website populated or Updated for Website then
    // perform HTTP callout to Charm io 'Enrichment' endpoint to retrieve the information for lead enrichment
    public static void charmDataEnrichment(List<Lead> newLeadList, Map<Id, lead> oldMap){
        List<Lead> ldList = new List<Lead>();
        Set<Id> ldIds = new Set<Id>();
        //l.MergeLead__c != 'Will Merge' & 'Merge' is added to avoid record locking for merge lead deduplication method(LeadTriggerHandlerWithoutSharing.mergeLead)
        for(Lead l:newLeadList){
            if(l.Clean_Website__c <> Null && l.MergeLead__c != 'Will Merge' && l.MergeLead__c != 'Merge' 
               && (Trigger.isInsert || (Trigger.isUpdate && l.Website != oldMap.get(l.id).Website))){
                ldList.add(l);
                ldIds.add(l.id);
            }
        }
        system.debug('charmDataLeadList.size()--'+ ldList.size());
        if(ldList.size() > 0){
            //Passing single record to queueable to avoid filling batch flex queue
            //Passing multiple records to batch of size 100. Charm io api request supports 250 websites/request.
            if(ldList.size() == 1){
                system.enqueueJob(new CharmDataEnrichmentProcessor(ldList));
            }else{
                string query = 'Select id, Clean_Website__c from Lead where id in ';
                CharmDataEnrichmentBatch charmBatch = new CharmDataEnrichmentBatch(query, ldIds);
                Database.executeBatch(charmBatch, 100);//[RGaokar 10/31/2022 SFDC-1102]
            }
        } 
    }
    
}
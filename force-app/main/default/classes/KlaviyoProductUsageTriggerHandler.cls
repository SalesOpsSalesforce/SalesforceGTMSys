/**
 * Name: KlaviyoProductUsageTriggerHandler
 * Created on: May 2020
 * Created by: J. Pipkin (OpFocus, Inc)
 * Description:
 */

public class KlaviyoProductUsageTriggerHandler extends TriggerHandler {
    private List<Klaviyo_Product_Usage__c> triggerNew = (Klaviyo_Product_Usage__c[]) Trigger.new;
    private List<Klaviyo_Product_Usage__c> triggerOld = (Klaviyo_Product_Usage__c[]) Trigger.old;
    private Map<Id,Klaviyo_Product_Usage__c> triggerNewmap = (Map<Id, Klaviyo_Product_Usage__c>) Trigger.newMap;
    private Map<Id,Klaviyo_Product_Usage__c> triggerOldmap = (Map<Id, Klaviyo_Product_Usage__c>) Trigger.oldMap;

    // ----------- OVERRIDE METHODS ----------------

    public override void beforeUpdate() {
        //markAsUpdated(); //[1/27/2022 RGaokar TP #96506 This method is moved to KPU before save flow]
    }

    public override void beforeInsert() {
        //markAsUpdated();//[1/27/2022 RGaokar TP #96506 This method is moved to KPU before save flow]
    }
    
    public override void afterUpdate(){
    
        updateLeadsFormula();    
    }

    // ----------- PRIVATE METHODS ----------------

    /**
     * if KPU record is updated and there is a klaviyo account Id, mark as updated by heroku.
     * A scheduled batch job will update any related account or lead associated with the KPU
*/
    //[1/27/2022 RGaokar TP #96506 This method is moved to KPU before save flow]
    //[1/27/2022 RGaokar TP #96506 Some of the KPU field changes are deprecated / removed for markAsUpdated method]
    //KPU Fields changes which are removed: PRODUCT_Has_Complete_Activity_Data__c,PRODUCT_Has_Email_Sign_Ups_Integrated__c,
    //PRODUCT_Has_Synced_to_Ad_Network__c,PRODUCT_Lists_Active_With_Subscribes_Cou__c,PRODUCT_NumListSubscribersfromFormsPages__c
    //PRODUCT_Metrics_PlacedOrder_Value__c,PRODUCT_Metrics_ViewedProduct_Count__c,PRODUCT_SMS_Messages_Sent__c,PRODUCT_Revenue_Trailing_12_Months__c
    /*private void markAsUpdated() {
        for(Klaviyo_Product_Usage__c kpu : triggerNew) {
            if(Trigger.isUpdate && ( kpu.Updated_By_Heroku__c != triggerOldmap.get(kpu.Id).Updated_by_Heroku__c 

            )
            ) {
                continue;
            }
            if(kpu.Klaviyo_Account_ID__c != null && 
            (
               Trigger.isUpdate && ( kpu.PRODUCT_Ecommerce_Integration__c != triggerOldmap.get(kpu.Id).PRODUCT_Ecommerce_Integration__c )
            || Trigger.isUpdate && ( kpu.PRODUCT_Has_Complete_Activity_Data__c != triggerOldmap.get(kpu.Id).PRODUCT_Has_Complete_Activity_Data__c)
            || Trigger.isUpdate && ( kpu.PRODUCT_Has_Email_Sign_Ups_Integrated__c != triggerOldmap.get(kpu.Id).PRODUCT_Has_Email_Sign_Ups_Integrated__c )
            || Trigger.isUpdate && ( kpu.PRODUCT_Has_Synced_to_Ad_Network__c != triggerOldmap.get(kpu.Id).PRODUCT_Has_Synced_to_Ad_Network__c)
            || Trigger.isUpdate && ( kpu.PRODUCT_Is_Sending_Campaigns__c != triggerOldmap.get(kpu.Id).PRODUCT_Is_Sending_Campaigns__c )
            || Trigger.isUpdate && ( kpu.PRODUCT_Is_Sending_Flows__c != triggerOldmap.get(kpu.Id).PRODUCT_Is_Sending_Flows__c)
            
            || ( Trigger.isUpdate && ( kpu.PRODUCT_Lists_Active_With_Subscribes_Cou__c != triggerOldmap.get(kpu.Id).PRODUCT_Lists_Active_With_Subscribes_Cou__c )
            && ( triggerOldmap.get(kpu.Id).PRODUCT_Lists_Active_With_Subscribes_Cou__c == NULL  || triggerOldmap.get(kpu.Id).PRODUCT_Lists_Active_With_Subscribes_Cou__c == 0)) 
            || ( Trigger.isUpdate && ( kpu.PRODUCT_NumListSubscribersfromFormsPages__c != triggerOldmap.get(kpu.Id).PRODUCT_NumListSubscribersfromFormsPages__c)
            && ( triggerOldmap.get(kpu.Id).PRODUCT_NumListSubscribersfromFormsPages__c == NULL  || triggerOldmap.get(kpu.Id).PRODUCT_NumListSubscribersfromFormsPages__c == 0)) 
            || ( Trigger.isUpdate && ( kpu.PRODUCT_Metrics_PlacedOrder_Value__c != triggerOldmap.get(kpu.Id).PRODUCT_Metrics_PlacedOrder_Value__c )
            && ( triggerOldmap.get(kpu.Id).PRODUCT_Metrics_PlacedOrder_Value__c == NULL  || triggerOldmap.get(kpu.Id).PRODUCT_Metrics_PlacedOrder_Value__c == 0)) 
            || ( Trigger.isUpdate && ( kpu.PRODUCT_Metrics_ViewedProduct_Count__c != triggerOldmap.get(kpu.Id).PRODUCT_Metrics_ViewedProduct_Count__c)
            && ( triggerOldmap.get(kpu.Id).PRODUCT_Metrics_ViewedProduct_Count__c == NULL  || triggerOldmap.get(kpu.Id).PRODUCT_Metrics_ViewedProduct_Count__c == 0)) 
            || ( Trigger.isUpdate && ( kpu.PRODUCT_SMS_Messages_Sent__c != triggerOldmap.get(kpu.Id).PRODUCT_SMS_Messages_Sent__c)
            && ( triggerOldmap.get(kpu.Id).PRODUCT_SMS_Messages_Sent__c == NULL  || triggerOldmap.get(kpu.Id).PRODUCT_SMS_Messages_Sent__c == 0)) 
            
            || Trigger.isUpdate && ( kpu.PRODUCT_Shopify_Plan__c != triggerOldmap.get(kpu.Id).PRODUCT_Shopify_Plan__c )
            || Trigger.isUpdate && ( kpu.PRODUCT_Stripe_Net_MRR__c != triggerOldmap.get(kpu.Id).PRODUCT_Stripe_Net_MRR__c )
            || Trigger.isUpdate && ( kpu.Current_GMV_Segment__c != triggerOldmap.get(kpu.Id).Current_GMV_Segment__c)
            || (
            Trigger.isUpdate && ( kpu.PRODUCT_of_Emailable_Profiles__c != triggerOldmap.get(kpu.Id).PRODUCT_of_Emailable_Profiles__c)
            && ( (kpu.PRODUCT_of_Emailable_Profiles__c >= 1000 && ( triggerOldmap.get(kpu.Id).PRODUCT_of_Emailable_Profiles__c < 1000 || triggerOldmap.get(kpu.Id).PRODUCT_of_Emailable_Profiles__c == NULL)) 
            || (kpu.PRODUCT_of_Emailable_Profiles__c >= 3000 && triggerOldmap.get(kpu.Id).PRODUCT_of_Emailable_Profiles__c < 3000)
            )
            )
            || Trigger.isUpdate && ( kpu.PRODUCT_Revenue_Trailing_12_Months__c != triggerOldmap.get(kpu.Id).PRODUCT_Revenue_Trailing_12_Months__c )
            
            || ( Trigger.isUpdate && ( kpu.MARKETING_utm_Campaign_Last__c != triggerOldmap.get(kpu.Id).MARKETING_utm_Campaign_Last__c )
            && triggerOldmap.get(kpu.Id).MARKETING_utm_Campaign_Last__c == NULL )         
            || ( Trigger.isUpdate && ( kpu.MARKETING_Referrer_Last__c != triggerOldmap.get(kpu.Id).MARKETING_Referrer_Last__c)
            && triggerOldmap.get(kpu.Id).MARKETING_Referrer_Last__c == NULL )            
            || ( Trigger.isUpdate && ( kpu.MARKETING_utm_Source_Last__c != triggerOldmap.get(kpu.Id).MARKETING_utm_Source_Last__c)
            && triggerOldmap.get(kpu.Id).MARKETING_utm_Source_Last__c == NULL )            
            || ( Trigger.isUpdate && ( kpu.MARKETING_utm_Term_Last__c != triggerOldmap.get(kpu.Id).MARKETING_utm_Term_Last__c )
            && triggerOldmap.get(kpu.Id).MARKETING_utm_Term_Last__c == NULL )
            )
            
            ) {
                kpu.Updated_By_Heroku__c = true;
            }
        }
    }*/
 
 
 /* [vrajapatruni 12/21/2020 ] This code is added for Workable Lead Time Stamp. 
 Impact on Nightly Sync: The code will be tranversed until the if loops and will exit out during sync. */    
 
 private void updateLeadsFormula(){    
    
        Set<Id> recIds = new Set<Id>();
                      
        for(Klaviyo_Product_Usage__c kpu : triggerNew) {
            
            if((triggerOldMap.get(kpu.Id).Contact_at_Close_Date__c < 1000 &&  (kpu.Contact_at_Close_Date__c >= 1000 || kpu.Contact_at_Close_Date__c == null)) || (kpu.PRODUCT_of_Emailable_Profiles__c <> triggerOldmap.get(kpu.Id).PRODUCT_of_Emailable_Profiles__c && kpu.PRODUCT_of_Emailable_Profiles__c > 999 && (triggerOldmap.get(kpu.Id).PRODUCT_of_Emailable_Profiles__c <= 999 || triggerOldmap.get(kpu.Id).PRODUCT_of_Emailable_Profiles__c == null))) {
                if((kpu.Contact_at_Close_Date__c >= 1000 || kpu.Contact_at_Close_Date__c == null) &&  kpu.PRODUCT_of_Emailable_Profiles__c > 999){       
                    recIds.add(kpu.Id);
                    
                }     
            }
        }
        
        if(!recIds.isEmpty()){
        
            Set<Id> acctIds = new Set<Id>();
            for(Account a : [Select Id, Klaviyo_Product_Usage__c from Account where Klaviyo_Product_Usage__c in: recIds]){
                acctIds.add(a.Id); 
            }
        
            List<Lead> leadList = [Select Id, Workable_Date__c,FORMULA_Workable_Lead__c, CanLeadDatebeStamped__c from Lead where (Klaviyo_Product_Usage__c in: recIds) OR (IsConverted = True AND ConvertedAccountId in: acctIds)]; 
            List<Lead> updateLeadList = new List<Lead>();
            
            for(Lead l : leadList){
                    l.CanLeadDatebeStamped__c = true;                    
                    updateLeadList.add(l);
                                          
            }   
            
            if(!updateLeadList.isEmpty()){
                update updateLeadList;
            }      
        }
        
    }
    
}
public with sharing class heap_Configuration {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_Configuration(){}
   /* public class HeapAppIdException extends Exception {}

    public static Integer MaxCallouts = 100;

    public static Integer MaxFutures = 50;

    public static Integer MaxQueueableJobs = 50;

    public static Boolean SkipTriggers {
        get {
            if (SkipTriggers == null) {
                heap_Settings__c settings = heap_Configuration.heapSettings;
                SkipTriggers = settings.Heap_Skip_Trigger__c;
            }
            return SkipTriggers;
        }
        public set;
    }

    public static String HeapAppId {
        get {
            if (HeapAppId == null) {
                heap_Settings__c settings = heap_Configuration.heapSettings;
                String AppId = settings.Heap_App_ID__c;
                //if (null == AppId && !Test.isRunningTest()) {
                //    throw new HeapAppIdException('Heap_App_ID is undefined. Please set in Custom Settings');
                //} else if (Test.isRunningTest()) {
                //    AppId = '123';
                //}
                HeapAppId = AppId;
            }
            return HeapAppId;
        }
        public set;
    }


    public static heap_Settings__c heapSettings {
        get {
            if (heapSettings == null) {
                heapSettings = heap_Settings__c.getOrgDefaults();
            }
            return heapSettings;
        }
        private set;
    }

    // This should get registered from the class if we can
    public static List<Type> backfillClasses = new List<Type>{
        heap_Opportunities.class,
        heap_Leads.class,
        heap_Contacts.class,
        heap_Accounts.class
    };*/

    /*
    It would be better to do this with annotations, but we don't have that in Apex
    These are all classes that implement heap_IUserPreopertySource and therefore can be sources
    of user properties.
     */
    /*public static List<Type> userPropertyTypes = new List<Type>{
            heap_Opportunities.class,
            heap_Leads.class,
            heap_Contacts.class,
            heap_Accounts.class
    };*/
}
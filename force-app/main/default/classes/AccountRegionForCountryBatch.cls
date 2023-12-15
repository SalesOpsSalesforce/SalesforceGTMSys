// [vrajapatruni 05/21/2021] This is a batch class to process all accounts Region for Country 
// Code to run in the Developer Console - Database.executeBatch(new AccountRegionForCountryBatch(),1);

public class AccountRegionForCountryBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
    
        return Database.getQueryLocator('Select Id, Country__c, SALES_Geographical_Location__c from Account'); //where SALES_Geographical_Location__c != Null
        
    }
    
    public void execute(Database.BatchableContext bc, List<Account> AccountList){
    
        Set<String> setCountries = new Set<String>();
        for (Account acc : AccountList) {
            // If the Account has a Country and its Flow Flip Channel is non-null and has changed
            if (acc.Country__c != null && acc.SALES_Geographical_Location__c == Null) {
                setCountries.add(acc.Country__c);
            }
        }
        if (!setCountries.isEmpty()) {
            // Create a map of Regions, indexed by Country.
            // The Country is the Label field.
            List<Country_and_Region_Mapping__mdt> lstMappings =
            [select id, Region__c, Label
            from   Country_and_Region_Mapping__mdt
            where  Label in :setCountries];

            Map<String, String> mapRegionsByCountry = new Map<String, String>();
            for (Country_and_Region_Mapping__mdt mapping : lstMappings) {
                mapRegionsByCountry.put(mapping.Label.toLowerCase(), mapping.Region__c);
            }
            System.debug('Map ' +mapRegionsByCountry);
            // Use the map to assign the correct Region to each Lead
            for (Account acc : AccountList) {
                if (acc.Country__c != null  && acc.SALES_Geographical_Location__c == Null){
                    String country = acc.Country__c.toLowerCase();
                    if (mapRegionsByCountry.containsKey(country)) {
                        String region = mapRegionsByCountry.get(country);
                        acc.SALES_Geographical_Location__c = region;
                    }
                }
            }
            Database.update(AccountList); 
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
}
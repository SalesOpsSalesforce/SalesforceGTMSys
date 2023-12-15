public class AccountRegionForCountryUpdate{
    
    // When an Account is created, if it has a Country Code (MARKETING_SignupFormFieacc_7__c),
    // use it to find the matching Region in Country_and_Region_Mapping__mdt.
    // Called on Before Insert
    public static void calcRegionForCountryCode(List<Account> triggerNew, Map<Id,Account> triggerOldmap) {

        System.debug('Account being inserted');
        // If this functionality is disabled, don't do it
        if (TriggerDisablementSwitchHelper.isDisabled('Account_Country_Code_And_Region_Mapping')) {
            return;
        }

        // Get a list of Country Codes to look up
        Set<String> setCodes = new Set<String>();
        for (Account acc : triggerNew) {
           if (acc.Country__c != null) 
               setCodes.add(acc.Country__c);
        }
        System.debug('List of codes' +setCodes);
        if (!setCodes.isEmpty()) {
            // Create a map of Regions, indexed by Country Code
            List<Country_and_Region_Mapping__mdt> lstMappings =
                [select id, Region__c, Label, Country_Code__c
                from   Country_and_Region_Mapping__mdt
                where  Label in :setCodes];
            System.debug('Mappings '+lstMappings);
            Map<String, String> mapRegionsByCountryCode = new Map<String, String>();
            for (Country_and_Region_Mapping__mdt mapping : lstMappings) {
                mapRegionsByCountryCode.put(mapping.Label.toLowerCase(), mapping.Region__c);
            }
            System.debug('Map '+mapRegionsByCountryCode);
            // Use the map to assign the correct Region to each Lead
            for (Account acc : triggerNew) {
                if (acc.Country__c != null) {
                    String countryCode = acc.Country__c.toLowerCase();
                    if (mapRegionsByCountryCode.containsKey(countryCode)) {
                    
                        String region = mapRegionsByCountryCode.get(countryCode);
                        acc.SALES_Geographical_Location__c = region;
                        
                    }
                }
            }
        }
    }


    // When an Account is updated, if it has a Country (Country__c) and its
    // FLOW_Flip_Channel__c has changed and is not null, use the Country to
    // to find the matching Region in Country_and_Region_Mapping__mdt.
    // Called on Before Update
    public static void calcRegionForCountry(List<Account> triggerNew, Map<Id,Account> triggerOldmap) {
        // Get a list of Country to look up
        Set<String> setCountries = new Set<String>();
        for (Account acc : triggerNew) {
            Account accOld = triggerOldmap.get(acc.Id);
            // If the Account has a Country and its Flow Flip Channel is non-null and has changed
            if (acc.Country__c != null &&
                   acc.Country__c != accOld.Country__c) {
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
            for (Account acc : triggerNew) {
                Account accOld = triggerOldmap.get(acc.Id);
                if (acc.Country__c != null  &&
                   acc.Country__c != accOld.Country__c) {
                    String country = acc.Country__c.toLowerCase();
                    if (mapRegionsByCountry.containsKey(country)) {
                        String region = mapRegionsByCountry.get(country);
                        acc.SALES_Geographical_Location__c = region;
                    }
                }
            }
        }
    }

}
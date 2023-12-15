/* *********
*  Date:            May 2020
*  Description:     Helper class to make accessing the Trigger_Disablement_Switch__mdt
*                   custom metadata type easier
*  Developer:       OpFocus
* *********/

public with sharing class TriggerDisablementSwitchHelper {

    @TestVisible
    private static Map<String, Boolean> mapSwitches = new Map<String, Boolean>();

    public static Boolean isDisabled(String switchName) {
        // If the switch isn't in the map, add it
        if (!mapSwitches.containsKey(switchName.toLowerCase())) {
            List<Trigger_Disablement_Switch__mdt> lstSwitches =
              [select id, Is_Disabled__c from Trigger_Disablement_Switch__mdt where DeveloperName = :switchName];
            if (lstSwitches.isEmpty()) {
                // The switch doesn't exist. We consider it to be enabled.
                mapSwitches.put(switchName.toLowerCase(), false);
            }
            else {
                // The switch does exist. Put its value in the map.
                mapSwitches.put(switchName.toLowerCase(), lstSwitches[0].Is_Disabled__c);
            }
        }

        // Return the switches' value
        return mapSwitches.get(switchName.toLowerCase());
    }

}
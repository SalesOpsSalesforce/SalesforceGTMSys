/* Class:       LeadTriggerHandlerTest
 * Created On:  May 2020
 * Created by:  OpFocus
 * Description: Unit tests for the TriggerDisablementSwitchHelper class
 */
@isTest
public class TriggerDisablementSwitchHelperTest {

    @isTest
    static void testSwitches() {
        // Find and test switches that are enabled
        List<Trigger_Disablement_Switch__mdt> lstSwitchesEnabled =
            [select id, DeveloperName, Is_Disabled__c from Trigger_Disablement_Switch__mdt where Is_Disabled__c = false];
        if (!lstSwitchesEnabled.isEmpty()) {
            System.assertEquals(false, TriggerDisablementSwitchHelper.isDisabled(lstSwitchesEnabled[0].DeveloperName.toUpperCase()));
        }

        // Find and testswitches that are disabled
        List<Trigger_Disablement_Switch__mdt> lstSwitchesDisabled =
        [select id, DeveloperName, Is_Disabled__c from Trigger_Disablement_Switch__mdt where Is_Disabled__c = true];
        if (!lstSwitchesDisabled.isEmpty()) {
            System.assertEquals(true, TriggerDisablementSwitchHelper.isDisabled(lstSwitchesDisabled[0].DeveloperName.toUpperCase()));
        }

        // Check for a switch that doesn't exist. Should be considered enabled.
        Boolean nonExistingSwitchValue =
                TriggerDisablementSwitchHelper.isDisabled('This_Switch_Should_Not_Exist');
        System.assertEquals(false, nonExistingSwitchValue, 'Switch not defined, so it should be considered not disabled');
    }
}
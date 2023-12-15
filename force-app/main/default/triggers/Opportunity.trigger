/*
** Trigger:  Opportunity
** SObject:  Opportunity
** Created by OpFocus 
** Description: Trigger for Opportunity.  Details in OpportunityTriggerHandler
**              
*/
trigger Opportunity on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    new OpportunityTriggerHandler().run();
}
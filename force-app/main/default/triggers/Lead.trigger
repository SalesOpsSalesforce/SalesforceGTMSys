/*
** Trigger:  Lead
** SObject:  Lead
** Created by OpFocus 
** Description: Trigger for Lead.  Details in LeadTriggerHandler
**              
*/
trigger Lead on Lead (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    new LeadTriggerHandler().run();
}
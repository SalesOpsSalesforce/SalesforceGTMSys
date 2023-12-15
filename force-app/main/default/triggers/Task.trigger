/*
** Trigger:  Task
** SObject:  Task
** Created by OpFocus 
** Description: Trigger for Task.  Details in TaskTriggerHandler
**              
*/
trigger Task on Task (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    new TaskTriggerHandler().run();
}
/*
** Trigger:  Contracts
** SObject:  Contract__c
** Created by RGaokar 
** Date: 06/16/2022 
** Description: Trigger for Contract__c. Details in ContractsTriggerHandler
**              
*/
trigger Contracts on Contract__c (before insert, before update, after insert, after update) 
{
    new ContractsTriggerHandler().run();
}
trigger ResourceTaskTrigger on Resource_Task__c (before insert,before update) {
    system.debug('dentro del trigger de Resource_Task__c');
    system.debug(Trigger.new);
    ProjectResourcesHelper.validateTasks(Trigger.new);
}
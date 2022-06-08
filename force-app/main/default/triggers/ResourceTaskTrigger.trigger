trigger ResourceTaskTrigger on Resource_Task__c (before insert,before update) {
    ProjectResourcesHelper.validateTasks(Trigger.new);
}
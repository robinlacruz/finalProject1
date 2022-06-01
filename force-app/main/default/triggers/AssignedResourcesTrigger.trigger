trigger AssignedResourcesTrigger on Project_Assigned_Resource__c (before insert, before update) {
    
    if(!Test.isRunningTest())
        ProjectResourcesHelper.validatePARs(trigger.new);
    
}
trigger AssignedResourcesTrigger on Project_Assigned_Resource__c (before insert, before update) {
    
    ProjectResourcesValidations.validatePARs(trigger.new);
    
}
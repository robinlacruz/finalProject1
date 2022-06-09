trigger AssignedResourcesTrigger on Project_Assigned_Resource__c (before insert , before update ) {

   if(Trigger.isInsert){
        ProjectResourcesHelper.validatePARs(trigger.new);
   } else if (Trigger.isUpdate){
        ProjectResourcesHelper.validateUpdatePARs(trigger.old,trigger.new);
   }
        
        
}
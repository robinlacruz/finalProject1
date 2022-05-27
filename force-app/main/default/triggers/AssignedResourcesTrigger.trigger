trigger AssignedResourcesTrigger on Project_Assigned_Resource__c (before insert, before update) {
    for(Project_Assigned_Resource__c item :trigger.new){
        String error = ProjectResourcesHelper.validateAssignedDates(item.user__c,item.Start_Date__c,item.End_Date__c,item.Project_Line_Item__c);
        if( error!= null)
            item.addError(error);
  	}
}
public with sharing class ProjectAndResources {

    @AuraEnabled(cacheable=true)
    public static Map<String,List<User>> getResourcesByRoleMap() {
        List<User> users = [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c != null];
        Map<String,List<User>> resourcesByRole = new Map<String,List<User>>();
        for(User resource: users){
            if(resourcesByRole.get(resource.Role__c)!=null){
                List<User> resources = resourcesByRole.get(resource.Role__c);
                resources.add(resource);
                resourcesByRole.put(resource.Role__c, resources);
            } else {
                List<User> resources = new List<User>();
                resources.add(resource);
                resourcesByRole.put(resource.Role__c, resources);
            }
        }
        return resourcesByRole;
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id,User> getResourcesById() {
        return new Map<Id,User>([SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c != null]);
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getResourcesByRole(String role) {
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c =: role];
    }

    @AuraEnabled(cacheable=true)
    public static Project__c getProjectAndPLIs(Id projectId) {
        return [SELECT Id, Name, Start_Date__c, End_Date__c, (SELECT Id, Name, Role__c, Estimated_Hours__c, Current_Hours__c, Assigned_Hours__c FROM Project_Line_Items__r) FROM Project__c WHERE Project__c.Id =: projectId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static List<Project_Line_Item__c> getProjectLineItems(Id projectId) {
        return [SELECT Id, Name, Role__c, Estimated_Hours__c, Current_Hours__c, Assigned_Hours__c FROM Project_Line_Item__c WHERE Project__c =: projectId];
    }

    @AuraEnabled(cacheable=true)
    public static Project_Line_Item__c getProjectLineItem(Id pliId) {
        return [SELECT Id, Name, Role__c, Estimated_Hours__c, Current_Hours__c, Assigned_Hours__c FROM Project_Line_Item__c WHERE Id =: pliId LIMIT 1];
    }


    @AuraEnabled(cacheable=true)
    public static List<Project_Assigned_Resource__c> getProjectAssignedResources(Id projectId) {
        return [SELECT Id, User__c, Start_Date__c, End_Date__c FROM Project_Assigned_Resource__c WHERE Project_Line_Item__r.Project__c =: projectId];
    }



    @AuraEnabled(cacheable=false)
    public static String insertPARs(List<Project_Assigned_Resource__c> PARsList){
        insert PARsList;
        return 'inserted';
    }

}

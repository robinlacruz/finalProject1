public with sharing class ProjectResourcesHelper {

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
    public static List<User> getResourcesByRole(String role) {
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c =: role];
    }

    @AuraEnabled(cacheable=true)
    public static Project__c getProjectAndPLIs(Id projectId) {
        return [SELECT Id, Name, Start_Date__c, End_Date__c, (SELECT Id, Name, Role__c, Estimated_Hours__c, Current_Hours__c, Assigned_Hours__c FROM Project_Line_Items__r) FROM Project__c WHERE Project__c.Id =: projectId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static Project_Line_Item__c getProjectLineItem(Id pliId) {
        return [SELECT Id, Name, Role__c, Estimated_Hours__c, Estimated_Amount__c, Assigned_Amount__c, Current_Hours__c, Assigned_Hours__c FROM Project_Line_Item__c WHERE Id =: pliId LIMIT 1];
    }

     @AuraEnabled(cacheable=true)
    public static List<Project_Line_Item__c> getProjectLineItems(Id projectId) {
        return [SELECT Id, Name, Role__c, Estimated_Hours__c, Current_Hours__c, Assigned_Hours__c, Estimated_Amount__c, Assigned_Amount__c FROM Project_Line_Item__c WHERE Project__c =: projectId];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects() {
        return [SELECT Id, Name, Start_Date__c, End_Date__c FROM Project__c];
    }
    
     @AuraEnabled(cacheable=true)
    public static Map<Id,User> getResourcesById() {
        return new Map<Id,User>([SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c != null]);
    }

    @AuraEnabled(cacheable=true)
    public static List<Project_Assigned_Resource__c> getProjectAssignedResources(Id projectId) {
        return [SELECT Id, User__c, Start_Date__c, End_Date__c FROM Project_Assigned_Resource__c WHERE Project_Line_Item__r.Project__c =: projectId];
    }

    public static List<Id> getUserIdsOfProject(Id projectId){
        List<Project_Assigned_Resource__c> parList = [SELECT User__c FROM Project_Assigned_Resource__c WHERE Project_Line_Item__r.Project__c =: projectId];
        Set<Id> userIds = new Set<Id>();
            for(Project_Assigned_Resource__c par:parList){
                userIds.add(par.User__c);   
            }
        return new List<Id>(userIds); 
    }

    @AuraEnabled(cacheable=false)
    public static String insertPARs(List<Project_Assigned_Resource__c>  resources){
        List<Project_Assigned_Resource__c> resourcesList = new List<Project_Assigned_Resource__c>();
        try{
           
            for(Project_Assigned_Resource__c item : resources){
                Integer assignedHours = Util.getBusinessHoursCount(item.Start_Date__c,item.End_Date__c);
                Double assignedAmount = assignedHours*(Decimal)item.Resource_Rate__c;
                item.Assigned_Hour__c = assignedHours;
                item.Assigned_Amount__c = assignedAmount;
                resourcesList.add(item);
            }
            insert resourcesList;
            return 'Operacion DML realizada correctamente';
        }
        catch(DmlException e){
            return 'Error en operacion DML';
        }
    }


}
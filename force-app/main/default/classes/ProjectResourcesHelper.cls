public with sharing class ProjectResourcesHelper {

    public class My1Exception extends Exception {}
	
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


    @AuraEnabled(cacheable=false)
    public static String insertPARs(List<Project_Assigned_Resource__c>  resources){
        List<Project_Assigned_Resource__c> resourcesList = new List<Project_Assigned_Resource__c>();
        try{
           
            for(Project_Assigned_Resource__c item : resources){
                Integer assignedHours = getBusinessHoursCount(item.Start_Date__c,item.End_Date__c);
                Double assignedAmount = assignedHours*item.Resource_Rate__c;
                item.put('Assigned_Hour__c',assignedHours);
                item.put('Assigned_Amount__c',assignedAmount);
                resourcesList.add(item);
            }
            system.debug('dentro de insertPARs');
            system.debug(resourcesList);
            insert resourcesList;
            return 'Operacion DML realizada correctamente';
        }
        catch(DmlException e){
            throw new My1Exception(e.getMessage());  
        }
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
    
    //Validations
    //Retorna true si el proyecto pasado por parametro tiene un unico squad lead. De lo contrario retorna false
    public static boolean hasUniqueSquadLead(Project__c project){
        List<Id> userIds = getUserIdsOfProject(project.Id);
        if(project.Squad_Lead__c ==null){
            return false;
        }    
        else{
            if(!userIds.contains(project.Squad_Lead__c))
                return false;
            return true;   
        }
    }
    
    //retorna true si el proyecto tiene asignadas la totalidad de horas requeridas por el equipo de ventas
    public static boolean projectIsFull(Project__c project){
        Project__c projectWithLineItems = [SELECT id, (SELECT id, Assigned_Hours__c, Estimated_Hours__c FROM Project_Line_Items__r) FROM Project__c WHERE id=:project.id];
        List<Project_Line_Item__c> projectLineItemList = projectWithLineItems.Project_Line_Items__r;
       
        for(Project_Line_Item__c lineItem:projectLineItemList){
            if(lineItem.Assigned_Hours__c < lineItem.Estimated_Hours__c)
                return false;
        }
        return true;
    }

    public static boolean isProfitable(Project__c project){
            if(project.Assigned_Amount__c > project.Estimated_Amount__c)
                return false;
            return true;
    }

    public static List<Id> getUserIdsOfProject(Id projectId){
        List<Project_Assigned_Resource__c> parList = [SELECT User__c FROM Project_Assigned_Resource__c WHERE Project_Line_Item__r.Project__c =: projectId];
        Set<Id> userIds = new Set<Id>();
            for(Project_Assigned_Resource__c par:parList){
                userIds.add(par.User__c);   
            }
        return new List<Id>(userIds); 
    }
    	
    public static String validateAssignedDates(Id userId,Date startDate,Date endDate,Id pliId){
        List<Project_Assigned_Resource__c> userAssignedResources= [SELECT id,User__c,User__r.Name,Start_Date__c,End_Date__c FROM Project_Assigned_Resource__c 
                                                                 WHERE User__c =:userId AND End_Date__c>=:Date.Today()];
        Project_Line_Item__c currentPLI = [SELECT Project__r.Start_Date__c, Project__r.End_Date__c FROM Project_Line_Item__c WHERE Id =: pliId];
        String error;
        if(startDate==null || endDate ==null){
            return 'Se deben asignar ambas fechas';
        }


        if(endDate<startDate){
            error='La fecha de fin de la asignacion no puede ser anterior a la fecha de inicio.';
            return error;
        }     
        if(endDate<Date.today() || startDate<Date.today()){
            error='Las fechas de inicio y fin del proyecto no pueden ser fechas pasadas';
            return error;
        }
		String dayOfStartDate = getDayOfWeek(startDate);
        String dayOfEndDate= getDayOfWeek(endDate);

        // Valida que las fechas no sean sabado o domingo
        
        if(dayOfStartDate == 'Saturday' || dayOfStartDate == 'Sunday'){
                if(dayOfEndDate =='Saturday' || dayOfEndDate == 'Sunday'){
                    error='No se pueden asignar dias no laborales como fecha de termino del proyecto';
                    return error;
                }
            error='No se pueden asignar dias no laborales como fecha de inicio del proyecto';
            return error;		
        }

        Date projectStartDate = currentPLI.Project__r.Start_Date__c; 
        Date projectEndDate = currentPLI.Project__r.End_Date__c;
        
        if(startDate<projectStartDate || endDate>projectEndDate){
            error='No se pueden asignar recursos fuera del rango de fechas del proyecto';
            return error;
        }
        
        for(Project_Assigned_Resource__c assignedResource : userAssignedResources){
            Date resourceStartDate = assignedResource.Start_Date__c; 
            Date resourceEndDate = assignedResource.End_Date__c;   
            if(startDate<=resourceEndDate && endDate>=resourceStartDate){
                error='No pueden asignarse las fechas seleccionadas porque no estan disponibles para ' + assignedResource.user__r.Name;
                return error;
            }
        }
            
		return error;     
    }
    	//Devuelve mensaje de error cuando las fechas no esten disponibles , caso contrario devuelve null
    
    //Utilities
        public static String getDayOfWeek(Date paramDate){
			Datetime dt = (DateTime)paramDate.addDays(1);
        	return  dt.format('EEEE');
    }
    
    	public static Integer getBusinessHoursCount(Date startDate, Date endDate){
        Integer count = 0;
        Date curDate = startDate;
        while (curDate <= endDate) {
                String dayOfWeek = getdayOfWeek(curDate);
                if(getDayOfWeek(curDate) != 'Friday' && getDayOfWeek(curDate) != 'Saturday') count++;
                curDate = curDate.addDays(1);
            }
       return count* 8;
    }
}
public with sharing class ProjectResourcesHelper {

    public class My1Exception extends Exception {}
	
    /* @AuraEnabled(cacheable=true)
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
    } */

    @AuraEnabled(cacheable=false) //testeado
    public static List<User> getResourcesByRoleAndDate(String role, Date startDate, Date endDate) {
        List<Project_Assigned_Resource__c> PARs = [SELECT User__c FROM Project_Assigned_Resource__c WHERE (End_Date__c >= :startDate AND End_Date__c <= :endDate) OR (Start_Date__c >= :startDate AND Start_Date__c <= :endDate) OR (Start_Date__c < :startDate AND End_Date__c > :endDate)];
        Set<Id> userIds = new Set<Id>();
        for (Project_Assigned_Resource__c par : PARS) {
            userIds.add(par.User__c);
        }
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c =: role AND Id NOT IN :userIds];
    }

    @AuraEnabled(cacheable=false) //testeado
    public static List<User> getResourcesByRole(String role) {
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c =: role];
    }    

    @AuraEnabled(cacheable=false) // testeado
    public static Map<Id,User> getResourcesByIdMap(List<User> resources){
        return new Map<Id,User>(resources);
    }

    @AuraEnabled(cacheable=true) // testeado
    public static Project__c getProjectAndPLIs(Id projectId) {
        return [SELECT Id, Name, Start_Date__c, End_Date__c, (SELECT Id FROM Project_Line_Items__r) FROM Project__c WHERE Project__c.Id =: projectId LIMIT 1];
    }

    @AuraEnabled(cacheable=true) // testeado
    public static Project_Line_Item__c getProjectLineItem(Id pliId) {
        return [SELECT Id, Name, Role__c, Estimated_Hours__c, Estimated_Amount__c, Assigned_Amount__c, Current_Hours__c, Assigned_Hours__c FROM Project_Line_Item__c WHERE Id =: pliId LIMIT 1];
    }


    @AuraEnabled(cacheable=false) // testeado
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
            insert resourcesList;
            return 'Operacion DML realizada correctamente';
        }
        catch(DmlException e){
            throw new My1Exception(e.getMessage());  
        }
    }
    
    //Validations
    //Retorna true si el proyecto pasado por parametro tiene un unico squad lead. De lo contrario retorna false
    public static boolean hasUniqueSquadLead(Project__c project){ //testeado
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
    public static boolean projectIsFull(Project__c project){ // testeado
        Project__c projectWithLineItems = [SELECT id, (SELECT id, Assigned_Hours__c, Estimated_Hours__c FROM Project_Line_Items__r) FROM Project__c WHERE id=:project.id];
        List<Project_Line_Item__c> projectLineItemList = projectWithLineItems.Project_Line_Items__r;
        for(Project_Line_Item__c lineItem:projectLineItemList){
            if(lineItem.Assigned_Hours__c < lineItem.Estimated_Hours__c)
                return false;
        }
        return true;
    }

    public static boolean isProfitable(Project__c project){ // testeado
            if(project.Assigned_Amount__c > project.Estimated_Amount__c)
                return false;
            return true;
    }

    public static List<Id> getUserIdsOfProject(Id projectId){  // testeado
        List<Project_Assigned_Resource__c> parList = [SELECT User__c FROM Project_Assigned_Resource__c WHERE Project_Line_Item__r.Project__c =: projectId];
        Set<Id> userIds = new Set<Id>();
            for(Project_Assigned_Resource__c par:parList){
                userIds.add(par.User__c);   
            }
        return new List<Id>(userIds); 
    }

    //item.user__c,item.Start_Date__c,item.End_Date__c,item.Project_Line_Item__c
    public static void validatePARs(List<Project_Assigned_Resource__c> PARsList){

        Set<Id> PLIIds = new Set<Id>();
        Set<Id> resourcesIds = new Set<Id>();
        for (Project_Assigned_Resource__c PAR : PARsList) {
            PLIIds.add(PAR.Project_Line_Item__c);
            resourcesIds.add(PAR.User__c);
        }
        Map<Id,User> PARsByUserId = new Map<Id,User>([SELECT Id, Name, Role__c, (SELECT id,User__c,User__r.Name,Start_Date__c,End_Date__c FROM Project_Assigned_Resources__r WHERE End_Date__c>=:Date.Today()) FROM User WHERE Id IN :resourcesIds]);
        Map<Id,Project_Line_Item__c> PLIsByPLIId = new Map<Id,Project_Line_Item__c>([SELECT Project__r.Start_Date__c, Project__r.End_Date__c, Role__c FROM Project_Line_Item__c WHERE Id IN :PLIIds]);
        for(Project_Assigned_Resource__c item :PARsList){
            Project_Line_Item__c currentPLI = PLIsByPLIId.get(item.Project_Line_Item__c);
            User UserPARs = PARsByUserId.get(item.User__c);
            List<Project_Assigned_Resource__c> PARs = UserPARs.Project_Assigned_Resources__r;
            String error = null;
            if(currentPLI.Role__c != UserPARs.Role__c){
                error = 'Los roles del User y el Project_Line_Item__c deben ser iguales';
            } else {
                error = ProjectResourcesHelper.validateAssignedDates(UserPARS.Name, item.Start_Date__c,item.End_Date__c,currentPLI,PARs);
            }  
            if( error!= null)
                item.addError(error);
          }
    }

    public static String validateAssignedDates(String resourceName, Date startDate,Date endDate,Project_Line_Item__c currentPLI,List<Project_Assigned_Resource__c> userAssignedResources){
        String error;
        if(startDate==null || endDate ==null){
            return 'Se deben asignar ambas fechas para '+resourceName;
        }


        if(endDate<startDate){
            error='La fecha de fin de la asignacion no puede ser anterior a la fecha de inicio para '+resourceName;
            return error;
        }     
        if(endDate<Date.today() || startDate<Date.today()){
            error='Las fechas de inicio y fin del proyecto no pueden ser fechas pasadas para '+resourceName;
            return error;
        }
		String dayOfStartDate = getDayOfWeek(startDate);
        String dayOfEndDate= getDayOfWeek(endDate);

        // Valida que las fechas no sean sabado o domingo
        
        /* if(dayOfStartDate == 'Saturday' || dayOfStartDate == 'Sunday'){
                if(dayOfEndDate =='Saturday' || dayOfEndDate == 'Sunday'){
                    error='No se pueden asignar dias no laborales como fecha de termino del proyecto para '+resourceName ;
                    return error;
                }
            error='No se pueden asignar dias no laborales como fecha de inicio del proyecto para '+resourceName;
            return error;		
        } */

        Date projectStartDate = currentPLI.Project__r.Start_Date__c; 
        Date projectEndDate = currentPLI.Project__r.End_Date__c;

        if(startDate<projectStartDate || endDate>projectEndDate){
            error='No se pueden asignar fechas fuera del rango de tiempo del proyecto para '+resourceName;
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
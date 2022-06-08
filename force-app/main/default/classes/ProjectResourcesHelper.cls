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

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjectsOfCurrentUser(){
        Id userId = UserInfo.getUserId();
        return [SELECT id,Name,Squad_Lead__c FROM Project__c];
    }

    @AuraEnabled(cacheable=false) //testeado
    public static List<User> getResourcesByRoleAndDate(String role, Date startDate, Date endDate) {
        List<Project_Assigned_Resource__c> PARs = [SELECT User__c FROM Project_Assigned_Resource__c WHERE (End_Date__c >= :startDate AND End_Date__c <= :endDate) OR (Start_Date__c >= :startDate AND Start_Date__c <= :endDate) OR (Start_Date__c < :startDate AND End_Date__c > :endDate)];
        Set<Id> userIds = new Set<Id>();
        for (Project_Assigned_Resource__c par : PARS) {
            userIds.add(par.User__c);
        }
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c =: role AND Id NOT IN :userIds];
    }

    @AuraEnabled(cacheable=true) //testeado
    public static List<User> getResourcesByRole(String role) {
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c =: role AND Role__c != null];
    }    

    @AuraEnabled(cacheable=true) //testeado
    public static List<User> getResourcesByRoleAndProject(String role, Id projectId) {

        List<Project_Assigned_Resource__c> pars = [SELECT id, Project_Line_Item__r.Role__c, Project_Line_Item__r.Project__c, User__c FROM Project_Assigned_Resource__c 
                                                WHERE Project_Line_Item__r.Role__c =:role AND Project_Line_Item__r.Project__c =:projectId];
        Set<Id> idsToQuery = new Set<Id>();
       
        for(Project_Assigned_Resource__c par : pars){
            system.debug(par);
            idsToQuery.add(par.User__c);
        }
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c != null AND Role__c =:role AND Id IN :idsToquery];
    }    


    @AuraEnabled(cacheable=false) // testeado
    public static Map<Id,User> getResourcesByIdMap(List<User> resources){
        return new Map<Id,User>(resources);
    }

    @AuraEnabled(cacheable=true) // testeado
    public static Project__c getProjectAndPLIs(Id projectId) {
        return [SELECT Id, Name, Start_Date__c, End_Date__c, (SELECT Id,Role__c FROM Project_Line_Items__r) FROM Project__c WHERE Project__c.Id =: projectId LIMIT 1];
    }

    @AuraEnabled(cacheable=true) // testeado
    public static Project_Line_Item__c getProjectLineItem(Id pliId) {
        return [SELECT Id, Name, Role__c, Estimated_Hours__c, Estimated_Amount__c, Assigned_Amount__c, Current_Hours__c, Assigned_Hours__c, Project__c FROM Project_Line_Item__c WHERE Id =: pliId LIMIT 1];
    }


    @AuraEnabled(cacheable=false) // testeado
    public static String insertPARs(List<Project_Assigned_Resource__c>  resources){
        system.debug('dentro de insertPARs');
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

    public static void validateUpdatePARs(List<Project_Assigned_Resource__c> OldPARsList,List<Project_Assigned_Resource__c> NewPARsList){
        for (Integer i=0;i<OldPARsList.size();i++) {
            if(OldPARsList[i].Project_Line_Item__c != NewPARsList[i].Project_Line_Item__c || OldPARsList[i].User__c != NewPARsList[i].User__c || OldPARsList[i].Start_Date__c != NewPARsList[i].Start_Date__c || OldPARsList[i].End_Date__c != NewPARsList[i].End_Date__c || OldPARsList[i].Assigned_Amount__c != NewPARsList[i].Assigned_Amount__c || OldPARsList[i].Assigned_Hour__c != NewPARsList[i].Assigned_Hour__c || OldPARsList[i].Resource_Rate__c != NewPARsList[i].Resource_Rate__c){
                OldPARsList[i].addError('You can not change this field in an Project_Assigned_Resource Object');
            }
        }
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

    @AuraEnabled
    public static void insertTask(Resource_Task__c task){
        system.debug('dentro de insertTask');
        try{
            insert task;
        } catch(DmlException e){
            throw new My1Exception(e.getMessage());  
        }
    }

    @AuraEnabled
    public static Project_Assigned_Resource__c getPARByUserAndDates(Id userId, Date startDate, Date endDate, Id projectId){
        List<Project_Assigned_Resource__c> PARs = [SELECT Start_Date__c, End_Date__c, User__r.Name FROM Project_Assigned_Resource__c WHERE User__c =: userId AND (Start_Date__c <= :startDate AND End_Date__c >= :endDate) AND Project_Line_Item__r.Project__c =: projectId];
        if(PARs.size()>0){
            return PARs[0];
        } else {
            throw new My1Exception('The selected resource is not assigned to the project in the selected Date range'); 
        }
    }

    public static void validateTasks(List<Resource_Task__c> tasks){
        String error=null;
        Set<Id> PARsIds = new Set<Id>();
        for (Resource_Task__c tsk : tasks) {
            PARsIds.add(tsk.Project_Assigned_Resource__c);
        }
        Map<Id, Project_Assigned_Resource__c> PARsMap = new Map<Id, Project_Assigned_Resource__c>([SELECT Id, Start_Date__c, End_Date__c FROM Project_Assigned_Resource__c WHERE Id IN :PARsIds]);
        for (Resource_Task__c tsk1 : tasks) {
            if(tsk1.Start_Date__c>tsk1.End_Date__c){
                error = 'The tasks StartDate must be before the EndDate';
            } else{
                if(PARsMap.get(tsk1.Project_Assigned_Resource__c).Start_Date__c > tsk1.Start_Date__c || PARsMap.get(tsk1.Project_Assigned_Resource__c).End_Date__c < tsk1.End_Date__c){
                    error = 'The task Start and End dates are not inside the dates range of the Project_Assigned_Resource';
                }
            }
            system.debug('error');
            system.debug(error);
            if(error!=null){
                tsk1.addError(error);
            }
        }
        system.debug(error);
    }
      
    @AuraEnabled
    public static Map<Id,List<Resource_Task__c>> getResourceTasksByProjectMap(Id userId){
        List<Resource_Task__c> tasks= [SELECT Id,Allocated_Hours__c,Subject__c,Status__c,Start_Date__c,End_Date__c,Description__c,Priority__c,Registered_Hours__c, Project_Assigned_Resource__c FROM Resource_Task__c WHERE Project_Assigned_Resource__r.User__c =:userId];
        Map<Id,List<Resource_Task__c>> tasksByPARIdMap = new Map<Id,List<Resource_Task__c>>();
        for (Resource_Task__c tsk : tasks){
            List<Resource_Task__c> tasksList = null;
            tasksList = new List<Resource_Task__c>();
            if(tasksByPARIdMap.get(tsk.Project_Assigned_Resource__c)!=null){
                tasksList = tasksByPARIdMap.get(tsk.Project_Assigned_Resource__c);
            }
            tasksList.add(tsk);
            tasksByPARIdMap.put(tsk.Project_Assigned_Resource__c,tasksList);
        }

        List<Project_Assigned_Resource__c> PARs = [SELECT Id, Project_Line_Item__r.Project__c FROM Project_Assigned_Resource__c WHERE User__c =:userId];
        Map<Id,List<Resource_Task__c>> tasksByProjectIdMap = new Map<Id,List<Resource_Task__c>>();
        for (Project_Assigned_Resource__c par : PARs) {
            List<Resource_Task__c> tasksList1 = new List<Resource_Task__c>();
            if(tasksByProjectIdMap.get(par.Project_Line_Item__r.Project__c)!=null){
                tasksList1.addAll(tasksByProjectIdMap.get(par.Project_Line_Item__r.Project__c));
            }
            tasksList1.addAll(tasksByPARIdMap.get(par.Id));
            tasksByProjectIdMap.put(par.Project_Line_Item__r.Project__c,tasksList1);
        }

        return tasksByProjectIdMap;
    }

    @AuraEnabled
    public static Map<Id,Project__c> getProjectsByIdMap(Id userId){
        List<Project_Assigned_Resource__c> PARs = [SELECT Id, Project_Line_Item__r.Project__c FROM Project_Assigned_Resource__c WHERE User__c =:userId];
        Set<Id> projectIdsSet = new Set<Id>();
        for (Project_Assigned_Resource__c par : PARs) {
            projectIdsSet.add(par.Project_Line_Item__r.Project__c);
        } 
        List<Id> projectIds = new List<Id>(projectIdsSet);
        Map<Id,Project__c> projectsByIdMap = new Map<Id,Project__c>([SELECT Name, Stage__c, Squad_Lead__c, 	isCurrentUserSquadLead__c FROM Project__c WHERE Id IN :projectIds]);
        return projectsByIdMap;   
    }


    public class DatesWrapper{
        //varibles
        @AuraEnabled
        public Date startDate;
        @AuraEnabled
        public Date endDate; 
        
        //Constructor
        public DatesWrapper(Date startDate ,Date endDate){
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }

    @AuraEnabled
    public static Map<Id,List<DatesWrapper>> getResourcesAvailability(Id projectId, Date projectStartDate, Date projectEndDate, String role){
       // Project__c project = [SELECT Start_Date__c,End_Date__c FROM Project__c WHERE Id =: projectId];
        List<User> resources = [SELECT Id, Name FROM User WHERE Role__c =: role];
        List<Project_Assigned_Resource__c> PARsList = [SELECT User__c, User__r.Name, Start_Date__c, End_Date__c FROM Project_Assigned_Resource__c WHERE Start_Date__c <= :projectEndDate AND User__r.Role__c =: role AND End_Date__c >= :projectStartDate AND End_Date__c >= :Date.today() ORDER BY Start_Date__c];
        // Creates a map with user Ids keys and lists of Project_Assigned_Resources__c as values 
        Map<Id,List<Project_Assigned_Resource__c>> PARsByUserIdMap = new Map<Id,List<Project_Assigned_Resource__c>>();
        for (Project_Assigned_Resource__c par : PARsList) {
            List<Project_Assigned_Resource__c> assignedPARs = new List<Project_Assigned_Resource__c>();
            if(PARsByUserIdMap.get(par.User__c)!=null){
                assignedPARs.addAll(PARsByUserIdMap.get(par.User__c));
            }
            assignedPARs.add(par);
            PARsByUserIdMap.put(par.User__c,assignedPARs);
        }
        // Creates a map with user Ids as keys and lists of available dates (startDate - endDate) as values 
        Map<Id,List<DatesWrapper>> availDatesByUserId = new Map<Id,List<DatesWrapper>>();
        for (Id userId : PARsByUserIdMap.keySet()) {
            List<DatesWrapper> availableDatesList = new List<DatesWrapper>();
            if(PARsByUserIdMap.get(userId).size()>0){
                for (Integer i=0;i<PARsByUserIdMap.get(userId).size();i++) {
                    if(i==0){
                        if(PARsByUserIdMap.get(userId)[i].Start_Date__c>projectStartDate){
                            availableDatesList.add(new DatesWrapper(projectStartDate,PARsByUserIdMap.get(userId)[i].Start_Date__c-1));
                        }
                        if(i==PARsByUserIdMap.get(userId).size()-1){
                            if(PARsByUserIdMap.get(userId)[i].End_Date__c<projectEndDate){
                                availableDatesList.add(new DatesWrapper(PARsByUserIdMap.get(userId)[i].End_Date__c+1,projectEndDate));
                            }
                        }
                    } else if(i == PARsByUserIdMap.get(userId).size()-1){
                        if(PARsByUserIdMap.get(userId)[i].End_Date__c < projectEndDate){
                            availableDatesList.add(new DatesWrapper(PARsByUserIdMap.get(userId)[i].End_Date__c+1, projectEndDate));
                        }
                        if(PARsByUserIdMap.get(userId)[i].Start_Date__c > PARsByUserIdMap.get(userId)[i-1].End_Date__c + 1){
                            availableDatesList.add(new DatesWrapper(PARsByUserIdMap.get(userId)[i-1].End_Date__c + 1, PARsByUserIdMap.get(userId)[i].Start_Date__c - 1));
                        }

                    } else {
                        if(PARsByUserIdMap.get(userId)[i].Start_Date__c > PARsByUserIdMap.get(userId)[i-1].End_Date__c + 1){
                            availableDatesList.add(new DatesWrapper(PARsByUserIdMap.get(userId)[i-1].End_Date__c + 1, PARsByUserIdMap.get(userId)[i].Start_Date__c - 1));
                        }
                    }   
                }
            }
            availDatesByUserId.put(userId, availableDatesList);
        }
        for (User usr : resources) {
            if(!availDatesByUserId.keySet().contains(usr.Id)){
                List<DatesWrapper> availDatesList = new List<DatesWrapper>();
                availDatesList.add(new DatesWrapper(projectStartDate, projectEndDate));
                availDatesByUserId.put(usr.Id,availDatesList);
            }
        }
        return availDatesByUserId;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,List<Resource_Task__c>> getUserTasks(){
        
        Id userId = UserInfo.getUserId();
        //Octavio ->
        //Id userId = '0058a00000LgxtTAAR';
        //Id userId = '0058a00000Lgxt9AAB';
        Set<Id> projectsID = new Set<Id>();
        
        try{
            List<Project_Assigned_Resource__c> parList = [SELECT User__c,Project_Line_Item__r.Project__r.name,Project_Line_Item__r.Project__c,(SELECT Id,Project_Assigned_Resource__c,Subject__c,Status__c,Start_Date__c,Name,Priority__c,Description__c,Allocated_Hours__c,Registered_Hours__c FROM Resource_Tasks__r ORDER BY Status__c DESC) FROM Project_Assigned_Resource__c WHERE User__c = :userId];

            Map<String,List<Resource_Task__c>> projectTasksMap = new Map<String,List<Resource_Task__c>>();        
                                              
            for(Project_Assigned_Resource__c par  : parList){

                List<Resource_Task__c> resourcesList = new List<Resource_Task__c>();
                if(!projectsID.contains(par.Project_Line_Item__r.Project__c)){
                    projectsID.add(par.Project_Line_Item__r.Project__c);
                } else{
                    resourcesList.addAll(projectTasksMap.get(par.Project_Line_Item__r.Project__r.name));
                }
                resourcesList.addAll(par.Resource_Tasks__r);
                projectTasksMap.put(par.Project_Line_Item__r.Project__r.name,resourcesList);

            }
            
            system.debug(projectTasksMap);
            return projectTasksMap;                       
            }

        catch(Exception e){
            throw new My1Exception(e.getMessage());
        }

        
    }

    @AuraEnabled
    public static void updateTask(Resource_Task__c task){
        update task;
    }

    /* @AuraEnabled
    public static Map<Id,List<Project_Assigned_Resource__c>> getPARsByProjectIdAndRole(Id projectId, String role){
        List<Project_Assigned_Resource__c> PARsList = [SELECT User__c, User__r.Name, Start_Date__c,End_Date__c FROM Project_Assigned_Resource__c WHERE Project_Line_Item__r.Project__c =: projectId AND Project_Line_Item__r.Role__c =: role];
        Map<Id,List<Project_Assigned_Resource__c>> PARsByUserIdMap = new Map<Id,List<Project_Assigned_Resource__c>>();
        for (Project_Assigned_Resource__c par : PARsList) {
            List<Project_Assigned_Resource__c> PARs = new List<Project_Assigned_Resource__c>();
            if(PARsByUserIdMap.get(par.User__c)!=null){
                PARs.addAll(PARsByUserIdMap.get(par.User__c));
            }
            PARs.add(par);
            PARsByUserIdMap.put(par.User__c,PARs);
        }
        return PARsByUserIdMap;
    } */

    @AuraEnabled
    public static List<Project_Assigned_Resource__c> getPARsByProjectIdAndUserId(Id projectId, Id userId){
        return [SELECT User__c, User__r.Name, Start_Date__c,End_Date__c FROM Project_Assigned_Resource__c WHERE Project_Line_Item__r.Project__c =: projectId AND User__c =: userId];
    }
}
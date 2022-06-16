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
        List<Project_Assigned_Resource__c> PARs = [SELECT User__c FROM Project_Assigned_Resource__c WHERE ((End_Date__c >= :startDate AND End_Date__c <= :endDate) OR (Start_Date__c >= :startDate AND Start_Date__c <= :endDate) OR (Start_Date__c < :startDate AND End_Date__c > :endDate)) AND User__r.Role__c =: role];
        Set<Id> userIds = new Set<Id>();
        for (Project_Assigned_Resource__c par : PARS) {
            userIds.add(par.User__c);
        }
        List<out_of_office__c> outOfOffices = [Select User__c, start_date__c, end_date__c FROM out_of_office__c WHERE User__c NOT IN :userIds AND User__r.Role__c=:role AND Status__c='Approved' AND ((end_date__c >= :startDate AND end_date__c <= :endDate) OR (start_date__c >= :startDate AND start_date__c <= :endDate) OR (start_date__c < :startDate AND end_date__c > :endDate))];
        for (out_of_office__c outOfOff : outOfOffices) {
            userIds.add(outOfOff.User__c);
        }
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c =: role AND Id NOT IN :userIds];
    }

    @AuraEnabled(cacheable=true) //testeado
    public static List<User> getResourcesByRole(String role) {
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c =: role AND Role__c != null];
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
        return [SELECT Id, Name, Role__c, Estimated_Hours__c, Estimated_Amount__c, Assigned_Amount__c, Current_Hours__c, Assigned_Hours__c, Project__c, Project__r.Start_Date__c, Project__r.End_Date__c FROM Project_Line_Item__c WHERE Id =: pliId LIMIT 1];
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
        List<Project_Line_Item__c> PLIs = [SELECT Project__r.Start_Date__c, Project__r.End_Date__c, Role__c FROM Project_Line_Item__c WHERE Id IN :PLIIds];
        Map<Id,User> PARsByUserId = new Map<Id,User>([SELECT Id, Name, Role__c, (SELECT id,User__c,User__r.Name,Start_Date__c,End_Date__c FROM Project_Assigned_Resources__r WHERE End_Date__c>=:Date.Today()),(SELECT id,User__c,User__r.Name,start_date__c,end_date__c FROM out_of_office__r WHERE end_date__c>=:Date.Today() AND Status__c = 'Approved') FROM User WHERE Id IN :resourcesIds]);
        Map<Id,Project_Line_Item__c> PLIsByPLIId = new Map<Id,Project_Line_Item__c>(PLIs);
        
        for(Project_Assigned_Resource__c item :PARsList){
            Project_Line_Item__c currentPLI = PLIsByPLIId.get(item.Project_Line_Item__c);
            User UserPARs = PARsByUserId.get(item.User__c);
            List<Project_Assigned_Resource__c> PARs = UserPARs.Project_Assigned_Resources__r;
            List<out_of_office__c> OOOffList = UserPARs.out_of_office__r;
            String error = null;
            if(currentPLI.Role__c != UserPARs.Role__c){
                error = 'Los roles del User y el Project_Line_Item__c deben ser iguales';
            } else {
                error = ProjectResourcesHelper.validateAssignedDates(UserPARS.Name, item.Start_Date__c,item.End_Date__c,currentPLI,PARs,OOOffList);
            }  
            if( error!= null)
                item.addError(error);
        }
        

    }

    public static String validateAssignedDates(String resourceName, Date startDate,Date endDate,Project_Line_Item__c currentPLI,List<Project_Assigned_Resource__c> userAssignedResources, List<out_of_office__c> userOutOfOffices){
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
                error='No pueden asignarse las fechas seleccionadas porque no estan disponibles para ' + assignedResource.User__r.Name;
                return error;
            }
        }
        
        for (out_of_office__c oooffice : userOutOfOffices) {
            Date ooofficeStartDate = oooffice.start_date__c; 
            Date ooofficeEndDate = oooffice.end_date__c;   
            if(startDate<=ooofficeEndDate && endDate>=ooofficeStartDate){
                error='No pueden asignarse las fechas seleccionadas porque el recurso ' + oooffice.User__r.Name +' esta out of office';
                return error;
            }
        }
            
		return error;     
    }

    public static void validateUpdatePARs(List<Project_Assigned_Resource__c> OldPARsList,List<Project_Assigned_Resource__c> NewPARsList){
        for (Integer i=0;i<OldPARsList.size();i++) {
            if(OldPARsList[i].Project_Line_Item__c != NewPARsList[i].Project_Line_Item__c || OldPARsList[i].User__c != NewPARsList[i].User__c || OldPARsList[i].Start_Date__c != NewPARsList[i].Start_Date__c || OldPARsList[i].End_Date__c != NewPARsList[i].End_Date__c || OldPARsList[i].Assigned_Amount__c != NewPARsList[i].Assigned_Amount__c || OldPARsList[i].Assigned_Hour__c != NewPARsList[i].Assigned_Hour__c || OldPARsList[i].Resource_Rate__c != NewPARsList[i].Resource_Rate__c){
                OldPARsList[i].addError('You can not change this field in a Project_Assigned_Resource Object');
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
        Set<Id> userIds = new Set<Id>();
        for (Resource_Task__c tsk : tasks) {
            PARsIds.add(tsk.Project_Assigned_Resource__c);
        }
        List<Project_Assigned_Resource__c> PARs = [SELECT Id, Start_Date__c, End_Date__c,User__c FROM Project_Assigned_Resource__c WHERE Id IN :PARsIds];
        for(Project_Assigned_Resource__c par : PARs){
            userIds.add(par.User__c);
        }
        system.debug('tasks ->'+tasks);
        system.debug('userIds -> '+userIds);
        List<out_of_office__c> oooffcs = [SELECT User__c, start_date__c, end_date__c FROM out_of_office__c WHERE User__c IN :userIds AND Status__c='Approved'];
        system.debug('oooffcs -> '+oooffcs);
        //Create a Map with users Ids as keys and out_of_office lists as values
        Map<Id,List<out_of_office__c>> oooffcsByUserId = new Map<Id,List<out_of_office__c>>();
        for (out_of_office__c oooff : oooffcs) {
            List<out_of_office__c> oooffList = new List<out_of_office__c>();
            if(oooffcsByUserId.get(oooff.User__c)!=null){
                oooffList.addAll(oooffcsByUserId.get(oooff.User__c));
            }
            oooffList.add(oooff);
            oooffcsByUserId.put(oooff.User__c,oooffList);
        }
        system.debug('oooffcsByUserId -> '+oooffcsByUserId);
        Map<Id, Project_Assigned_Resource__c> PARsMap = new Map<Id, Project_Assigned_Resource__c>(PARs);
        for (Resource_Task__c tsk1 : tasks) {
            system.debug('iterando dentro del for de tasks');
            if(tsk1.Start_Date__c>tsk1.End_Date__c){
                error = 'The tasks StartDate must be before the EndDate';
            } else{
                system.debug('dentro del primer else del for');
                if(oooffcsByUserId.get(PARsMap.get(tsk1.Project_Assigned_Resource__c).User__c)!=null){
                    system.debug('dentro del for de tasks con usuario con vacaciones');
                    for (out_of_office__c oooff1 : oooffcsByUserId.get(PARsMap.get(tsk1.Project_Assigned_Resource__c).User__c)) {
                        system.debug('Dentro del loop de los outOfOffices');
                        if((tsk1.Start_Date__c>=oooff1.start_date__c && tsk1.Start_Date__c<=oooff1.end_date__c)||(tsk1.End_Date__c>=oooff1.start_date__c && tsk1.End_Date__c<=oooff1.end_date__c)){
                            system.debug('Dentro del for del outOfOffice y el if de dates');
                            error = 'The resource is out of office during the assigned task dates range';
                        }
                    }
                }
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

    @AuraEnabled
    public static Map<Id,List<DatesWrapper>> getResourcesAvailability(Id projectId, Date projectStartDate, Date projectEndDate, String role){
        List<User> resources = [SELECT Id, Name FROM User WHERE Role__c =: role];
        List<Project_Assigned_Resource__c> PARsList = [SELECT User__c, User__r.Name, Start_Date__c, End_Date__c FROM Project_Assigned_Resource__c WHERE User__r.Role__c =: role AND (Start_Date__c <= :projectEndDate AND End_Date__c >= :projectStartDate) AND End_Date__c >= :Date.today() ORDER BY Start_Date__c];
        List<out_of_office__c> OOOffList = [SELECT User__c, User__r.Name, start_date__c, end_date__c FROM out_of_office__c WHERE User__r.Role__c =: role AND End_Date__c >= :Date.today() AND (start_date__c <= :projectEndDate  AND end_date__c >= :projectStartDate) AND Status__c='Approved' ORDER BY start_date__c];
        
        // Creates a map with user Ids as keys and booked dates (startDate - endDate) as values  
        Map<Id,List<DatesWrapper>> bookedDatesByUserId = new Map<Id,List<DatesWrapper>>();
        Set<Id> bussyResoursesIds = new Set<Id>();
        for (Project_Assigned_Resource__c par : PARsList) {
            List<DatesWrapper> bookedDates = new List<DatesWrapper>();
            if(bookedDatesByUserId.get(par.User__c)!=null){
                bookedDates.addAll(bookedDatesByUserId.get(par.User__c));
            }
            bookedDates.add(new DatesWrapper(par.Start_Date__c,par.End_Date__c));
            bookedDatesByUserId.put(par.User__c,bookedDates);
            bussyResoursesIds.add(par.User__c);
        }
        system.debug('bookedDatesByUserId');
        system.debug(bookedDatesByUserId);
        // Creates a map with user Ids as keys and vacation dates (startDate - endDate) as values 
        Map<Id,List<DatesWrapper>> vacationDatesByUserId = new Map<Id,List<DatesWrapper>>();
        for (out_of_office__c oooff : OOOffList) {
            List<DatesWrapper> vacationDates = new List<DatesWrapper>();
            if(vacationDatesByUserId.get(oooff.User__c)!=null){
                vacationDates.addAll(vacationDatesByUserId.get(oooff.User__c));
            }
            vacationDates.add(new DatesWrapper(oooff.start_date__c,oooff.end_date__c));
            vacationDatesByUserId.put(oooff.User__c,vacationDates);
            bussyResoursesIds.add(oooff.User__c);
        }
        system.debug('vacationDatesByUserId');
        system.debug(vacationDatesByUserId);

        // Creates a map with user Ids as keys and bussy dates (startDate - endDate) as values
        Map<Id,List<DatesWrapper>> bussyDatesByUserId = new Map<Id,List<DatesWrapper>>();
        for(Id usrId : bussyResoursesIds){
            List<DatesWrapper> bussyDatesList = new List<DatesWrapper>();
            if(bookedDatesByUserId.get(usrId)!=null){
                if(vacationDatesByUserId.get(usrId)==null){
                    bussyDatesList=bookedDatesByUserId.get(usrId);
                } else { // the user has both bookedDates and vacationDates
                    List<DatesWrapper> overlappedBussyList = new List<DatesWrapper>();
                    overlappedBussyList.addAll(bookedDatesByUserId.get(usrId));
                    overlappedBussyList.addAll(vacationDatesByUserId.get(usrId));
                    overlappedBussyList.sort();
                    system.debug('overlappedBussyList de usrId'+usrId);
                    system.debug(overlappedBussyList);
                    for (Integer i=0;i< overlappedBussyList.size();i++) {
                        if(i<overlappedBussyList.size()-1){ // it isnt the last element of the list
                            if(overlappedBussyList[i].endDate<overlappedBussyList[i+1].startDate){
                                if(overlappedBussyList[i].startDate>projectStartDate){
                                    bussyDatesList.add(new DatesWrapper(overlappedBussyList[i].startDate,overlappedBussyList[i].endDate));
                                } else {
                                    bussyDatesList.add(new DatesWrapper(projectStartDate,overlappedBussyList[i].endDate));
                                }
                            } else { 
                                if(overlappedBussyList[i].endDate<overlappedBussyList[i+1].endDate){
                                    if(overlappedBussyList[i].startDate>projectStartDate){
                                        bussyDatesList.add(new DatesWrapper(overlappedBussyList[i].startDate,overlappedBussyList[i].endDate));
                                        overlappedBussyList[i+1].startDate = overlappedBussyList[i].endDate + 1;
                                    } else {
                                        bussyDatesList.add(new DatesWrapper(projectStartDate,overlappedBussyList[i].endDate));
                                        overlappedBussyList[i+1].startDate = overlappedBussyList[i].endDate + 1;
                                    }
                                } else {
                                    for(Integer j=i;j<overlappedBussyList.size()-1;j++){
                                        if(overlappedBussyList[i].endDate>overlappedBussyList[j+1].endDate){
                                            overlappedBussyList.remove(j+1);
                                            j=j-1;
                                            system.debug('removiendo elemento '+overlappedBussyList[j+1]+'de overlappedBussyList del usrId '+usrId);
                                        } 
                                    }
                                    if(overlappedBussyList[i].startDate>projectStartDate){
                                            bussyDatesList.add(new DatesWrapper(overlappedBussyList[i].startDate,overlappedBussyList[i].endDate));
                                            //overlappedBussyList.remove(i+1);
                                    } else {
                                            bussyDatesList.add(new DatesWrapper(projectStartDate,overlappedBussyList[i].endDate));
                                            //overlappedBussyList.remove(i+1);
                                    }
                                }

                            }
                        } else { // it is the last element of the list
                            if(i==0){ // it is the only element of the list
                                if(overlappedBussyList[i].startDate < projectStartDate){
                                    bussyDatesList.add(new DatesWrapper(projectStartDate,overlappedBussyList[i].endDate));
                                } else {
                                    if(overlappedBussyList[i].endDate < projectEndDate){
                                        bussyDatesList.add(new DatesWrapper(overlappedBussyList[i].startDate,overlappedBussyList[i].endDate));
                                    } else {
                                        bussyDatesList.add(new DatesWrapper(overlappedBussyList[i].startDate,projectEndDate));
                                    }
                                }
                            } else {
                                if(overlappedBussyList[i].startDate < projectStartDate){
                                    if(overlappedBussyList[i].endDate < projectEndDate){
                                        bussyDatesList.add(new DatesWrapper(projectStartDate,overlappedBussyList[i].endDate));
                                    } else {
                                        bussyDatesList.add(new DatesWrapper(projectStartDate,projectEndDate));
                                    }
                                } else {
                                    if(overlappedBussyList[i].endDate < projectEndDate){
                                        bussyDatesList.add(new DatesWrapper(overlappedBussyList[i].startDate,overlappedBussyList[i].endDate));
                                    } else {
                                        bussyDatesList.add(new DatesWrapper(overlappedBussyList[i].startDate,projectEndDate));
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                bussyDatesList=vacationDatesByUserId.get(usrId);
            }
            system.debug('bussyDatesList userId: '+usrId);
            system.debug(bussyDatesList);
            bussyDatesByUserId.put(usrId,bussyDatesList);
        }



        // Creates a map with user Ids as keys and lists of available dates (startDate - endDate) as values 
        Map<Id,List<DatesWrapper>> availDatesByUserId = new Map<Id,List<DatesWrapper>>();
        for (Id userId : bussyDatesByUserId.keySet()) {
            List<DatesWrapper> availableDatesList = new List<DatesWrapper>();
            if(bussyDatesByUserId.get(userId).size()>0){
                for (Integer i=0;i<bussyDatesByUserId.get(userId).size();i++) {
                    if(i==0){
                        if(bussyDatesByUserId.get(userId)[i].startDate>projectStartDate){
                            availableDatesList.add(new DatesWrapper(projectStartDate,bussyDatesByUserId.get(userId)[i].startDate-1));
                        }
                        if(i==bussyDatesByUserId.get(userId).size()-1){
                            if(bussyDatesByUserId.get(userId)[i].endDate<projectEndDate){
                                availableDatesList.add(new DatesWrapper(bussyDatesByUserId.get(userId)[i].endDate+1,projectEndDate));
                            }
                        }
                    } else if(i == bussyDatesByUserId.get(userId).size()-1){
                        if(bussyDatesByUserId.get(userId)[i].endDate < projectEndDate){
                            availableDatesList.add(new DatesWrapper(bussyDatesByUserId.get(userId)[i].endDate+1, projectEndDate));
                        }
                        if(bussyDatesByUserId.get(userId)[i].startDate > bussyDatesByUserId.get(userId)[i-1].endDate + 1){
                            availableDatesList.add(new DatesWrapper(bussyDatesByUserId.get(userId)[i-1].endDate + 1, bussyDatesByUserId.get(userId)[i].startDate - 1));
                        }

                    } else {
                        if(bussyDatesByUserId.get(userId)[i].startDate > bussyDatesByUserId.get(userId)[i-1].endDate + 1){
                            availableDatesList.add(new DatesWrapper(bussyDatesByUserId.get(userId)[i-1].endDate + 1, bussyDatesByUserId.get(userId)[i].startDate - 1));
                        }
                    }   
                }
            }
            availDatesByUserId.put(userId, availableDatesList);
        }
        // If the user is not assigned to any project in this project dates range:
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
        try{
            update task;
        }
        catch(Exception e){
            throw new My1Exception(e.getMessage());
        }
        
    }

    @AuraEnabled
    public static List<Project_Assigned_Resource__c> getPARsByProjectIdAndUserId(Id projectId, Id userId){
        List<Project_Assigned_Resource__c> PARs = [SELECT User__c, User__r.Name, Start_Date__c,End_Date__c FROM Project_Assigned_Resource__c WHERE Project_Line_Item__r.Project__c =: projectId AND User__c =: userId];
        List<out_of_office__c> oooffcs = [SELECT User__c, start_date__c, end_date__c FROM out_of_office__c WHERE User__c =:userId AND Status__c='Approved'];
        List<Project_Assigned_Resource__c> filteredPARs = new List<Project_Assigned_Resource__c>();
        for (Project_Assigned_Resource__c par : PARs) {
            Boolean isContained = false;
            for(out_of_office__c oooff : oooffcs){
                if(par.Start_Date__c<oooff.start_date__c){
                    if(par.End_Date__c>oooff.start_date__c && par.End_Date__c<oooff.end_date__c){
                        par.End_Date__c = oooff.start_date__c - 1;
                    }
                } else {
                    if(par.End_Date__c <= oooff.end_date__c){
                        isContained = true;
                    } else{
                        par.Start_Date__c = oooff.end_date__c + 1;
                    }
                }
            }
            if(!isContained){
                filteredPARs.add(par);
            }
        }
        return filteredPARs;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getResourcesByRoleAndProject(String role, Id projectId) {

        List<Project_Assigned_Resource__c> pars = [SELECT id, Project_Line_Item__r.Role__c, Project_Line_Item__r.Project__c, User__c FROM Project_Assigned_Resource__c 
                                                WHERE Project_Line_Item__r.Role__c =:role AND Project_Line_Item__r.Project__c =:projectId];
        Set<Id> idsToQuery = new Set<Id>();
       
        for(Project_Assigned_Resource__c par : pars){
            idsToQuery.add(par.User__c);
        }
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c != null AND Role__c =:role AND Id IN :idsToquery];
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjectsOfCurrentUser(){
        Id userId = UserInfo.getUserId();
        
        return [SELECT id,Name,Squad_Lead__c FROM Project__c WHERE Squad_Lead__c =:userId];
    }

    @AuraEnabled(cacheable=false)
    public static void setSquadLead(){
        Id userId = UserInfo.getUserId();
        User me = [SELECT id,imSquadLead__c FROM User WHERE id=:userId];
        List<Project__c> myProjects = [SELECT id,Name,Squad_Lead__c FROM Project__c WHERE Squad_Lead__c =:userId];
        if(myProjects.size()>0){
            me.imSquadLead__c = true;  
        }
        else{
            me.imSquadLead__c = false;
        }
        update me;
    }





    public static void sendEmail(Project__c proj, String error){
        // If we know how many addresses the email will be sent to from this transaction
        // We can set the reserve capacity
        try{
            system.debug('dentro de metodo sendEmail');
            system.debug(proj);
            Messaging.reserveSingleEmailCapacity(1);
    
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            User pm = [SELECT Id,Email FROM USER WHERE Id=:proj.Project_Manager__c];
    
            String pmEMail = pm.Email;
            String[] toAddresses = new String[] {pmEMail};
    
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('El proyecto no puede iniciar');
            mail.setSubject('Accion necesaria del Project Manager');
            mail.setBccSender(false);
            mail.setPlainTextBody('Sample plain text goes here');
            String body = '<!doctypehtml><html lang=en xmlns:o=urn:schemas-microsoft-com:office:office xmlns:v=urn:schemas-microsoft-com:vml><title></title><meta content="text/html; charset=utf-8"http-equiv=Content-Type><meta content="width=device-width,initial-scale=1"name=viewport><!--[if mso]><xml><o:officedocumentsettings><o:pixelsperinch>96</o:pixelsperinch><o:allowpng></o:officedocumentsettings></xml><![endif]--><style>*{box-sizing:border-box}body{margin:0;padding:0}a[x-apple-data-detectors]{color:inherit!important;text-decoration:inherit!important}#MessageViewBody a{color:inherit;text-decoration:none}p{line-height:inherit}.desktop_hide,.desktop_hide table{mso-hide:all;display:none;max-height:0;overflow:hidden}@media (max-width:520px){.desktop_hide table.icons-inner{display:inline-block!important}.icons-inner{text-align:center}.icons-inner td{margin:0 auto}.row-content{width:100%!important}.column.border,.mobile_hide{display:none}table{table-layout:fixed!important}.stack .column{width:100%;display:block}.mobile_hide{min-height:0;max-height:0;max-width:0;overflow:hidden;font-size:0}.desktop_hide,.desktop_hide table{display:table!important;max-height:none!important}}</style><body style=background-color:#fff;margin:0;padding:0;-webkit-text-size-adjust:none;text-size-adjust:none><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0;background-color:#fff width=100% border=0 class=nl-container><tr><td><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class="row row-1"align=center><tr><td><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0;color:#000;width:500px width=500 border=0 class="row-content stack"align=center><tr><td style=mso-table-';
            String body2 = 'lspace:0;mso-table-rspace:0;font-weight:400;text-align:left;vertical-align:top;padding-top:5px;padding-bottom:5px;border-top:0;border-right:0;border-bottom:0;border-left:0 class="column column-1"width=100%><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=image_block><tr><td style=width:100%;padding-right:0;padding-left:0><div align=center style=line-height:10px><img src=https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Salesforce.com_logo.svg/800px-Salesforce.com_logo.svg.png style=display:block;height:auto;border:0;width:100px;max-width:100% width=100></div></table><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=heading_block><tr><td style=width:100%;text-align:center><h1 style="margin:0;color:#555;font-size:23px;font-family:Arial,Helvetica Neue,Helvetica,sans-serif;line-height:120%;text-align:center;direction:ltr;font-weight:700;letter-spacing:normal;margin-top:0;margin-bottom:0"><span class=tinyMce-placeholder>Un proyecto requiere de tu atención</span></h1></table><table cellpadding=10 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=divider_block><tr><td><div align=center><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-';
            String body3 = 'lspace:0;mso-table-rspace:0 width=100% border=0><tr><td style="font-size:1px;line-height:1px;border-top:1px solid #bbb"class=divider_inner><span> </span></table></div></table><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0;word-break:break-word;word-wrap:break-word width=100% border=0 class=html_block><tr><td style=padding-top:60px><div align=center style="font-family:Arial,Helvetica Neue,Helvetica,sans-serif;text-align:center"><div class=our-class>';
            String body35 = '.</div></div></table><table cellpadding=10 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=divider_block><tr><td><div align=center><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0><tr><td style="font-size:1px;line-height:1px;border-top:1px solid #bbb"class=divider_inner><span> </span></table></div></table></table></table><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class="row row-2"align=center><tr><td><table cellpadding=0 cellspacing=0';
            String body4= 'role=presentation style=mso-table-lspace:0;mso-table-rspace:0;color:#000;width:500px width=500 border=0 class="row-content stack"align=center><tr><td style=mso-table-lspace:0;mso-table-rspace:0;font-weight:400;text-align:left;vertical-align:top;padding-top:5px;padding-bottom:5px;border-top:0;border-right:0;border-bottom:0;border-left:0 class="column column-1"width=100%><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=icons_block><tr><td style=vertical-align:middle;color:#9d9d9d;font-family:inherit;font-size:15px;padding-bottom:5px;padding-top:5px;text-align:center><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100%><tr><td style=vertical-align:middle;text-align:center><!--[if vml]><table cellpadding=0 cellspacing=0 role=presentation style=display:inline-block;padding-left:0;padding-';
            String body5= 'right:0;mso-table-lspace:0;mso-table-rspace:0 align=left><![endif]--><!--[if !vml]><!--><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0;display:inline-block;margin-right:-4px;padding-left:0;padding-right:0 class=icons-inner><!--<![endif]--><tr><td style=vertical-align:middle;text-align:center;padding-top:5px;padding-bottom:5px;padding-left:5px;padding-right:6px>td style="font-family:Arial,Helvetica Neue,Helvetica,sans-serif;font-size:15px;color:#9d9d9d;vertical-align:middle;letter-spacing:undefined;text-align:center"><a href=https://www.designedwithbee.com/ style=color:#9d9d9d;text-decoration:none target=_blank></table></table></table></table></table></table>';
    
            String link = 'https://plataforma585-dev-ed.lightning.force.com/lightning/r/Project__c/'+proj.id+'/view';
            
            String linkDiv = '<a href= \'' + link + '\'> <h3>Click para ir al proyecto con problemas<h3></a>';
            String errorMessage = '<b>Motivo:</b> ' + error ;
            String contenido = '<b>El proyecto ' + proj.Name + ' no puede pasar a estado In Progress </b>' +'<br>'+errorMessage+'<br>'+linkDiv;
            
            body = body+body2+body3+contenido+body35+body4+body5;
            mail.setHtmlBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(Exception e){
            throw new My1Exception(e.getMessage());  
        }
        
    }

}
public with sharing class ProjectResourcesValidations {

    //Retorna true si el proyecto pasado por parametro tiene un unico squad lead. De lo contrario retorna false
    public static boolean hasUniqueSquadLead(Project__c project){

        List<Id> userIds = ProjectResourcesHelper.getUserIdsOfProject(project.Id);
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
    // Retorna true si el proyecto es rentable en base a su costo estimado y real
    public static boolean isProfitable(Project__c project){
            if(project.Assigned_Amount__c > project.Estimated_Amount__c)
                return false;
            return true;
    }

    public static void validatePARs(List<Project_Assigned_Resource__c> PARsList){
        Map<Id,User> PARsByUserId = new Map<Id,User>([SELECT Id, (SELECT id,User__c,User__r.Name,Start_Date__c,End_Date__c FROM Project_Assigned_Resources__r WHERE End_Date__c>=:Date.Today()) FROM User]);
        Map<Id,Project_Line_Item__c> PLIsByPLIId = new Map<Id,Project_Line_Item__c>([SELECT Project__r.Start_Date__c, Project__r.End_Date__c FROM Project_Line_Item__c]);
        for(Project_Assigned_Resource__c item :PARsList){
            Project_Line_Item__c currentPLI = PLIsByPLIId.get(item.Project_Line_Item__c);
            User UserPARs = PARsByUserId.get(item.User__c);
            List<Project_Assigned_Resource__c> PARs = UserPARs.Project_Assigned_Resources__r;
            
            String error = ProjectResourcesValidations.validateAssignedDates(item.Start_Date__c,item.End_Date__c,currentPLI,PARs);
            if( error!= null)
                item.addError(error);
          }
    
    }

    public static String validateAssignedDates(Date startDate,Date endDate,Project_Line_Item__c currentPLI,List<Project_Assigned_Resource__c> userAssignedResources){
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
		String dayOfStartDate = Util.getDayOfWeek(startDate);
        String dayOfEndDate= Util.getDayOfWeek(endDate);

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
}
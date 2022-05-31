trigger ProjectTrigger on Project__c (before update) {
	
    for(Project__c proj : trigger.new){
        if(proj.Stage__c != 'Pre-Kickoff'){
         
            if(!ProjectResourcesHelper.projectIsFull(proj)){
                String error = 'El proyecto debe tener todas las horas asignadas para cambiar su estado a In progress';
                //EmailHelper.sendEmail(proj, error);
                proj.addError(error);
                
            }

            if(!ProjectResourcesHelper.isProfitable(proj)){
                String error = 'El proyecto debe ser rentable para cambiar su estado a In progress ';
                //EmailHelper.sendEmail(proj, error);
                proj.addError(error);

            }

            if(!ProjectResourcesHelper.hasUniqueSquadLead(proj)){
                String error = 'El proyecto debe tener asignado un Squad Lead perteneciente al proyecto para cambiar su estado a In progress';
                //EmailHelper.sendEmail(proj, error);
                proj.addError(error);
            }
        } 
    }  
    
}
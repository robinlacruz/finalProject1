trigger ProjectTrigger on Project__c (before update) {

    for(Project__c proj : trigger.new){
        if(proj.Stage__c != 'Pre-Kickoff'){
            Boolean flag = true;
            if(!ProjectResourcesValidations.projectIsFull(proj)){
                String error = 'El proyecto debe tener todas las horas asignadas para cambiar su estado a In progress';
                system.debug(proj.id);
                EmailHelper.sendEmail(proj.id, error);
                system.debug(proj.id);
                proj.addError(error);
                flag=false;
                
            }

            if(!ProjectResourcesValidations.isProfitable(proj) && flag){
                String error = 'El proyecto debe ser rentable para cambiar su estado a In progress ';
                EmailHelper.sendEmail(proj.id, error);
                proj.addError(error);
                flag = false;

            }

            if(!ProjectResourcesValidations.hasUniqueSquadLead(proj) && flag){
                String error = 'El proyecto debe tener asignado un Squad Lead perteneciente al proyecto para cambiar su estado a In progress';
                EmailHelper.sendEmail(proj.id, error);
                proj.addError(error);
            }
        } 
    }  
    
}
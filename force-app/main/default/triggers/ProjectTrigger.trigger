trigger ProjectTrigger on Project__c (before update) {
	
    for(Project__c proj : trigger.new){
        if(proj.Stage__c == 'In progress'){
         
            if(!ProjectResourcesHelper.projectIsFull(proj))
                proj.addError('El proyecto debe tener todas las horas asignadas para cambiar su estado a In progress');
               
            
            //Validar que tenga TODAS las horas asignadas
            //Validar que tenga un squad lead asignado
            //Validar que no este en estado de perdida
            
        }
    }
    
}
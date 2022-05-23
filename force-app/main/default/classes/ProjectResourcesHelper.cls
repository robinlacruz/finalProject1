public with sharing class ProjectResourcesHelper {
	@AuraEnabled(cacheable=true)
    public static  Map<String,List<User>> getProjectResourcesByRol (Id projectId){
        
        List<Project_Line_Item__c>  projectLineItemList= 
        [SELECT Project__c,Role__c,Estimated_Hours__c, (SELECT Id,Start_Date__c, End_Date__c,Assigned_Hour__c,User__c FROM Project_Assigned_Resources__r ) 
        FROM Project_Line_Item__c WHERE Project__c=: projectId];
        
        //Mapa Clave: Rol , Valor : Users asignados
        //
        Map<String,List<User>> resourcesByRole = new Map<String,List<user>>();
       

 		for(Project_Line_Item__c item :projectLineItemList){
           
          List<User> userList = new List<User>(); 
          System.debug('Para el rol [' +item.Role__c + '] se tienen que cubrir :  '+ item.Estimated_Hours__c + ' HORAS');
          System.debug('Las personas disponibles son: ');
            for(User usuario : [SELECT id,name,Role__c FROM User WHERE Role__c =:item.Role__c]){
            	userList.add(usuario);                     
            }
           resourcesByRole.put(item.Role__c, userList);
        	
        }
	return resourcesByRole;
    }//Fin Metodo getLineItemsFromProjectId
    
 
     
    @AuraEnabled(cacheable=true)
    public static  Map<String,List<User>> getAllResourcesByRol (){
        
        List<Project_Line_Item__c>  projectLineItemList= 
        [SELECT Project__c,Role__c,Estimated_Hours__c, (SELECT Id,Start_Date__c, End_Date__c,Assigned_Hour__c,User__c FROM Project_Assigned_Resources__r ) 
        FROM Project_Line_Item__c];
        
        //Mapa Clave: Rol , Valor : Users asignados
        //
        Map<String,List<User>> resourcesByRole = new Map<String,List<user>>();
       

 		for(Project_Line_Item__c item :projectLineItemList){
           
          List<User> userList = new List<User>(); 
          System.debug('Para el rol [' +item.Role__c + '] se tienen que cubrir :  '+ item.Estimated_Hours__c + ' HORAS');
          System.debug('Las personas disponibles son: ');
            for(User usuario : [SELECT id,name,Role__c FROM User WHERE Role__c =:item.Role__c]){
            	userList.add(usuario);                     
            }
           resourcesByRole.put(item.Role__c, userList);
        	
        }
	return resourcesByRole;
    }//Fin Metodo getLineItemsFromProjectId
    
    
    
    
    
    
    
   /* //Utils
    public static List<Date> getDates(){
        List<Date> fechas = new List<Date>();
        for(Integer i = 0; i<20; i++){
            fechas.add(Date.today()+ i);
        }
   		return fechas;
    }*/
    
}
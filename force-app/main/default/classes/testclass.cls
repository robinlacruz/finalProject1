public class testclass {
	
    static List<Project_Line_Item__c> getLineItemsFromProjectId (Id projectId){
        
        List<Project_Line_Item__c>  projectLineItemList= 
        [SELECT Project__c,Role__c, (SELECT Id,Start_Date__c, End_Date__c,Assigned_Hour__c FROM Project_Assigned_Resources__r ) 
        FROM Project_Line_Item__c WHERE id =:projectId];
        
        List<String> rolesList  = new List<String>();
        
 		for(Project_Line_Item__c p : projectLineItemList){
            rolesList.add(p.Role__c);
            rolesList.add(p.Role__c);
        }
	return projectLineItemList;
    }//Fin Metodo getLineItemsFromProjectId
     
    
    public static List<Date> getDates(){
        List<Date> fechas = new List<Date>();
        for(Integer i = 0; i<20; i++){
            fechas.add(Date.today()+ i);
        }
   		return fechas;
    }
    

}
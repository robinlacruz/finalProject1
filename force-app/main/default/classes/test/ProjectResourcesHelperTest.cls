@isTest
public with sharing class ProjectResourcesHelperTest{
    @isTest
    public static void getResourcesByRoleAndDateTest() {
    List<User> listUsers = TestDataFactory.createUsers();
       List<Project_Assigned_Resource__c> pars = TestDataFactory.createPAR(listUsers);
       Date startDate  = Date.newInstance(2022, 18, 9);
       Date endDate  = startDate.addDays(15);
       List<Id> userIds = new List<Id>();
       List<User> devUserList = new List<User>();
       List<User> consUserList = new List<User>();
       List<User> archUserList = new List<User>();
       for(Project_Assigned_Resource__c par : pars){
            if((par.End_Date__c >=startDate && par.End_Date__c <=endDate) || (par.Start_Date__c >= startDate & par.Start_Date__c <= endDate) || (par.Start_Date__c < startDate && par.End_Date__c > endDate))
                userIds.add(par.User__c);
        }         

      for(User u : listUsers){
          if(!userIds.contains(u.id)) {
              if(u.Role__c == 'Developer') devUserList.add(u); 
              if(u.Role__c == 'Consultant') consUserList.add(u); 
              if(u.Role__c == 'Architect') archUserList.add(u); 
          }

      }
      system.debug(devUserList.size());
      system.debug(consUserList.size());
      system.debug(archUserList.size());
      system.assertEquals(devUserList.size(), ProjectResourcesHelper.getResourcesByRoleAndDate('Developer', startDate, endDate).size());
      system.assertEquals(consUserList.size(), ProjectResourcesHelper.getResourcesByRoleAndDate('Consultant', startDate, endDate).size());
      system.assertEquals(archUserList.size(), ProjectResourcesHelper.getResourcesByRoleAndDate('Architect', startDate, endDate).size());
    }
}
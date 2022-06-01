@isTest
public with sharing class ProjectResourcesHelperTest{
    @isTest
    public static void getResourcesByRoleAndDateTest() {
        List<User> usersDB = [SELECT Id, Role__c FROM User WHERE Role__c != null];
        List<User> listUsers = TestDataFactory.createUsers();
        listUsers.addAll(usersDB);
        List<Project_Assigned_Resource__c> pars = TestDataFactory.createPAR(listUsers);
        Date startDate  = Date.today().addDays(30);
        Date endDate  = startDate.addDays(15);
        Set<Id> userIds = new Set<Id>();
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
        List<User> getResByRoleAndDateDevs = ProjectResourcesHelper.getResourcesByRoleAndDate('Developer', startDate, endDate);
        List<User> getResByRoleAndDateCons = ProjectResourcesHelper.getResourcesByRoleAndDate('Consultant', startDate, endDate);
        List<User> getResByRoleAndDateArchs = ProjectResourcesHelper.getResourcesByRoleAndDate('Architect', startDate, endDate);
        
        system.debug(devUserList.size());
        system.debug(consUserList.size());
        system.debug(archUserList.size());
        system.assertEquals(devUserList.size(), getResByRoleAndDateDevs.size());
        system.assertEquals(consUserList.size(), getResByRoleAndDateCons.size());
        system.assertEquals(archUserList.size(), getResByRoleAndDateArchs.size());

        Set<Id> devUserSet = new Set<Id>((new Map<Id,User>(devUserList)).keySet());
        Set<Id> consUserSet = new Set<Id>((new Map<Id,User>(consUserList)).keySet());
        Set<Id> archUserSet = new Set<Id>((new Map<Id,User>(archUserList)).keySet());
        Set<Id> getResByRoleAndDateDevsSet = new Set<Id>((new Map<Id,User>(getResByRoleAndDateDevs)).keySet());
        Set<Id> getResByRoleAndDateConsSet = new Set<Id>((new Map<Id,User>(getResByRoleAndDateCons)).keySet());
        Set<Id> getResByRoleAndDateArchsSet = new Set<Id>((new Map<Id,User>(getResByRoleAndDateArchs)).keySet());

        system.assertEquals(devUserSet, getResByRoleAndDateDevsSet);
        system.assertEquals(consUserSet, getResByRoleAndDateConsSet);
        system.assertEquals(archUserSet, getResByRoleAndDateArchsSet);
    }
}
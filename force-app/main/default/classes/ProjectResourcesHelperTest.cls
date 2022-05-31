@isTest
public with sharing class ProjectResourcesHelperTest {
    @isTest
    static void getResourcesByRoleTest() {
        List<User> userList = new List<User>();
        List<Project_Assigned_Resource__c> parList = new List<Project_Assigned_Resource__c>();
        Profile p = [select id from profile where name = 'System Administrator'];
       for(Integer i=0;i<45;i++){
           User us = new User(alias = 'standt',
                email='a@dolby.com',
                emailencodingkey='UTF-8',
                FirstName = 'hello',
                lastname='Testing',
                languagelocalekey='en_US',
                localesidkey='en_US',
                profileid = p.Id,
                timezonesidkey='America/Los_Angeles',
                CommunityNickname = 'Tom'+i,
                isActive = true,
                username='a@dolby.com'+i,
                Role__c = Math.mod(i,2) == 0 ? 'architect': Math.mod(i,5) == 0 ? 'Consultant' : 'Developer',
                Rate_p_hour__c= i+1);
        userList.add(us);
          
        }
        insert userList;

        for(User user:userList){
            Project_Assigned_Resource__c resource = new Project_Assigned_Resource__c(
                Start_date__c = Date.newInstance(2022, 4, 1),
                End_date__c = Start_date__c.addDays(25),
                User__c= user.id
            );
            parList.add(resource);

        }

        Date startDate = Date.newInstance(2022, 4, 1);
        Date endDate = Date.newInstance(2022, 5, 1);
        List<User> listDevsOutOfDates = new List<User>();
        List<User> listConsOutOfDates = new List<User>();
        List<User> listArchsOutOfDates = new List<User>();

        for(User u:userList){
            if(u.Role__c =='Developer' && !(u.Start_Date__c>= startDate && u.End_Date__c<=endDate))
                listDevsOutOfDates.add(u);
            if(u.Role__c =='Consultant' && !(u.Start_Date__c>= startDate && u.End_Date__c<=endDate))
                listConsOutOfDates.add(u);    
            if(u.Role__c =='Architect' && !(u.Start_Date__c>= startDate && u.End_Date__c<=endDate))
                listArchsOutOfDates.add(u);
        }


        List<User> listDevsOutOfDatesDB = ProjectResourcesHelper.getResourcesByRole('Developer');
        List<User> listConOutOfDatesDB = ProjectResourcesHelper.getResourcesByRole('Consultant');
        List<User> listArchOutOfDatesDB = ProjectResourcesHelper.getResourcesByRole('Architect');

        system.assertEquals(listDevsOutOfDatesDB.size(), listDevsOutOfDatesDB.size());
    }


   /* public static List<User> getResourcesByRole(String role, Date startDate, Date endDate) {
        List<Project_Assigned_Resource__c> PARs = [SELECT User__c FROM Project_Assigned_Resource__c WHERE Start_Date__c >= :startDate AND End_Date__c <= :endDate];
        Set<Id> userIds = new Set<Id>();
        for (Project_Assigned_Resource__c par : PARS) {
            userIds.add(par.User__c);
        }
        return [SELECT Id, Name, Role__c,Rate_p_hour__c FROM User WHERE Role__c =: role AND Id NOT IN :userIds];
    }*/

}
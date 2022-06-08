@isTest
public with sharing class TestDataFactory {
    
    public static List<Project__c> createProjects (Integer numberOfProjects){
        Date startDateP = Date.today().addDays(30);
        Date endDateP = startDateP.addDays(500);
        Date startDate = startDateP;
        Date endDate = endDateP;
        Integer numOfProjects = numberOfProjects;
        List<Account> accounts = new List<Account>();
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i=0;i<numOfProjects;i++){
            accounts.add(new Account(Name= 'Acc name '+i));
            opportunities.add(new Opportunity(Name = 'opp'+i, 
                                              StageName= 'Closed',
                                              CloseDate = Date.today()+i,
                                              EndDate__c = endDate,
                                              StartDate__c = startDate));
            startDate.addDays(30);
            endDate.addDays(30);
        }
        insert accounts;
        insert opportunities;
        List<Project__c> projects = new List<Project__c>();
        for (Integer j=0;j<numOfProjects;j++){
            projects.add(new Project__c(Name = 'Proj '+j,
                                        Account__c = accounts[j].id,
                                        End_Date__c = opportunities[j].EndDate__c,
                                        Estimated_Amount__c = 4000,
                                        OpportunityId__c= opportunities[j].id,
                                        Stage__c = 'Pre-Kickoff',
                                        Start_Date__c = opportunities[j].StartDate__c));
        }
        return projects;
    }
    
    public static List<Project_Line_Item__c> createPLIs(List<Project__c> projects){
        List<Project_Line_Item__c> pLIs = new List<Project_Line_Item__c>();
        for (Integer l=0;l<projects.size();l++){
            pLIs.add(new Project_Line_Item__c(Name='PLI Devs '+Project__c.Name, Project__c = projects[l].id, Estimated_Hours__c = 4000, Role__c = 'Developer'));
            pLIs.add(new Project_Line_Item__c(Name='PLI Cons '+Project__c.Name, Project__c = projects[l].id, Estimated_Hours__c = 2000, Role__c = 'Consultant'));
            pLIs.add(new Project_Line_Item__c(Name='PLI Archs '+Project__c.Name, Project__c = projects[l].id, Estimated_Hours__c = 2000, Role__c = 'Architect'));
        }
        return PLIs;
    }
}
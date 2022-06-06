@isTest
public with sharing class TestDataFactory {

    public static List<User> createUsers(Integer numberOfUsers){

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        List<User> userList = new List<User>();

        for (Integer i =0 ; i<numberOfUsers; i++) {
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            String uid = h.SubString(0,8);
            User u = new User(Alias = uid, Email= uid + '@myorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/New_York', UserName= uid + '@myorg.com',
                Role__c = Math.mod(i,2) == 0 ? 'Architect': Math.mod(i,5) == 0 ? 'Consultant' : 'Developer');      
            userList.add(u);
         }
        return userList;
    }

    public static List<Project_Assigned_Resource__c> createPAR (List<User> userList){
        //
        List<Project_Assigned_Resource__c> PARs = new List<Project_Assigned_Resource__c>();
        Date startDateP = Date.today().addDays(30);
        Date startDate = startDateP;
        Date endDateP = startDateP.addDays(5000);
        Account acc = new Account(Name= 'Acc name');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'opp1', StageName= 'Closed', CloseDate = Date.today(), EndDate__c = endDateP, StartDate__c = startDateP);
        insert opp;
        Project__c proj = new Project__c(Account__c = acc.id, End_Date__c = endDateP, Estimated_Amount__c = 4000, OpportunityId__c= opp.id,Stage__c = 'Pre-Kickoff',Start_Date__c = startDateP);
        insert proj;
        Project_Line_Item__c lineDev = new Project_Line_Item__c(Project__c = proj.id, Estimated_Hours__c = 4000, Role__c = 'Developer');
        Project_Line_Item__c lineCon = new Project_Line_Item__c(Project__c = proj.id, Estimated_Hours__c = 4000, Role__c = 'Consultant');
        Project_Line_Item__c lineArch = new Project_Line_Item__c(Project__c = proj.id, Estimated_Hours__c = 4000, Role__c = 'Architect');
        insert lineDev;
        insert lineCon;
        insert lineArch;

        for(Integer j=0;j<userList.size();j++/* User u : userList */){
            for(Integer i = 0; i<6; i++){
                Project_Assigned_Resource__c par = new Project_Assigned_Resource__c(
                    Start_Date__c = startDate,
                    End_Date__c = startDate.addDays(10),
                    User__c = userList[j].Id,
                    Project_Line_Item__c = userList[j].Role__c == 'Developer'? lineDev.Id : userList[j].Role__c == 'Consultant' ? lineCon.Id : lineArch.Id,
                    Assigned_Hour__c = 1,
                    Resource_Rate__c = 2
                );
                startDate.addDays(20);
                PARs.add(par);
            }
            startDate=Date.today().addDays((j+1)*30);
        }
        return PARs;
    }

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
            opportunities.add(new Opportunity(Name = 'opp'+i, StageName= 'Closed', CloseDate = Date.today()+i, EndDate__c = endDate, StartDate__c = startDate));
            startDate.addDays(30);
            endDate.addDays(30);
        }
        insert accounts;
        insert opportunities;
        List<Project__c> projects = new List<Project__c>();
        for (Integer j=0;j<numOfProjects;j++){
            projects.add(new Project__c(Name = 'Proj '+j,Account__c = accounts[j].id, End_Date__c = opportunities[j].EndDate__c, Estimated_Amount__c = 4000, OpportunityId__c= opportunities[j].id,Stage__c = 'Pre-Kickoff',Start_Date__c = opportunities[j].StartDate__c)); 
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
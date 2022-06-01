@isTest
public with sharing class TestDataFactory {
    public static List<User> createUsers(){

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        List<User> userList = new List<User>();

        for (Integer i =0 ; i<120; i++) {
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
    insert(userList);
        return userList;
    }

    public static List<Project_Assigned_Resource__c> createPAR (List<User> userList){
        //
        List<Project_Assigned_Resource__c> PARs = new List<Project_Assigned_Resource__c>();
        Date startDate;
        Date startDateP = Date.newInstance(2022, 1, 1);
        Date endDateP = Date.newInstance(2022, 12, 31);
        Account acc = new Account(Name= 'Acc name');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'opp1', StageName= 'Closed', CloseDate = Date.newInstance(2022, 1, 1), EndDate__c = endDateP, StartDate__c = startDateP);
        insert opp;
        Project__c proj = new Project__c(Account__c = acc.id, End_Date__c = endDateP, Estimated_Amount__c = 4000, OpportunityId__c= opp.id,Stage__c = 'Pre-Kickoff',Start_Date__c = startDateP);
        insert proj;
        Project_Line_Item__c lineDev = new Project_Line_Item__c(Project__c = proj.id, Estimated_Hours__c = 4000, Role__c = 'Developer');
        Project_Line_Item__c lineCon = new Project_Line_Item__c(Project__c = proj.id, Estimated_Hours__c = 4000, Role__c = 'Consultant');
        Project_Line_Item__c lineArch = new Project_Line_Item__c(Project__c = proj.id, Estimated_Hours__c = 4000, Role__c = 'Architect');
        insert lineDev;
        insert lineCon;
        insert lineArch;

        for(User u : userList){
            startDate = Date.newInstance(2022, 1,12);
            for(Integer i = 0; i<18; i++){
                Project_Assigned_Resource__c par = new Project_Assigned_Resource__c(
                    Start_Date__c = startDate.addDays(i),
                    End_Date__c = startDate.addDays(i+10),
                    User__c = u.id,
                    Project_Line_Item__c = u.role__c == 'Developer'? lineDev.id : u.role__c == 'Consultant' ? lineCon.id : lineArch.id,
                    Assigned_Hour__c = 1,
                    Resource_Rate__c = 2
                );
                startDate.addDays(11);
                PARs.add(par);
            }
        }
        insert PARs;
        return PARs;
    }
}
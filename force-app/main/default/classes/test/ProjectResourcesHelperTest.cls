@isTest
public with sharing class ProjectResourcesHelperTest{

    @isTest
    public static void getResourcesByRoleAndDateTest() {
        List<User> users = TestDataFactory.createUsers(12);
        insert users;
        List<User> listUsers = [SELECT Id, Role__c FROM User WHERE Role__c != null];
        List<Project_Assigned_Resource__c> pars = TestDataFactory.createPAR(listUsers);
        insert pars;
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

    @isTest
    public static void getResourcesByRoleTest(){
        
        List<User> newUsers = TestDataFactory.createUsers(120);
        insert newUsers;
        List<User> listUsers = [SELECT Id, Role__c FROM User WHERE Role__c != null];

        List<User> developers = new List<User>();
        List<User> architects = new List<User>();
        List<User> consultants = new List<User>();

        for (User u : listUsers) {
            if(u.Role__c == 'Developer') developers.add(u); 
            if(u.Role__c == 'Consultant') consultants.add(u); 
            if(u.Role__c == 'Architect') architects.add(u);
        }

        system.assertEquals(developers.size(), ProjectResourcesHelper.getResourcesByRole('Developer').size());
        system.assertEquals(consultants.size(), ProjectResourcesHelper.getResourcesByRole('Consultant').size());
        system.assertEquals(architects.size(), ProjectResourcesHelper.getResourcesByRole('Architect').size());

        Set<Id> devUserSet = new Set<Id>((new Map<Id,User>(developers)).keySet());
        Set<Id> consUserSet = new Set<Id>((new Map<Id,User>(consultants)).keySet());
        Set<Id> archUserSet = new Set<Id>((new Map<Id,User>(architects)).keySet());
        Set<Id> getResourcesByRoleDevSet = new Set<Id>((new Map<Id,User>(ProjectResourcesHelper.getResourcesByRole('Developer'))).keySet());
        Set<Id> getResourcesByRoleConsSet = new Set<Id>((new Map<Id,User>(ProjectResourcesHelper.getResourcesByRole('Consultant'))).keySet());
        Set<Id> getResourcesByRoleArchSet = new Set<Id>((new Map<Id,User>(ProjectResourcesHelper.getResourcesByRole('Architect'))).keySet());

        system.assertEquals(devUserSet, getResourcesByRoleDevSet);
        system.assertEquals(consUserSet, getResourcesByRoleConsSet);
        system.assertEquals(archUserSet, getResourcesByRoleArchSet);
    }

    @isTest
    public static void getResourcesByIdMapTest(){  
        List<User> newUsers = TestDataFactory.createUsers(120);
        insert newUsers;
        List<User> listUsers = [SELECT Id, Role__c FROM User WHERE Role__c != null];

        Map<Id,User> usersMap = new Map<Id,User>(listUsers);
        system.assertEquals(usersMap, ProjectResourcesHelper.getResourcesByIdMap(listUsers));
    }

    @isTest
    public static void getProjectAndPLIsTest(){
        List<Project__c> projects = TestDataFactory.createProjects(5);
        insert projects;
        List<Project_Line_Item__c> pLIs = TestDataFactory.createPLIs(projects);
        insert pLIs;
        Map<Id,List<Project_Line_Item__c>> pLIsByProjectIdMap = new Map<Id,List<Project_Line_Item__c>>();
        for (Project_Line_Item__c pli : PLIs) {
            List<Project_Line_Item__c> pliList = new List<Project_Line_Item__c>();
            if(pLIsByProjectIdMap.get(pli.Project__c)!=null){
                pliList = pLIsByProjectIdMap.get(pli.Project__c);
            }
            pliList.add(pli);
            pLIsByProjectIdMap.put(pli.Project__c,pliList);
        }

        for (Project__c project : projects) {
            system.assertEquals(pLIsByProjectIdMap.get(project.Id).size(), ProjectResourcesHelper.getProjectAndPLIs(project.Id).Project_Line_Items__r.size());
            List<Project_Line_Item__c> ProjLinItems = pLIsByProjectIdMap.get(project.Id);
            Map<Id,Project_Line_Item__c> PLIsMap = new Map<Id,Project_Line_Item__c>(ProjLinItems);
            List<Project_Line_Item__c> ProjLinItemsRec = ProjectResourcesHelper.getProjectAndPLIs(project.Id).Project_Line_Items__r;
            Map<Id,Project_Line_Item__c> PLIsMap1 = new Map<Id,Project_Line_Item__c>(ProjLinItemsRec);
            system.assertEquals(PLIsMap.keySet(), PLIsMap1.keySet()); 
        }
    }

    @isTest 
    public static void getProjectLineItemTest(){
        List<Project__c> projects = TestDataFactory.createProjects(1);
        insert projects;
        List<Project_Line_Item__c> pLIs = TestDataFactory.createPLIs(projects);
        insert pLIs;
        for (Project_Line_Item__c pli : pLIs) {
            system.assertEquals(pli.Id, ProjectResourcesHelper.getProjectLineItem(pli.Id).Id);
        }
    }

    @isTest 
    public static void getDayOfWeekTest(){
        Date date1 = Date.newInstance(2022, 06, 02);
        system.assertEquals('Thursday', ProjectResourcesHelper.getDayOfWeek(date1));
    }

    @isTest 
    public static void getBusinessHoursCountTest(){
        Date date1 = Date.newInstance(2022, 06, 02);
        Date date2 = Date.newInstance(2022, 06, 07);
        system.assertEquals(32, ProjectResourcesHelper.getBusinessHoursCount(date1,date2));
    }

    @isTest 
    public static void insertPARsTest(){
        List<User> users = TestDataFactory.createUsers(10);
        insert users;
        List<User> listUsers = [SELECT Id, Role__c FROM User WHERE Role__c != null];
        List<Project_Assigned_Resource__c> pars = TestDataFactory.createPAR(listUsers);
        System.assertEquals('Operacion DML realizada correctamente', ProjectResourcesHelper.insertPARs(pars));
        List<Project_Assigned_Resource__c> repeatedPars = TestDataFactory.createPAR(listUsers);
        repeatedPars[0].Project_Line_Item__c = null;
        String error = null;
        try{
            ProjectResourcesHelper.insertPARs(repeatedPars);
        } catch(Exception e){
            error = e.getMessage();
        }
        System.assert(error!=null);
    }

    @isTest 
    public static void hasUniqueSquadLeadTest(){
        List<User> users = TestDataFactory.createUsers(20);
        insert users;
        List<User> listUsers = [SELECT Id, Role__c FROM User WHERE Role__c != null];
        List<User> firstHalfListUsers = new List<User>();
        List<User> secondHalfListUsers = new List<User>();
        for(Integer i=0;i<listUsers.size();i++){
            if(Math.mod(i,2)==0){
                firstHalfListUsers.add(listUsers[i]);
            } else {
                secondHalfListUsers.add(listUsers[i]);
            }
        }
        List<Project_Assigned_Resource__c> pars = TestDataFactory.createPAR(firstHalfListUsers);
        insert pars;
        List<Project__c> project = [SELECT Id,Squad_Lead__c FROM Project__c];
        System.assertEquals(false, ProjectResourcesHelper.hasUniqueSquadLead(project[0]));
        project[0].Squad_Lead__c = secondHalfListUsers[0].Id;
        update project[0];
        project = [SELECT Id,Squad_Lead__c FROM Project__c];
        System.assertEquals(false, ProjectResourcesHelper.hasUniqueSquadLead(project[0]));
        project[0].Squad_Lead__c = firstHalfListUsers[0].Id;
        update project[0];
        project = [SELECT Id,Squad_Lead__c FROM Project__c];
        System.assertEquals(true, ProjectResourcesHelper.hasUniqueSquadLead(project[0]));
    }

    @isTest 
    public static void projectIsFullTest(){
        List<User> users = TestDataFactory.createUsers(10);
        insert users;
        User developer = new User();
        User consultant = new User();
        User architect = new User();
        for (User us : users) {
            if(us.Role__c=='Architect') architect = us;
            if(us.Role__c=='Developer') developer= us;
            if(us.Role__c=='Consultant') consultant = us;
        }
        List<Project__c> projects = TestDataFactory.createProjects(1);
        insert projects;
        List<Project_Line_Item__c> pLIs = TestDataFactory.createPLIs(projects);
        insert pLIs;
        system.assertEquals(false, ProjectResourcesHelper.projectIsFull(projects[0]));
        List<Project_Line_Item__c> pLIsfromDB = [SELECT Id, Estimated_Hours__c, Assigned_Hours__c, Role__c FROM Project_Line_Item__c WHERE Project__c =: projects[0].Id];
        List<Project_Assigned_Resource__c> pARs = new List<Project_Assigned_Resource__c>();
        for (Project_Line_Item__c pLI : pLIsfromDB) {
            Project_Assigned_Resource__c par = new Project_Assigned_Resource__c(
                    Start_Date__c = projects[0].Start_Date__c,
                    End_Date__c = projects[0].Start_Date__c.addDays(10),
                    User__c = pLI.Role__c == 'Architect'? architect.Id: pLI.Role__c == 'Developer'? developer.Id : consultant.Id,
                    Project_Line_Item__c = pLI.Id,
                    Assigned_Hour__c = pLI.Estimated_Hours__c,
                    Resource_Rate__c = 2
                );
                pARs.add(par);
        }
        insert pARs;
        system.assertEquals(true, ProjectResourcesHelper.projectIsFull(projects[0]));
    }

    @isTest 
     public static void isProfitableTest(){ 
        List<User> users = TestDataFactory.createUsers(10);
        insert users;
        Integer resourcesRate = 2;
        User developer = new User();
        User consultant = new User();
        User architect = new User();
        for (User us : users) {
            if(us.Role__c=='Architect') architect = us;
            if(us.Role__c=='Developer') developer= us;
            if(us.Role__c=='Consultant') consultant = us;
        }
        List<Project__c> projects = TestDataFactory.createProjects(1);
        insert projects;
        List<Project_Line_Item__c> pLIs = TestDataFactory.createPLIs(projects);
        insert pLIs;
        projects = [SELECT Id, Start_Date__c, Estimated_Amount__c, Assigned_Amount__c FROM Project__c];
        List<Project_Line_Item__c> pLIsfromDB = [SELECT Id, Estimated_Hours__c, Assigned_Hours__c, Role__c FROM Project_Line_Item__c WHERE Project__c =: projects[0].Id];
        List<Project_Assigned_Resource__c> pARs = new List<Project_Assigned_Resource__c>();
        Integer totalAssignedHours = 0;
        for (Project_Line_Item__c pLI : pLIsfromDB) {
            Project_Assigned_Resource__c par = new Project_Assigned_Resource__c(
                    Start_Date__c = projects[0].Start_Date__c,
                    End_Date__c = projects[0].Start_Date__c.addDays(10),
                    User__c = pLI.Role__c == 'Architect'? architect.Id: pLI.Role__c == 'Developer'? developer.Id : consultant.Id,
                    Project_Line_Item__c = pLI.Id,
                    Assigned_Hour__c = pLI.Estimated_Hours__c,
                    Resource_Rate__c = resourcesRate,
                    Assigned_Amount__c = pLI.Estimated_Hours__c*resourcesRate
                );
                totalAssignedHours+=(Integer)par.Assigned_Hour__c;
                pARs.add(par);
        }
        insert pARs;
        projects[0].Estimated_Amount__c = totalAssignedHours*resourcesRate;
        update projects;
        projects = [SELECT Id, Start_Date__c, Estimated_Amount__c, Assigned_Amount__c FROM Project__c];
        system.assertEquals(true, ProjectResourcesHelper.isProfitable(projects[0]));
        
        projects[0].Estimated_Amount__c = totalAssignedHours*(resourcesRate-1);
        update projects;
        projects = [SELECT Id, Start_Date__c, Estimated_Amount__c, Assigned_Amount__c FROM Project__c];
        system.assertEquals(false, ProjectResourcesHelper.isProfitable(projects[0]));
    }

    @isTest 
    public static void getUserIdsOfProjectTest(){
        List<User> users = TestDataFactory.createUsers(10);
        insert users;
        users = [SELECT Id, Role__c FROM User];
        Map<String,List<User>> usersByRoleMap = new Map<String,List<User>>();
        for (user us : users) {
            if(usersByRoleMap.get(us.Role__c)!=null){
                List<User> resources = usersByRoleMap.get(us.Role__c);
                resources.add(us);
                usersByRoleMap.put(us.Role__c, resources);
            } else {
                List<User> resources = new List<User>();   
                resources.add(us);
                usersByRoleMap.put(us.Role__c, resources);     
            }
            
        }
        List<Project__c> projects = TestDataFactory.createProjects(2);
        insert projects;
        List<Project_Line_Item__c> pLIs = TestDataFactory.createPLIs(projects);
        insert pLIs;
        Integer k=0;
        Integer resourcesRate=2;
        Set<Id> project1resources = new Set<Id>();
        Set<Id> project2resources = new Set<Id>();
        List<Project_Assigned_Resource__c> pARs = new List<Project_Assigned_Resource__c>();
        
        for (Project_Line_Item__c pLI : pLIs) {
            if(pLI.Project__c == projects[0].Id){
                Project_Assigned_Resource__c par = new Project_Assigned_Resource__c(
                    Start_Date__c = projects[0].Start_Date__c,
                    End_Date__c = projects[0].Start_Date__c.addDays(10),
                    User__c = usersByRoleMap.get(pLI.Role__c)[0].Id,
                    Project_Line_Item__c = pLI.Id,
                    Assigned_Hour__c = pLI.Estimated_Hours__c,
                    Resource_Rate__c = resourcesRate,
                    Assigned_Amount__c = pLI.Estimated_Hours__c*resourcesRate
                );
                pARs.add(par);
                project1resources.add(usersByRoleMap.get(pLI.Role__c)[0].Id);
            } else if(pLI.Project__c == projects[1].Id){
                Project_Assigned_Resource__c par = new Project_Assigned_Resource__c(
                    Start_Date__c = projects[1].Start_Date__c,
                    End_Date__c = projects[1].Start_Date__c.addDays(10),
                    User__c = usersByRoleMap.get(pLI.Role__c)[1].Id,
                    Project_Line_Item__c = pLI.Id,
                    Assigned_Hour__c = pLI.Estimated_Hours__c,
                    Resource_Rate__c = resourcesRate,
                    Assigned_Amount__c = pLI.Estimated_Hours__c*resourcesRate
                );
                pARs.add(par);
                project2resources.add(usersByRoleMap.get(pLI.Role__c)[1].Id);
            }    
        }
        insert pARs;

        system.assertEquals(new List<Id>(project1resources), ProjectResourcesHelper.getUserIdsOfProject(projects[0].Id));
        system.assertEquals(new List<Id>(project2resources), ProjectResourcesHelper.getUserIdsOfProject(projects[1].Id));
        system.assert(ProjectResourcesHelper.getUserIdsOfProject(projects[0].Id)!=new List<Id>(project2resources));
    }

    @isTest 
    public static void validatePARsTest(){
        List<User> users = TestDataFactory.createUsers(10);
        insert users;
        users = [SELECT Id, Role__c FROM User];
        Map <Id,User> usersByIdMap = new Map<Id,User>(users);
        Map<String,List<User>> usersByRoleMap = new Map<String,List<User>>();
        for (user us : users) {
            if(usersByRoleMap.get(us.Role__c)!=null){
                List<User> resources = usersByRoleMap.get(us.Role__c);
                resources.add(us);
                usersByRoleMap.put(us.Role__c, resources);
            } else {
                List<User> resources = new List<User>();   
                resources.add(us);
                usersByRoleMap.put(us.Role__c, resources);     
            }
            
        }
        List<Project__c> projects = TestDataFactory.createProjects(2);
        insert projects;
        List<Project_Line_Item__c> pLIs = TestDataFactory.createPLIs(projects);
        insert pLIs;
        Integer k=0;
        Integer resourcesRate=2;
        Set<Id> project1resources = new Set<Id>();
        Set<Id> project2resources = new Set<Id>();
        List<Project_Assigned_Resource__c> pARs = new List<Project_Assigned_Resource__c>();
        
        for (Project_Line_Item__c pLI : pLIs) {
            if(pLI.Project__c == projects[0].Id){
                Project_Assigned_Resource__c par = new Project_Assigned_Resource__c(
                    Start_Date__c = projects[0].Start_Date__c,
                    End_Date__c = projects[0].Start_Date__c.addDays(10),
                    User__c = usersByRoleMap.get(pLI.Role__c)[0].Id,
                    Project_Line_Item__c = pLI.Id,
                    Assigned_Hour__c = pLI.Estimated_Hours__c,
                    Resource_Rate__c = resourcesRate,
                    Assigned_Amount__c = pLI.Estimated_Hours__c*resourcesRate
                );
                pARs.add(par);
                project1resources.add(usersByRoleMap.get(pLI.Role__c)[0].Id);
            } else if(pLI.Project__c == projects[1].Id){
                Project_Assigned_Resource__c par = new Project_Assigned_Resource__c(
                    Start_Date__c = projects[1].Start_Date__c,
                    End_Date__c = projects[1].Start_Date__c.addDays(10),
                    User__c = usersByRoleMap.get(pLI.Role__c)[1].Id,
                    Project_Line_Item__c = pLI.Id,
                    Assigned_Hour__c = pLI.Estimated_Hours__c,
                    Resource_Rate__c = resourcesRate,
                    Assigned_Amount__c = pLI.Estimated_Hours__c*resourcesRate
                );
                pARs.add(par);
                project2resources.add(usersByRoleMap.get(pLI.Role__c)[1].Id);
            }    
        }
        String error=null;
        try{
            insert pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error==null);
        error=null;
        String usRole = usersByIdMap.get(pARs[0].User__c).Role__c;
        Id firstpARsUser = pARs[0].User__c;
        pARs[0].User__c = usRole=='Developer'? usersByRoleMap.get('Consultant')[0].Id : usRole=='Architect'? usersByRoleMap.get('Developer')[0].Id: usersByRoleMap.get('Architect')[0].Id;
        try{
            update pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('Los roles del User y el Project_Line_Item__c deben ser iguales'));
        pARs[0].User__c = firstpARsUser;
        Date firstpARsStartDate = pARs[0].Start_Date__c;
        pARs[0].Start_Date__c = null;
        error=null;
        try{
            update pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('Se deben asignar ambas fechas para'));
        pARs[0].Start_Date__c = firstpARsStartDate;
        Date firstpARsEndDate = pARs[0].End_Date__c;
        pARs[0].End_Date__c = firstpARsStartDate.addDays(-10);
        error=null;
        try{
            update pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('La fecha de fin de la asignacion no puede ser anterior a la fecha de inicio para'));
        pARs[0].End_Date__c = firstpARsEndDate;
        pARs[0].Start_Date__c = Date.today().addDays(-10);
        error=null;
        try{
            update pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('Las fechas de inicio y fin del proyecto no pueden ser fechas pasadas para'));
        pARs[0].Start_Date__c = projects[0].Start_Date__c.addDays(-10);
        error=null;
        try{
            update pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('No se pueden asignar fechas fuera del rango de tiempo del proyecto para'));
        pARs[0].Start_Date__c = projects[0].Start_Date__c;
        pARs[0].End_Date__c = projects[0].End_Date__c;
        error=null;
        try{
            update pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('No pueden asignarse las fechas seleccionadas porque no estan disponibles para'));
    }
}
@isTest
public with sharing class ProjectResourcesHelperTest{

    @isTest
    static void testUpdateStageToInProgressWithoutSL(){
        //comprobar que el trigger se activa en condición de que no hay un Squad Lead asignado
        //Generar usuarios para asignarlos a diferentes listas de roles, PM incluido
        List<User> listOfUser = [SELECT id, name, role__c, rate_p_hour__c from user];
        List<User> listOfPMs = new List<User>();
        List<User> listOfDevelopers = new List<User>();
        List<User> listOfConsultants = new List<User>();
        List<User> listOfArchitects = new List<User>();
        for (User u : listOfUser){
            if (u.role__c=='PM'){
                listofPMs.add(u);
            }else if (u.role__c=='Developer'){
                listOfDevelopers.add(u);
            }else if (u.role__c=='Architect'){
                listOfArchitects.add(u);
            }else if (u.role__c=='Consultant'){
                listOfConsultants.add(u);
            }
        }
        //Invocar TestDataFactory para crear proyectos, luego insertar
        //***No se asigna Squad Lead a los proyectos para que el trigger se active y devuelva un error***
        List<Project__c> listOfProjects = TestDataFactory.createProjects(50);
        for (Project__c eachProj : listOfProjects){
            eachProj.Project_Manager__c = listofPMs[0].id;
        }
        insert listOfProjects;
        //Invocar TestDataFactory para crear los project line items relacionados a cada proyecto
        List<Project_Line_Item__c> listOfPLI = TestDataFactory.createPLIs(listOfProjects);
        List<Project_Assigned_Resource__c> listOfPAR = new List<Project_Assigned_Resource__c>();
        //Agregar un Estimated Amount así se llena el rollup Assigned Amount de Project
        for (Project_line_item__c eachPLI : listOfPLI){
            eachPLI.Estimated_Amount__c = 5000;
        }
        insert listOfPLI;
        //crear los Project Assigned Resource relacionado a cada PLI, insertarlos al final
        integer i = 0;
        for (Project_line_item__c eachPLI : listOfPLI){
            //busco que usuario le voy a asignar al assigned resource, debe coincidir con el del line item
        	User actualUser;
            if (eachPLI.Role__c == 'Developer'){
                actualUser=listOfDevelopers[0];
                    }else if (eachPLI.Role__c == 'Architect'){
                        actualUser=listOfArchitects[0];
                            } else if (eachPLI.Role__c == 'Consultant'){
                                actualUser=listOfConsultants[0];}
            //Crear un PAR para cada PLI con usuario del rol correspondiente
            Project_Assigned_Resource__c PAR = new Project_Assigned_Resource__c(
                name='par'+i,
                Project_Line_Item__c=eachPLI.id,
                Resource_Rate__c = 10,
                Start_Date__c = DATE.TODAY().addDays(1+i*100),
                End_Date__c = DATE.today().addDays(100+i*100),
                User__c = actualUser.Id,
                Assigned_amount__c = 1000,
                Assigned_Hour__c = eachPli.Estimated_Hours__c);
            i++;
            listOfPAR.add(PAR);
        }
        insert listOfPar;
        update listOfPLI;
        update listOfProjects;
        //Realizar queries de Project para que se actualicen los campos roll-up
        List<project__c> testProjects = new List<project__c>();
        List<Project_Line_Item__c> testProjLineItems = new List<Project_Line_Item__c>();
        testProjects = [SELECT Id, Assigned_amount__c, Estimated_amount__c, Stage__c from project__c];
        
        //Generar un String error que se llena en caso de que se active el trigger
        //Comenzar el test
        String error=null;
        test.startTest();
        for (Project__c eachProj : testProjects){
            eachProj.Stage__c = 'in progress';
        }
        try{
	         update testProjects;
        }catch(Exception e){
            error=e.getMessage();
        }
        test.stopTest();
        System.assert(error!=null);

    }
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
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User us = new User(Alias = 'userWOOO', Email= 'userWithOutOfOffice@myorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/New_York', UserName= 'userWithOutOfOffice@myorg.com',
                Role__c = 'Developer');
        insert us;
        listUsers.add(us);
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

        out_of_office__c outOfOff = new out_of_office__c(User__c = us.Id, start_date__c=startDate ,end_date__c=endDate, Status__c='Approved');
        insert outOfOff;
        getResByRoleAndDateDevs = ProjectResourcesHelper.getResourcesByRoleAndDate('Developer', startDate, endDate);
        getResByRoleAndDateDevsSet = new Set<Id>((new Map<Id,User>(getResByRoleAndDateDevs)).keySet());
        system.assertEquals(devUserList.size()-1, getResByRoleAndDateDevs.size());
        devUserSet.remove(us.Id);
        system.assertEquals(devUserSet, getResByRoleAndDateDevsSet);
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
        delete pARs;
        List<Project_Assigned_Resource__c> pARs1 = new List<Project_Assigned_Resource__c>();
        for (Project_Assigned_Resource__c par : pARs) {
            Map<String, Object> parMap = (Map<String, Object>) JSON.deserializeUntyped( JSON.serialize( par ) );
            parMap.remove('Id');
            Project_Assigned_Resource__c par1 = (Project_Assigned_Resource__c) JSON.deserialize( JSON.serialize( parMap ), Project_Assigned_Resource__c.class );
            pARs1.add(par1);
        }
        pARs = pARs1;
        String usRole = usersByIdMap.get(pARs[0].User__c).Role__c;
        Id firstpARsUser = pARs[0].User__c;
        pARs[0].User__c = usRole=='Developer'? usersByRoleMap.get('Consultant')[0].Id : usRole=='Architect'? usersByRoleMap.get('Developer')[0].Id: usersByRoleMap.get('Architect')[0].Id;
        try{
            insert pARs;
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
            insert pARs;
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
            insert pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('La fecha de fin de la asignacion no puede ser anterior a la fecha de inicio para'));
        pARs[0].End_Date__c = firstpARsEndDate;
        pARs[0].Start_Date__c = Date.today().addDays(-10);
        error=null;
        try{
            insert pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('Las fechas de inicio y fin del proyecto no pueden ser fechas pasadas para'));
        
        pARs[0].Start_Date__c = projects[0].Start_Date__c.addDays(-10);
        error=null;
        try{
            insert pARs;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('No se pueden asignar fechas fuera del rango de tiempo del proyecto para'));
        
        pARs[0].Start_Date__c = projects[0].Start_Date__c;
        pARs[0].End_Date__c = projects[0].End_Date__c;
        error=null;
        insert pARs;
        pARs1 = new List<Project_Assigned_Resource__c>();
        for (Project_Assigned_Resource__c par : pARs) {
            Map<String, Object> parMap = (Map<String, Object>) JSON.deserializeUntyped( JSON.serialize( par ) );
            parMap.remove('Id');
            Project_Assigned_Resource__c par1 = (Project_Assigned_Resource__c) JSON.deserialize( JSON.serialize( parMap ), Project_Assigned_Resource__c.class );
            pARs1.add(par1);
        }
        try{
            insert pARs1;
        }catch(Exception e){
            error = e.getMessage();
        }
        system.assert(error!=null);
        system.assert(error.contains('No pueden asignarse las fechas seleccionadas porque no estan disponibles para'));
    }
    
    @isTest
    static void testUpdateStageToInProgressNoProfitable(){
        //Testear proyectos que no son rentables
        //Generar usuarios para asignarlos según roles, se incluyen los PMs
        List<User> listOfUser = [SELECT id, name, role__c, rate_p_hour__c from user];
        List<User> listOfPMs = new List<User>();
        List<User> listOfDevelopers = new List<User>();
        List<User> listOfConsultants = new List<User>();
        List<User> listOfArchitects = new List<User>();
        for (User u : listOfUser){
            if (u.role__c=='PM'){
                listofPMs.add(u);
            }else if (u.role__c=='Developer'){
                listOfDevelopers.add(u);
            }else if (u.role__c=='Architect'){
                listOfArchitects.add(u);
            }else if (u.role__c=='Consultant'){
                listOfConsultants.add(u);
            }
        }
        
        //Generar una lista de projects y asignarle PM y Squad Lead, insertarla
        List<Project__c> listOfProjects = TestDataFactory.createProjects(50);
        for (Project__c eachProj : listOfProjects){
            eachProj.Project_Manager__c = listofPMs[0].id;
            eachProj.Squad_Lead__c = listOfConsultants[0].id;
        }
        insert listOfProjects;
        //Generar los PLIs para cada project, insertarlos
        List<Project_Line_Item__c> listOfPLI = TestDataFactory.createPLIs(listOfProjects);
        List<Project_Assigned_Resource__c> listOfPAR = new List<Project_Assigned_Resource__c>();
        //antes de insertar los PLI se les agrega un estimated amount hardcodeado así se llena el rollup Assigned amount de project
        //crear project assigned resource por cada pli
        integer i = 0;
        for (Project_line_item__c eachPLI : listOfPLI){
            eachPLI.Estimated_Amount__c = 5000;
        }
        insert listOfPLI;
        
        //Se agregan todos los Project Assigned Resources para que cubra las horas requeridas
        for (Project_line_item__c eachPLI : listOfPLI){
            //El usuario a asignar al assigned resource debe coincidir con el del line item
        	User actualUser;
            if (eachPLI.Role__c == 'Developer'){
                actualUser=listOfDevelopers[0];
                    }else if (eachPLI.Role__c == 'Architect'){
                        actualUser=listOfArchitects[0];
                            } else if (eachPLI.Role__c == 'Consultant'){
                                actualUser=listOfConsultants[0];}
            //Crear un PAR para cada PLI con usuario del rol correspondiente
            Project_Assigned_Resource__c PAR = new Project_Assigned_Resource__c(
                name='par'+i,
                Project_Line_Item__c=eachPLI.id,
                Resource_Rate__c = 10,
                Start_Date__c = DATE.TODAY().addDays(1+i*100),
                End_Date__c = DATE.today().addDays(100+i*100),
                User__c = actualUser.Id,
                Assigned_amount__c = 1000,
                Assigned_Hour__c = eachPli.Estimated_Hours__c);
            i++;
            listOfPAR.add(PAR);
        }
        insert listOfPar;
        update listOfPLI;
        update listOfProjects;
        //Para que se actualicen los campos roll-up se debe hacer una query de project y project line item
        List<project__c> testProjects = new List<project__c>();
        List<Project_Line_Item__c> testProjLineItems = new List<Project_Line_Item__c>();
        testProjects = [SELECT Id, Assigned_amount__c, Estimated_amount__c from project__c];
        testProjLineItems = [SELECT Id, Assigned_amount__c, Estimated_amount__c from project_line_item__c];
     
        //Generar un String error que se llena en caso de que se active el trigger
        //Comenzar el test
        String error=null;
        test.startTest();
        //Se resta una cantidad grande a estimated amount de cada project a testear, asi no es rentable y pasarlo de estado in progress
        for (Project__c eachProj:testProjects){
            eachProj.Estimated_Amount__c = eachProj.Estimated_Amount__c-3000;
            eachProj.Stage__c = 'in progress';
        }
        try{
	         update testProjects;   
        }catch(Exception e){
            error=e.getMessage();
        }
        test.stopTest();
        System.assert(error!=null);
    }
    
    @isTest
    static void testUpdateProjectNoFull(){
        //Testear que el trigger se activa en caso que los proyectos no tienen todas las horas cubiertas
        //Generar usuarios para asignarlos según roles, se incluyen los PMs
        List<User> listOfUser = [SELECT id, name, role__c, rate_p_hour__c from user];
        List<User> listOfPMs = new List<User>();
        List<User> listOfDevelopers = new List<User>();
        List<User> listOfConsultants = new List<User>();
        List<User> listOfArchitects = new List<User>();
        for (User u : listOfUser){
            if (u.role__c=='PM'){
                listofPMs.add(u);
            }else if (u.role__c=='Developer'){
                listOfDevelopers.add(u);
            }else if (u.role__c=='Architect'){
                listOfArchitects.add(u);
            }else if (u.role__c=='Consultant'){
                listOfConsultants.add(u);
            }
        }
        
        //Generar una lista de projects con un PM y Squad Lead, insertarla
        List<Project__c> listOfProjects = TestDataFactory.createProjects(50);
        for (Project__c eachProj : listOfProjects){
            eachProj.Project_Manager__c = listofPMs[0].id;
            eachProj.Squad_Lead__c = listOfConsultants[0].id;
        }
        insert listOfProjects;
        //Generar los PLIs para cada project
        List<Project_Line_Item__c> listOfPLI = TestDataFactory.createPLIs(listOfProjects);
        List<Project_Assigned_Resource__c> listOfPAR = new List<Project_Assigned_Resource__c>();
        //antes de insertar los PLI se les agrega un estimated amount hardcodeado así se llena el rollup Assigned amount de project
        for (Project_line_item__c eachPLI : listOfPLI){
            eachPLI.Estimated_Amount__c = 5000;
        }
        insert listOfPLI;
        //crear project assigned resource por cada pli
        integer i = 0;
        for (Project_line_item__c eachPLI : listOfPLI){
            //El usuario a asignar al assigned resource debe coincidir con el del line item
        	User actualUser;
            if (eachPLI.Role__c == 'Developer'){
                actualUser=listOfDevelopers[0];
                    }else if (eachPLI.Role__c == 'Architect'){
                        actualUser=listOfArchitects[0];
                            } else if (eachPLI.Role__c == 'Consultant'){
                                actualUser=listOfConsultants[0];}
            //Crear un Project Assigned Resource para cada Project Line Item con un usuario del rol correspondiente
            Project_Assigned_Resource__c PAR = new Project_Assigned_Resource__c(
                name='par'+i,
                Project_Line_Item__c=eachPLI.id,
                Resource_Rate__c = 10,
                Start_Date__c = DATE.TODAY().addDays(1+i*100),
                End_Date__c = DATE.today().addDays(100+i*100),
                User__c = actualUser.Id,
                Assigned_amount__c = 1000,
                Assigned_Hour__c = eachPli.Estimated_Hours__c);
            i++;
            listOfPAR.add(PAR);
            //Sumar una hora al Estimated Hour de cada Project Line Item para que sea diferente al del Project Assigned Resource
            eachPli.Estimated_Hours__c=eachPli.Estimated_Hours__c+1;
        }
        insert listOfPar;
        update listOfPLI;
        update listOfProjects;
        //Para que se actualicen los campos roll-up se debe hacer una query de project y project line item
        List<project__c> testProjects = new List<project__c>();
        List<Project_Line_Item__c> testProjLineItems = new List<Project_Line_Item__c>();
        testProjects = [SELECT Id, Assigned_amount__c, Estimated_amount__c from project__c];
        testProjLineItems = [SELECT Id, Assigned_Hours__c, Estimated_Hours__c from project_line_item__c];
        
        //Generar un String error que se llena en caso de que se active el trigger
        //Comenzar el test cambiando el estado de los proyectos
        String error=null;
        test.startTest();
        for (Project__c eachProj:testProjects){
            eachProj.Stage__c = 'in progress';
        }
        try{
	         update testProjects;   
        }catch(Exception e){
            error=e.getMessage();
        }
        test.stopTest();
        System.assert(error!=null);
    }
    
}
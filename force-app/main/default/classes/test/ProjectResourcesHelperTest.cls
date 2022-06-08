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
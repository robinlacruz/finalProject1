@isTest
public with sharing class ProjectResourcesHelperTest{

    @isTest
    public static void getResourcesByRoleAndDateTest() {
    List<User> listUsers = TestDataFactory.createUsers();
       Map<String,Integer> nOfResourcesByRol = TestDataFactory.createPAR(listUsers);
       Date startDate = Date.Today().addDays(32);
       Date endDate = startDate.addDays(1000);

      system.assertEquals(nOfResourcesByRol.get('Developer'), ProjectResourcesHelper.getResourcesByRoleAndDate('Developer', startDate, endDate).size());
      system.assertEquals(nOfResourcesByRol.get('Consultant'), ProjectResourcesHelper.getResourcesByRoleAndDate('Consultant', startDate, endDate).size());
      system.assertEquals(nOfResourcesByRol.get('Architect'), ProjectResourcesHelper.getResourcesByRoleAndDate('Architect', startDate, endDate).size());
     
    /*
      Set<Id> setUdev= new  Set<Id>();
      Set<Id> setUcon = new Set<Id>();
      Set<Id> setUarch= new  Set<Id>();
      Set<Id> setUdevDB= new  Set<Id>();
      Set<Id> setUconDB = new  Set<Id>();
      Set<Id> setUarchDB= new  Set<Id>();


    for(Integer i = 0 ; i<devUserList.size();i++){
        setUdev.add(devUserList[i].id);
        setUdevDB.add(ProjectResourcesHelper.getResourcesByRoleAndDate('Developer', startDate, endDate)[i].id);
        }
    for(Integer i = 0 ; i<consUserList.size();i++){
            setUcon.add(consUserList[i].id);
            setUconDB.add(ProjectResourcesHelper.getResourcesByRoleAndDate('Consultant', startDate, endDate)[i].id);
     }
     for(Integer i = 0 ; i<archUserList.size();i++){
        setUarch.add(archUserList[i].id);
        setUarchDB.add(ProjectResourcesHelper.getResourcesByRoleAndDate('Architect', startDate, endDate)[i].id);
        }

      system.assertEquals(setUdev, setUdevDB);
      system.assertEquals(setUcon, setUconDB);
      system.assertEquals(setUarch, setUarchDB);


*/
    }
}
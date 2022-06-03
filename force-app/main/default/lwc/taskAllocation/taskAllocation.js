import { LightningElement, api,wire,track} from 'lwc';
import getProjectAndPLIs from '@salesforce/apex/ProjectResourcesHelper.getProjectAndPLIs';
import getResourcesByRole from '@salesforce/apex/ProjectResourcesHelper.getResourcesByRole';
import getPARByUserAndDates from '@salesforce/apex/ProjectResourcesHelper.getPARByUserAndDates';
import insertTask from '@salesforce/apex/ProjectResourcesHelper.insertTask';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TaskAllocation extends LightningElement {
    @api recordId
    project;
    optionsRole = [];
    optionsResources = [];
    projectLineItems;
    selectedRole = 'Architect';
    selectedResource = null;
    selectedResourceId;

    optionsResourcesFlag = true;
    fields  = {summary: '',description: '', startDate : null,endDate : null, nOfHours : 0 , projectId : null, resourceId : this.selectedResource , role : this.selectedRole};

    @wire (getProjectAndPLIs,{projectId:'$recordId'})
    receivedProject(result){
        const {data,error} = result;
        if(data){
            this.project = data;
            this.fields.projectId = this.project.Id;
            this.projectLineItems = data.Project_Line_Items__r;
            this.optionsRole = data.Project_Line_Items__r.map(element =>{
                return {label: element.Role__c , value: element.Role__c};
            });
            
        } else if(error){
            console.log('There was an error receiving projects', error);
        } else {
            console.log('project is undefined');
        }
    }
  
    @wire (getResourcesByRole, {role : '$selectedRole'})
    receivedResources(result){
        const {data,error} = result;

        if(data){
                 this.optionsResources = data.map(element=>{
          
                    return {label : element.Name, value:element.Id}
                })
                console.log(data);
        }
        else if(error){
            console.log('There was an error fetching resources', error);
        } else {
            console.log('getResourcesByRole no data');
        }
    }
   
// Fecha inicio / fin  -- resource ID -- 

    handleFieldsChange(evt){
        const name = JSON.parse(JSON.stringify(evt.target.name));
        const value = JSON.parse(JSON.stringify(evt.target.value));
         if(name == 'summary')    this.fields.summary = value;
         if(name == 'description')this.fields.description = value;
         if(name == 'startDate')  this.fields.startDate = value;
         if(name == 'endDate')    this.fields.endDate = value;
         if(name == 'nOfHours')   this.fields.nOfHours = value;
         if(name == 'role')       this.selectedRole = value;
 
         if(name =='resource') {
             this.fields.resourceId = value;
         }
         
     
     }
     handleCreateTask(evt){
        let par = null;
        getPARByUserAndDates({userId : this.fields.resourceId ,startDate : this.fields.startDate, endDate : this.fields.endDate}).then(data=>{
                par = data;
                console.log(data);
                if(true){
                    const {summary,startDate,endDate,description,nOfHours} = this.fields;
                    console.log('asdasd');
                    console.log('this fields : ');
                    console.log(this.fields);

                    console.log('campos');
                    console.log(summary,startDate,endDate,description,nOfHours);
                  let task = {
                        Subject__c:summary,
                        Status__c:'Not started',
                        Start_Date__c:startDate,
                        End_Date__c:endDate,
                        Name : par.User__r.Name,
                        Project_Assigned_Resource__c : par.id,
                        Priority__c : 'Normal', // Crear campo
                        Description__c : description,
                        Allocated_Hours__c:nOfHours 
                    }


                    console.log('task');
                    console.log(task);
                }

                insertTask({task: task}).then(data=>{
                    this.showErrorToast('Success','Task succesfully inserted','success');
        
        
                }).catch(error=>{
                    this.showErrorToast('Error',error.body.message,'error');
                })
        })
        .catch(error=>{
            this.showErrorToast('Error',error.body.message,'error');
        })

      


      
            
        
    }
        

  


}
        // this.fields[property] = property == 'summary' ?
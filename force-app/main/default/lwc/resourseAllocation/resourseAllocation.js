import { LightningElement, wire, api } from 'lwc';
import getProjectAndPLIs from '@salesforce/apex/ProjectResourcesHelper.getProjectAndPLIs';
import getResourcesById from '@salesforce/apex/ProjectResourcesHelper.getResourcesById';

export default class ResourseAllocation extends LightningElement {
    project;
    @api recordId;
    resourcesById;

    @wire (getProjectAndPLIs,{projectId:'$recordId'})
    receivedProject(result){
        console.log('cambio recordId');
        const {data,error} = result;
        if(data){
            this.project = data;
            console.log('recibimos projects: ',data);
            getResourcesById({startDate:this.project.Start_Date__c,endDate:this.project.End_Date__c})
            .then(result=>{
                this.resourcesById = result; 
                console.log('resources by id ->',this.resourcesById);  
                }
            ).catch(error=>{
                console.log('Hubo error recibiendo resourcesById', error);
            })

        } else if(error){
            console.log('Hubo error recibiendo projects', error);
        } else {
            console.log('project llego undefined');
        }
    }

}
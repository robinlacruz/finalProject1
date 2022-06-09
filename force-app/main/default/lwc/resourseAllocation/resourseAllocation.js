import { LightningElement, wire, api } from 'lwc';
import getProjectAndPLIs from '@salesforce/apex/ProjectResourcesHelper.getProjectAndPLIs';

export default class ResourseAllocation extends LightningElement {
    project;
    @api recordId;
    resourcesById;
// connected Callback ? 
    @wire (getProjectAndPLIs,{projectId:'$recordId'})
    receivedProject(result){
        const {data,error} = result;
        if(data){
            this.project = data;

        } else if(error){
            console.log('Hubo error recibiendo projects', error);
        } else {
            console.log('project llego undefined');
        }
    }

}
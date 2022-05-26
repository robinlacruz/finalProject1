import { LightningElement, wire, api } from 'lwc';
import getProjectAndPLIs from '@salesforce/apex/ProjectAndResources.getProjectAndPLIs';

export default class ResourseAllocation extends LightningElement {
    project;
    @api recordId;

    @wire (getProjectAndPLIs,{projectId:'$recordId'})
    receivedProject(result){
        console.log('cambio recordId');
        const {data,error} = result;
        if(data){
            this.project = data;
            console.log('recibimos projects: ',data);
        } else if(error){
            console.log('Hubo error recibiendo projects', error);
        } else {
            console.log('project llego undefined');
        }
    }
}
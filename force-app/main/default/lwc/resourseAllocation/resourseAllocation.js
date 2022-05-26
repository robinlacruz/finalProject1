import { LightningElement, wire, api } from 'lwc';
import getProjectAndPLIs from '@salesforce/apex/ProjectAndResources.getProjectAndPLIs';

export default class ResourseAllocation extends LightningElement {
    project;
    recordId;
    
    @wire (getProjectAndPLIs,{projectId:'$recordId'})
    receivedProject(result){
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

    connectedCallback(){
        this.recordId='a038a00000P1efQAAR';
        console.log('recordId es -> ',this.recordId);
    }
}
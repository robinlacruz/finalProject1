import { LightningElement, wire } from 'lwc';
import getProjects from '@salesforce/apex/ProjectAndResources.getProjects';
import getResourcesByRole from '@salesforce/apex/ProjectAndResources.getResourcesByRole';
import getProjectLineItems from '@salesforce/apex/ProjectAndResources.getProjectLineItems';
import getProjectAssignedResources from '@salesforce/apex/ProjectAndResources.getProjectAssignedResources';

export default class ResourseAllocation extends LightningElement {
    project;
    resourcesByRole;
    projectLineItems;
    projectId;
    value=[];

    
    @wire (getProjects)
    receivedProjects(result){
        const {data,error} = result;
        this.project=null;
        if(data){
            if(data.length>0) this.project=data[0];
            this.projectId=this.project.Id;
            console.log('recibimos projects: ',data);
        } else if(error){
            console.log('Hubo error recibiendo projects', error);
        } else {
            console.log('project llego undefined');
        }
    }

    @wire (getProjectLineItems,{projectId:'$projectId'})
    receivedProjectLineItems(result){
        const {data, error}=result;
        if(data){
            let receivedPLIs = data;
            let PLIarray=[];
            console.log('antes del for de projectLineItems',data);
            for(let i=0;i<receivedPLIs.length;i++){
                let {Id, Name, Role__c, Estimated_Hours__c}  = receivedPLIs[i];
                console.log('Id->'+Id+' Name->'+Name+' Role__c->'+Role__c+' Estimated_Hours__c'+Estimated_Hours__c);
                let resources = this.getResource(receivedPLIs[i].Role__c);
                let checkboxResources = [];
                checkboxResources = resources.map(element=>{
                    return {label:element.Name,value:{resourceId:element.Id,PLIId:receivedPLIs[i].Id}}
                });
                console.log('Resources->'+JSON.stringify(resources));
                PLIarray[i] = {Id:Id,Name:Name,Role__c:Role__c,Estimated_Hours__c:Estimated_Hours__c,Resources:checkboxResources};
            }
            this.projectLineItems=PLIarray;
            console.log('projectLineItems: ',this.projectLineItems);
            
        } else if(error){
            console.log('Hubo error recibiendo projectLineItems', error);
        }
    }

    @wire (getResourcesByRole)
    receivedResources(result){
        const {data,error} = result;
        if(data){
            this.resourcesByRole=data;
            console.log('recibimos resourcesByRole: ',data);
        } else if(error){
            console.log('Hubo error recibiendo resourcesByRole', error);
        }
    }

    getResource(role){
        return this.resourcesByRole[role];
    }
    
    get selectedValues() {
        return this.value?this.value.resourceId/* .join(',') */:'ninguno';
    }

    handleChange(e) {
        this.value = e.detail.value;
        console.log('evento en handleChange')
        console.log(JSON.parse(JSON.stringify(e.detail.value)));
    }
}
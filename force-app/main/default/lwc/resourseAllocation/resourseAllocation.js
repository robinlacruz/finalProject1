import { LightningElement, wire } from 'lwc';
import getProjects from '@salesforce/apex/ProjectAndResources.getProjects';
import getResourcesByRole from '@salesforce/apex/ProjectAndResources.getResourcesByRole';
import getProjectLineItems from '@salesforce/apex/ProjectAndResources.getProjectLineItems';
import getProjectAssignedResources from '@salesforce/apex/ProjectAndResources.getProjectAssignedResources';
import getResourcesById from '@salesforce/apex/ProjectAndResources.getResourcesById';

const columns = [
    { label: 'Resource Name', fieldName: 'resourceName', editable: false },
    { label: 'Role', fieldName: 'resourceRole', type: 'picklist', editable: false },
    { label: 'Rate', fieldName: 'resourceRate', type: 'currency', editable: false },
    { label: 'Start Date', fieldName: 'startDate', type: 'date-local', editable: true },
    { label: 'End Date', fieldName: 'endDate', type: 'date-local', editable: true },
];

export default class ResourseAllocation extends LightningElement {
    project;
    resourcesByRole;
    projectLineItems;
    projectId;
    columns=columns;
    rowOffset = 0;
    resourcesById;
    projectLineItemsByRole;

    
    @wire (getProjects)
    receivedProjects(result){
        const {data,error} = result;
        this.project=null;
        if(data){
            if(data.length>0) this.project = data[0];
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
            //console.log('antes del for de projectLineItems',data);
            for(let i=0;i<receivedPLIs.length;i++){
                let {Id, Name, Role__c, Estimated_Hours__c}  = receivedPLIs[i];

                let resources = this.getResource(receivedPLIs[i].Role__c);
                console.log('Resources->'+JSON.stringify(resources));
                let data1 = [];
                resources.forEach(element => {
                    data1.push({resourceId:element.Id,resourceName:element.Name,resourceRate:element.Rate_p_hour__c,startDate:null,endDate:null,pliId:receivedPLIs[i].Id,resourceRole:element.Role__c});
                });

                PLIarray[i] = {Id:Id,Name:Name,Role__c:Role__c,Estimated_Hours__c:Estimated_Hours__c,data1:data1};
            }
            this.projectLineItems=PLIarray;
            this.projectLineItemsByRole= new Map(this.projectLineItems.map(elemento=>{
                return [elemento.Role__c, elemento];
            }));
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
            //console.log('recibimos resourcesByRole: ',data);

        } else if(error){
            console.log('Hubo error recibiendo resourcesByRole', error);
        }
    }

    @wire (getResourcesById)
    receivedRescs(result){
        const {data,error} = result;
        if(data){
            this.resourcesById=data;
            //console.log('recibimos resourcesById: ',data);

        } else if(error){
            console.log('Hubo error recibiendo resourcesByRole', error);
        }
    }

    getResource(role){
        return this.resourcesByRole[role];
    }
    
    get selectedValues() {
        return 'Por ahora nada';
    }

    handleSave(data) {
        
        //console.log('los draftValues son:');
        //console.log(JSON.parse(JSON.stringify(data.detail.draftValues)));
        let editedRecords = data.detail.draftValues;
        let pliToInsert=[];
        editedRecords.forEach(element => {
            let user = this.resourcesById[element.resourceId];
            let pli = this.projectLineItemsByRole.get(user.Role__c);
            let businessDays = getBusinessDatesCount(new Date(element.startDate), new Date(element.endDate))
            let assignedHours = 8*businessDays;
            //console.log('assignedHours -> ',assignedHours);
            let projAssignResource = {Name:`ProjAssRes${user.Name}`, User__c:user.Id,Start_Date__c:element.startDate,End_Date__c:element.endDate ,Project_Line_Item__c:pli.Id ,Assigned_Hour__c:assignedHours};
            pliToInsert.push(projAssignResource);

        }); 
        console.log(pliToInsert); 

        function getBusinessDatesCount(startDate, endDate) {
            let count = 0;
            const curDate = new Date(startDate.getTime());
            while (curDate <= endDate) {
                const dayOfWeek = curDate.getDay();
                if(dayOfWeek !== 0 && dayOfWeek !== 6) count++;
                curDate.setDate(curDate.getDate() + 1);
            }
            return count;
        }
    }

    handleCancel(data) {
        console.log('los draftValues son:');
        console.log(JSON.parse(JSON.stringify(data.detail)));
    }


}
import { LightningElement,api,wire } from 'lwc';
import insertPARs from '@salesforce/apex/ProjectAndResources.insertPARs';
import getResourcesById from '@salesforce/apex/ProjectAndResources.getResourcesById';
import getProjectLineItem from '@salesforce/apex/ProjectAndResources.getProjectLineItem';
import getResourcesByRole from '@salesforce/apex/ProjectAndResources.getResourcesByRole';
import {refreshApex} from'@salesforce/apex';

const columns = [
    { label: 'Resource Name', fieldName: 'resourceName', editable: false },
    { label: 'Role', fieldName: 'resourceRole', type: 'picklist', editable: false },
    { label: 'Rate', fieldName: 'resourceRate', type: 'currency', editable: false },
    { label: 'Start Date', fieldName: 'startDate', type: 'date-local', editable: true },
    { label: 'End Date', fieldName: 'endDate', type: 'date-local', editable: true },
];
export default class ProjectLineItem extends LightningElement {
    @api pliId;
    columns=columns;
    rowOffset = 0;
    resourcesById;
    draftValues=[];
    projectLineItem;
    changedFlag;
    pliResources;
    resources;


    @wire (getResourcesById)
    receivedRescs(result){
        console.log('dentro del LWC PLI, pliId es: ',this.pliId);
        const {data,error} = result;
        if(data){
            this.resourcesById=data;
            //console.log('recibimos resourcesById: ',data);

        } else if(error){
            console.log('Hubo error recibiendo resourcesByRole', error);
        }
    }

    @wire (getProjectLineItem,{pliId:'$pliId'})
    receivedProjectLineItem(result){
        //console.log('Dentro de getProjectLineItem, pliId es ->',this.pliId);
        
        this.changedFlag=result;
        const {data, error}=result;
        if(data){
            console.log('Dentro de getProjectLineItem, data es ->',data);
            this.projectLineItem=data;
            if(this.projectLineItem) this.getResources(this.projectLineItem.Role__c);          
        } else if(error){
            console.log('Hubo error recibiendo projectLineItem ->', error);
        }
    }

    getResources(role){
        getResourcesByRole({role:role}).then(data=>{
            let resources = data;
            console.log('dentro de getResources, data es ->',data);
            let data1 = [];
            resources.forEach(element => {
                data1.push({resourceId:element.Id,resourceName:element.Name,resourceRate:element.Rate_p_hour__c,startDate:null,endDate:null,pliId:this.pliId,resourceRole:element.Role__c});
            });
            this.resources = data1;
            console.log('resources es -> ',this.resources);
        }).catch(error=>{
            console.log('Hubo error recibiendo pliResources', error);
        })
    }

    async refresh() {
        await refreshApex(this.changedFlag);
        this.draftValues=[];
    }

    handleSave(data) {
        console.log('los draftValues que llegan a handleSave son ->',JSON.parse(JSON.stringify(data.detail.draftValues)));
        let editedRecords = data.detail.draftValues;
        let parsToInsert=[];
        editedRecords.forEach(element => {
            let user = this.resourcesById[element.resourceId];
            /* let businessDays = getBusinessDatesCount(new Date(element.startDate), new Date(element.endDate))
            let assignedHours = 8*businessDays; */
            //console.log('assignedHours -> ',assignedHours);
            let projAssignResource = {Name:`ProjAssRes${user.Name}`, User__c:user.Id,Start_Date__c:element.startDate,End_Date__c:element.endDate ,Project_Line_Item__c:this.projectLineItem.Id /* ,Assigned_Hour__c:parseInt(assignedHours) */};
            parsToInsert.push(projAssignResource);

        }); 
        console.log('this.draftValues es -> ',JSON.parse(JSON.stringify(this.draftValues)));
        console.log('PAsResToInsert -> ',parsToInsert); 
        insertPARs({PARsList: parsToInsert}).then(data=>{
            this.refresh();
        }).catch(error=>{
            console.log('ERROR ->',error);
        })
        
        /* function getBusinessDatesCount(startDate, endDate) {
            let count = 0;
            const curDate = new Date(startDate.getTime());
            while (curDate <= endDate) {
                const dayOfWeek = curDate.getDay();
                if(dayOfWeek !== 5 && dayOfWeek !== 6) count++;
                curDate.setDate(curDate.getDate() + 1);
            }
            return count;
        } */
    }

    handleCellChange(data){
        //console.log('data que llega a handleCellChange ->',JSON.parse(JSON.stringify(data.detail.draftValues)));
        console.log('dentro de handleCellChange, draftValues q trae -> ',JSON.parse(JSON.stringify(data.detail.draftValues)));
        this.draftValues.push(data.detail.draftValues);
        //console.log('this.draftValues al salir de handleCellChange->',JSON.parse(JSON.stringify(this.draftValues)));
        
    }

    handleCancel(data) {
        console.log('se cancelo');
        //console.log(JSON.parse(JSON.stringify(data.detail)));
    }
}
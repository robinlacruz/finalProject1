import { LightningElement,api,wire } from 'lwc';
import insertPARs from '@salesforce/apex/ProjectResourcesHelper.insertPARs';
import getResourcesById from '@salesforce/apex/ProjectResourcesHelper.getResourcesById';
import getProjectLineItem from '@salesforce/apex/ProjectResourcesHelper.getProjectLineItem';
import getResourcesByRole from '@salesforce/apex/ProjectResourcesHelper.getResourcesByRole';
import {refreshApex} from'@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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
    assignedData= [];


    @wire(getResourcesById)
    receivedRescs(result){
        console.log('(modifiedsis)dentro del LWC PLI, pliId es: ',this.pliId);
        const {data,error} = result;
        if(data){
            this.resourcesById=data;
        } else if(error){
            console.log('Hubo error recibiendo resourcesById', error);
        }
    }

    @wire (getProjectLineItem,{pliId:'$pliId'})
    receivedProjectLineItem(result){
        this.changedFlag=result;
        const {data, error}=result;
        if(data){
            this.projectLineItem=data;
            if(this.projectLineItem) 
                this.getResources(this.projectLineItem.Role__c);          
        } else if(error){
            console.log('Hubo error recibiendo projectLineItem ->', error);
        }
    }
    getResources(role){
        getResourcesByRole({role:role}).then(data=>{
            this.resources = data.map(element => {
                return {
                        resourceId:element.Id,
                        resourceName:element.Name,
                        resourceRate:element.Rate_p_hour__c,
                        startDate:null,
                        endDate:null,
                        pliId:this.pliId,
                        resourceRole:element.Role__c
                        }
                }
            ); 
        }).catch(error=>{
            console.log('Hubo error recibiendo pliResources', error);
        })
    }
    
    async refresh() {
        await refreshApex(this.changedFlag);
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 500);
        this.draftValues=[];
    }

    handleSave(data) {
        const parsToInsert= data.detail.draftValues.map(element => {
            let user = this.resourcesById[element.resourceId];
            let assignedHours = 8 * getBusinessDatesCount(new Date(element.startDate), new Date(element.endDate));
            return {
                Name:`ProjAssRes${user.Name}`, 
                User__c:user.Id,
                Start_Date__c:element.startDate,
                End_Date__c:element.endDate,
                Project_Line_Item__c:this.projectLineItem.Id,
                Assigned_Hour__c:parseInt(assignedHours),
                Assigned_Amount__c:assignedHours * user.Rate_p_hour__c,
                Resource_Rate__c:user.Rate_p_hour__c };
            
        }); 
        insertPARs({resources: parsToInsert})
        .then(data=>{
            console.log(data);
            this.refresh();})
        .catch(error=>{
            this.showErrorToast('Error de Insercion',error.body.message,'error'); }) ;

    }

    handleCellChange(data){
        this.draftValues.push(data.detail.draftValues); 
    }

    showErrorToast(title,message,variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

   
}
const getBusinessDatesCount = (startDate, endDate)=>{
    let count = 0;
    const curDate = new Date(startDate.getTime());
    while (curDate <= endDate) {
        const dayOfWeek = curDate.getDay();
        if(dayOfWeek !== 5 && dayOfWeek !== 6) count++;
        curDate.setDate(curDate.getDate() + 1);
    }
    return count;
}
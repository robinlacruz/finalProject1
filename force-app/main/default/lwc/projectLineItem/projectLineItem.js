import { LightningElement,api,wire } from 'lwc';
import insertPARs from '@salesforce/apex/ProjectResourcesHelper.insertPARs';
import getResourcesByIdMap from '@salesforce/apex/ProjectResourcesHelper.getResourcesByIdMap';
import getProjectLineItem from '@salesforce/apex/ProjectResourcesHelper.getProjectLineItem';
import getResourcesByRole from '@salesforce/apex/ProjectResourcesHelper.getResourcesByRole';
import getResourcesByRoleAndDate from '@salesforce/apex/ProjectResourcesHelper.getResourcesByRoleAndDate';
import {refreshApex} from'@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Resource Name', fieldName: 'resourceName', editable: false },
    { label: 'Role', fieldName: 'resourceRole', type: 'picklist', editable: false },
    { label: 'Rate', fieldName: 'resourceRate', type: 'currency', editable: false },
    { label: 'Start Date', fieldName: 'startDate', type: 'date-local', editable: true},
    { label: 'End Date', fieldName: 'endDate', type: 'date-local', editable: true},
];
export default class ProjectLineItem extends LightningElement {
    @api pliId;
    @api projectStartDate;
    @api projectEndDate;
    columns=columns;
    rowOffset = 0;
    resourcesById;
    draftValues=[];
    projectLineItem;
    changedFlag;
    pliResources;
    resources;
    startDateFilter;
    endDateFilter;
    

    @wire (getProjectLineItem,{pliId:'$pliId'})
    receivedProjectLineItem(result){    
        this.changedFlag=result;
        const {data, error}=result;
        if(data){
            this.projectLineItem=data;
            if(this.projectLineItem) this.getResources(this.projectLineItem.Role__c);          
        } else if(error){
            console.log('Hubo error recibiendo projectLineItem ->', error);
        }
    }

    getResources(role){
        getResourcesByRole({role:role/*  ,startDate:this.startDateFilter,endDate:this.endDateFilter */}).then(data=>{
            let resources = data;
            let data1 = [];
            resources.forEach(element => {
                data1.push({resourceId:element.Id,resourceName:element.Name,resourceRate:element.Rate_p_hour__c,startDate:null,endDate:null,pliId:this.pliId,resourceRole:element.Role__c});
            });
            this.resources = data1;
            getResourcesByIdMap({resources:resources}).then(data2=>{
                console.log('resourcesByIdMap ->',data2);
                this.resourcesById=data2;
            }).catch(error=>{
                console.log('Hubo error en la funcion getResourcesByIdMap ',error);
            })
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
        this.startDateFilter = null;
        this.endDateFilter = null;

    }

    handleSave(data) {
        this.draftValues = data.detail.draftValues;
        const parsToInsert= data.detail.draftValues.map(element => {
            let user = this.resourcesById[element.resourceId];
            let assignedHours = 8 * getBusinessDatesCount(new Date(element.startDate), new Date(element.endDate));
            let assignedAmount = user.Rate_p_hour__c*assignedHours;
            return {
                Name:`ProjAssRes${user.Name}`, 
                User__c:user.Id,
                Start_Date__c:element.startDate,
                End_Date__c:element.endDate,
                Project_Line_Item__c:this.projectLineItem.Id,
                Assigned_Hour__c:parseInt(assignedHours),
                Assigned_Amount__c:assignedAmount,
                Resource_Rate__c:user.Rate_p_hour__c };
        }); 

        insertPARs({resources: parsToInsert}).then(data=>{
            this.refresh();
        }).catch(error=>{
            this.showErrorToast('Error de Insercion',error.body.message,'error');
        })
        
        function getBusinessDatesCount(startDate, endDate) {
            let count = 0;
            const curDate = new Date(startDate.getTime());
            while (curDate <= endDate) {
                const dayOfWeek = curDate.getDay();
                if(dayOfWeek !== 5 && dayOfWeek !== 6) count++;
                curDate.setDate(curDate.getDate() + 1);
            }
            return count;
        }
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

    handleChange(event){
        if(event.target.name == 'startDateFilter'){
            this.startDateFilter=event.target.value;
        }else if(event.target.name == 'endDateFilter'){
            this.endDateFilter=event.target.value;
        }
    }

    handleFilter(){
        if(this.startDateFilter && this.endDateFilter){
            if(this.projectLineItem){
                getResourcesByRoleAndDate({role:this.projectLineItem.Role__c ,startDate:this.startDateFilter,endDate:this.endDateFilter}).then(data=>{
                    let resources = data;
                    let data1 = [];
                    resources.forEach(element => {
                        data1.push({resourceId:element.Id,resourceName:element.Name,resourceRate:element.Rate_p_hour__c,startDate:null,endDate:null,pliId:this.pliId,resourceRole:element.Role__c});
                    });
                    this.resources = data1;
                    console.log('recursos filtrados: ',this.resources);

                }).catch(error=>{
                    console.log('Hubo error recibiendo pliResources', error);
                })
            } else {console.log('No existe this.projectLineItem: ',this.projectLineItem)}
        } else {
            console.log('Se deben seleccionar ambas fechas para filtrar');
        }
    }

}
import { LightningElement, api, wire, track } from "lwc";
import getProjectAndPLIs from "@salesforce/apex/ProjectResourcesHelper.getProjectAndPLIs";
import getResourcesByRole from "@salesforce/apex/ProjectResourcesHelper.getResourcesByRole";
import getPARByUserAndDates from "@salesforce/apex/ProjectResourcesHelper.getPARByUserAndDates";
import insertTask from "@salesforce/apex/ProjectResourcesHelper.insertTask";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class TaskAllocation extends LightningElement {
  @api recordId;
  project;
  optionsRole = [];
  optionsResources = [];
  projectLineItems;
  selectedRole = "";
  selectedResource = null;
  selectedResourceId;

  optionsResourcesFlag = true;
  fields = {
    summary: "",
    description: "",
    startDate: null,
    endDate: null,
    nOfHours: 0,
    projectId: null,
    resourceId: this.selectedResource,
    role: this.selectedRole
  };

  @wire(getProjectAndPLIs, { projectId: "$recordId" })
  receivedProject(result) {
    //console.log(JSON.parse(JSON.stringify(result)));
    const { data, error } = result;
    if (data) {
      this.project = data;
      this.fields.projectId = this.project.Id;
      this.projectLineItems = data.Project_Line_Items__r;
      this.optionsRole = data.Project_Line_Items__r.map((element) => {
        return { label: element.Role__c, value: element.Role__c };
      });
    } else if (error) {
      console.log("There was an error receiving projects", error);
    } else {
      console.log("project is undefined");
    }
  }

  @wire(getResourcesByRole, { role: "$selectedRole" })
  receivedResources(result) {
    const { data, error } = result;

    if (data) {
      this.optionsResources = data.map((element) => {
        return { label: element.Name, value: element.Id };
      });
      console.log(data);
    } else if (error) {
      console.log("There was an error fetching resources", error);
    } else {
      console.log("getResourcesByRole no data");
    }
  }

  // Fecha inicio / fin  -- resource ID --

  handleFieldsChange(evt) {
    const name = JSON.parse(JSON.stringify(evt.target.name));
    const value = JSON.parse(JSON.stringify(evt.target.value));
    if (name == "summary") this.fields.summary = value;
    if (name == "description") this.fields.description = value;
    if (name == "startDate") this.fields.startDate = value;
    if (name == "endDate") this.fields.endDate = value;
    if (name == "nOfHours") this.fields.nOfHours = value;
    if (name == "role") {
      this.fields.role = value;
      this.selectedRole = value;
    }

    if (name == "resource") {
      this.fields.resourceId = value;
    }

    console.log(value);
  }

  handleCreateTask(evt) {
    console.log(this.fields);
    let par = null;
    getPARByUserAndDates({
      userId: this.fields.resourceId,
      startDate: this.fields.startDate,
      endDate: this.fields.endDate
    })
      .then((data) => {
        par = data;
        let task;
        console.log("PAR -> ", data);
        if (data) {
          const { summary, startDate, endDate, description, nOfHours } =
            this.fields;
          console.log(summary, startDate, endDate, description, nOfHours);
          task = {
            Subject__c: summary,
            Status__c: "Not started",
            Start_Date__c: startDate,
            End_Date__c: endDate,
            Name: "Martin", //par.User__r.Name,
            Project_Assigned_Resource__c: par.Id,
            Priority__c: "Normal", // Crear campo
            Description__c: description,
            Allocated_Hours__c: nOfHours,
            Registered_Hours__c: 0
          };
          console.log("task ->", task);
        }

        insertTask({ task: task })
          .then((data) => {
            this.showErrorToast(
              "Success",
              "Task succesfully inserted",
              "success"
            );
          })
          .catch((error) => {
            console.log("error de insercion de tarea");
            this.showErrorToast("Error", error.body.message, "error");
          });
      })
      .catch((error) => {
        console.log("error trayendo el PAR");
        this.showErrorToast("Error", error.body.message, "error");
      });
  }

  showErrorToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      mode: "dismissable"
    });
    this.dispatchEvent(evt);
  }
}

/*import RESOURCETASK_OBJECT from '@salesforce/schema/Resource_Task__c';
import NAME_FIELD from '@salesforce/schema/Resource_Task__c.name';
import SUBJECT_FIELD from '@salesforce/schema/Resource_Task__c.Subject__c';
import PRIORITY_FIELD from '@salesforce/schema/Resource_Task__c.Priority__c';
import STATUS_FIELD from '@salesforce/schema/Resource_Task__c.Status__c';
import STARTDATE_FIELD from '@salesforce/schema/Resource_Task__c.Start_Date__c';
import ENDATE_FIELD from '@salesforce/schema/Resource_Task__c.End_Date__c';
import PAR_FIELD from '@salesforce/schema/Resource_Task__c.Project_Assigned_Resource__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Resource_Task__c.Description__c';
import ALLOCATEDHOURS_FIELD from '@salesforce/schema/Resource_Task__c.Allocated_Hours__c'*/

/*import PRIORITY_FIELD from '@salesforce/schema/Resource_Task__c.Priority__c';
import STATUS_FIELD from '@salesforce/schema/Resource_Task__c.Status__c';
import STARTDATE_FIELD from '@salesforce/schema/Resource_Task__c.Start_Date__c';
import ENDATE_FIELD from '@salesforce/schema/Resource_Task__c.End_Date__c';
import PAR_FIELD from '@salesforce/schema/Resource_Task__c.Project_Assigned_Resource__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Resource_Task__c.Description__c';
import ALLOCATEDHOURS_FIELD from '@salesforce/schema/Resource_Task__c.Allocated_Hours__c'
     handleCreateTask() {
        const fieldsUI = {};
        fields[NAME_FIELD.fieldApiName] = this.name;
        fields[SUBJECT_FIELD.fieldApiName] = this.fields.summary
        fields[PRIORITY_FIELD.fieldApiName] = this.name;
        fields[STARTDATE_FIELD.fieldApiName] = this.name;
        fields[ENDATE_FIELD.fieldApiName] = this.name;
        fields[PAR_FIELD.fieldApiName] = this.name;
        fields[DESCRIPTION_FIELD.fieldApiName] = this.name;
        fields[ALLOCATEDHOURS_FIELD.fieldApiName] = this.name;
        const recordInput = { apiName: RESOURCETASK_OBJECT.objectApiName, fieldsUI };
        createRecord(recordInput)
            .then(account => {
                this.accountId = account.id;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Account created',
                        variant: 'success',
                    }),
                );
            })
            /* task = {
                        Subject__c:summary,
                        Status__c:'Not started',
                        Start_Date__c:startDate,
                        End_Date__c:endDate,
                        Name : 'Martin',//par.User__r.Name,
                        Project_Assigned_Resource__c : par.Id,
                        Priority__c : 'Normal', // Crear campo
                        Description__c : description,
                        Allocated_Hours__c:nOfHours 
                    }
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }

    */
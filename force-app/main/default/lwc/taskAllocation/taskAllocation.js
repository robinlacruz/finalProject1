/* eslint-disable guard-for-in */
import { LightningElement, api, wire, track } from "lwc";
import getProjectAndPLIs from "@salesforce/apex/ProjectResourcesHelper.getProjectAndPLIs";
import getPARByUserAndDates from "@salesforce/apex/ProjectResourcesHelper.getPARByUserAndDates";
import getProjectsOfCurrentUser from "@salesforce/apex/ProjectResourcesHelper.getProjectsOfCurrentUser";
import insertTask from "@salesforce/apex/ProjectResourcesHelper.insertTask";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getResourcesByRoleAndProject from "@salesforce/apex/ProjectResourcesHelper.getResourcesByRoleAndProject";

export default class TaskAllocation extends LightningElement {
  @api recordId;
  project;
  optionsRole = [];
  optionsResources = [];
  optionsProject = [];
  projectLineItems;
  selectedRole = "";
  selectedResource = null;
  selectedResourceId;
  selectedProject;
  selectedPriority = "";
  optionsPriority = [
    { label: "High", value: "High" },
    { label: "Normal", value: "Normal" },
    { label: "Low", value: "Low" }
  ];

  optionsResourcesFlag = true;
  @track fields = {
    summary: "",
    description: "",
    startDate: null,
    endDate: null,
    nOfHours: 0,
    projectId: null,
    resourceId: this.selectedResource,
    role: "Architect",
    priority: this.priority
  };

  @wire(getProjectsOfCurrentUser,{})
  receiveSLProjects(result) {
    const { data, error } = result;
    if (data) {
      this.optionsProject = data.map((element) => {
        return { label: element.Name, value: element.Id };
      });
  
     this.fields.projectId = data[0].Id;
    } else if (error) {
      console.log("There was an error receiving projects of squad lead", error);
    } else {
      console.log("project is undefined");
    }
  }

  @wire(getProjectAndPLIs, { projectId: "$fields.projectId" })
  receivedProject(result) {
    const { data, error } = result;
    if (data) {
      this.fields.projectId = data.Id;
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

  @wire(getResourcesByRoleAndProject, { role: "$fields.role", projectId:"$fields.projectId" })
  receivedResources(result) {
    const { data, error } = result;
    if (data) {
      this.optionsResources = data.map((element) => {
        return { label: element.Name, value: element.Id };
      });
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
    if (name === "summary") this.fields.summary = value;
    if (name === "description") this.fields.description = value;
    if (name === "startDate") this.fields.startDate = value;
    if (name === "endDate") this.fields.endDate = value;
    if (name === "nOfHours") this.fields.nOfHours = value;
    if (name === "priority") this.fields.priority = value;
    if (name === "project") this.fields.projectId = value;
    if (name === "role") {
      this.fields.role = value;
    }
    if (name === "resource") {
      this.fields.resourceId = value;
    }

    console.log(JSON.stringify(this.fields));
  }

  handleCreateTask() {
    let par = null;
    getPARByUserAndDates({
      userId: this.fields.resourceId,
      startDate: this.fields.startDate,
      endDate: this.fields.endDate,
      projectId: this.recordId
    })
      .then((data) => {
        par = data;
        let task;
          const {summary,startDate,endDate,description,nOfHours,priority} = this.fields;
          task = {
            Subject__c: summary,
            Status__c: "Not started",
            Start_Date__c: startDate,
            End_Date__c: endDate,
            Name: par.User__r.Name,
            Project_Assigned_Resource__c: par.Id,
            Priority__c: priority,
            Description__c: description,
            Allocated_Hours__c: nOfHours,
            Registered_Hours__c: 0
          };

          console.log(task);
          console.log("task arriba");
        

        insertTask({ task: task })
          .then(() => {
            this.fields = {
              summary: "",
              description: "",
              startDate: null,
              endDate: null,
              nOfHours: 0,
              projectId: null,
              resourceId: "",
              role: "Architect",
              priority: ""
            };
            this.showErrorToast(
              "Success",
              "Task succesfully inserted",
              "success"
            );
          })
          .catch((error) => {
            this.showErrorToast("Error", error.body.message, "error");
          });
      })
      .catch((error) => {
        this.showErrorToast("Error", error.body.message, "error");
      });
  }

  handleCancelTask() {
    this.fields = {
      summary: "",
      description: "",
      startDate: null,
      endDate: null,
      nOfHours: 0,
      projectId: null,
      resourceId: "",
      role: "Architect",
      priority: ""
    };
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
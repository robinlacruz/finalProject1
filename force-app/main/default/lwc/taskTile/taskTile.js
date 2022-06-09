import { LightningElement, api,wire } from "lwc";
import updateTask from "@salesforce/apex/ProjectResourcesHelper.updateTask";


export default class TaskTile extends LightningElement {
  @api task;

  taskIsStarted = false;
  taskIsCompleted = false;
  hours = 0;
  progress= 0;

  connectedCallback() {
    this.task = JSON.parse(JSON.stringify(this.task));
    if (this.task.Status__c != "Not Started") {
      this.taskIsStarted = true;
      if (this.task.Status__c == "Completed") {
        this.taskIsCompleted = true;
      }
    } else {
      this.taskIsStarted = false;
    }
  }

  handleMarkCompleted() {
    if (this.task.Allocated_Hours__c <= this.task.Registered_Hours__c) {
      this.task.Status__c = "Completed";
      this.taskIsCompleted = true;
      console.log(this.task.Status__c);
      /*updateTask({ task: this.task })
        .then(() => {
          console.log("Task succesfully updated");
        })
        .catch((error) => {
          console.log("Error updating task ", error);
        });*/
    }
  }

  handleLoadHours() {
    this.task.Registered_Hours__c =
      parseInt(this.hours) + parseInt(this.task.Registered_Hours__c);
    this.hours = 0;
    if(this.task.Allocated_Hours__c!==0 && this.progress!==100)
      this.progress = Math.round((this.task.Registered_Hours__c / this.task.Allocated_Hours__c)*100);
      /*updateTask({ task: this.task })
      .then(() => {
        console.log("Task succesfully updated");
      }).catch((error) => {
        console.log("Error updating task ", error);
      });*/
  }

  handleInput(evt) {
    this.hours = evt.target.value;
  }

  handleStartTask() {
    this.task.Status__c = "In Progress";
    this.taskIsStarted = true;
    /*updateTask({ task: this.task })
      .then(() => {
        console.log("Task succesfully updated");
      }).catch((error) => {
        console.log("Error updating task ", error);
      });*/
    
  }


 
}
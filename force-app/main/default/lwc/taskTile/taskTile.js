import { LightningElement, api } from "lwc";
import updateTask from "@salesforce/apex/ProjectResourcesHelper.updateTask";

export default class TaskTile extends LightningElement {
  @api task;

  taskIsStarted = false;
  taskIsCompleted = false;
  hours = 0;

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
      updateTask({ task: this.task })
        .then(() => {
          console.log("Task succesfully updated");
        })
        .catch((error) => {
          console.log("Error updating task ", error);
        });
    }
  }

  handleLoadHours() {
    this.task.Registered_Hours__c =
      parseInt(this.hours) + parseInt(this.task.Registered_Hours__c);
    this.hours = 0;
    updateTask({ task: this.task })
      .then(() => {
        console.log("Task succesfully updated");
      })
      .catch((error) => {
        console.log("Error updating task ", error);
      });
  }

  handleInput(evt) {
    this.hours = evt.target.value;
  }

  handleStartTask() {
    this.task.Status__c = "In Progress";
    this.taskIsStarted = true;
  }
}

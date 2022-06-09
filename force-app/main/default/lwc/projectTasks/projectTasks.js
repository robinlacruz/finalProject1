import { LightningElement, api } from "lwc";
export default class ProjectTasks extends LightningElement {
  @api currentProjectTasks;
  /* connectedCallback(){
        this.currentProjectTasks = JSON.parse(JSON.stringify(this.currentProjectTasks));
    } */
}
/* eslint-disable guard-for-in */
import { LightningElement, api, wire } from "lwc";
import getUserTasks from "@salesforce/apex/ProjectResourcesHelper.getUserTasks";
import setSquadLead from "@salesforce/apex/ProjectResourcesHelper.setSquadLead";
export default class UserTasks extends LightningElement {
  @api recordId;
  userTasks = [];
  completedTasks = [];

  connectedCallback(){
    setSquadLead({}).then(()=>{
      console.log('squadLead Setted')
    }).catch(()=>{
      console.log('squadLead Setted')
    })
  }

  @wire(getUserTasks, {})
  receivedUserTasks(result) {
    const { data, error } = result;
    console.log(data);
    let tasksList = [];
    if (data) {
      const allTasks = [];
      for (let i in data) {
        let projectTasks = [];
        let keyP;
        for (let j in data[i]) {
          console.log(data[i][j]);
          projectTasks.push(data[i][j]);
          allTasks.push(data[i][j]);
          keyP = data[i][j].Project_Assigned_Resource__c;
        }
        tasksList.push({ project: i, tasks: projectTasks, id: keyP });
        
      }
      this.userTasks = tasksList;
      this.completedTasks = allTasks.filter((element)=>element.Status__c === 'Completed');
      this.dispatchEvent(new CustomEvent('completed',{
        detail:this.completedTasks
      }));
    } else if (error) {
      console.log(
        "There was a problem with the getUserTasks apex function, ",
        error
      );
    }
  }
  
}
import { LightningElement, api, wire } from "lwc";
import getUserTasks from "@salesforce/apex/ProjectResourcesHelper.getUserTasks";
export default class UserTasks extends LightningElement {
  @api recordId;
  userTasks = [];

  @wire(getUserTasks, {})
  receivedUserTasks(result) {
    const { data, error } = result;
    console.log(data);
    let tasksList = [];
    if (data) {
      for (let i in data) {
        let projectTasks = [];
        let keyP;
        for (let j in data[i]) {
          console.log(data[i][j]);
          projectTasks.push(data[i][j]);
          keyP = data[i][j].Project_Assigned_Resource__c;
        }
        tasksList.push({ project: i, tasks: projectTasks, id: keyP });
      }
      this.userTasks = tasksList;
      console.log(JSON.parse(JSON.stringify(this.userTasks)));
    } else if (error) {
      console.log(
        "There was a problem with the getUserTasks apex function, ",
        error
      );
    }
  }
  /* connectedCallback() {
    getUserTasks({})
      .then((data) => {
        console.log("dentro de getUserTasks", JSON.parse(JSON.stringify(data)));
        if (data) {
          for (let i in data) {
            let projectTasks = [];
            let keyP;
            for (let j in data[i]) {
              projectTasks.push(data[i][j]);
              keyP = data[i][j].Project_Assigned_Resource__c;
            }
            this.userTasks.push({ project: i, tasks: projectTasks, id: keyP });
          }
          console.log(JSON.parse(JSON.stringify(this.userTasks)));
        } else {
          console.log("No data");
        }
      })
      .catch((data) => {
        console.log("CATCH DE METODO IMPERATIVO");
      });
  } */

  /* @wire (getUserTasks)
    receivedProjectLineItem(result){
        const {data,error} = result;
        console.log(data);
    }*/
}
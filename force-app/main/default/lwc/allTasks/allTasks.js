import { LightningElement,track } from 'lwc';

export default class AllTasks extends LightningElement {
    @track completedTasks= [];
    taskList;
    handleCompleteTasks(evt){
        
        for(let i in evt.detail){
            this.completedTasks.push(evt.detail[i]);
        }
        console.log(this.completedTasks);
  
    }

}
import { LightningElement,api,track} from 'lwc';

export default class TaskTile extends LightningElement {

    @api task;
    taskIsStarted = false;
    taskIsCompleted = false;
    @track hours; 

    connectedCallback(){
        this.task= JSON.parse(JSON.stringify(this.task));
        this.hours = this.task.Registered_Hours__c;
        if(this.task.Status__c != 'Not Started' ){
            this.taskIsStarted = true;    
           }
           else{
               this.taskIsStarted = false;
           }
          
    }

    handleMarkCompleted(){
        if(this.task.Allocated_Hours__c <= this.task.Registered_Hours__c){
            this.task.Status__c = 'Completed';
            this.taskIsCompleted = true;
        }
        console.log(this.task);    

    }

    handleLoadHours(){
        this.hours = parseInt(this.hours) + parseInt(this.task.Registered_Hours__c);
        this.task.Registered_Hours__c =this.hours;
        this.hours = 0;
    }

    handleInput(evt){
        this.hours = evt.target.value;
    }

    handleStartTask(){
        this.task.Status__c = 'In Progress';
        this.taskIsStarted = true;
    }

}
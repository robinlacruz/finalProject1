import { LightningElement,api,wire,track} from 'lwc';
import getUserTasks from '@salesforce/apex/ProjectResourcesHelper.getUserTasks'
export default class UserTasks extends LightningElement {

    @api recordId;
    @track userTasks = [];
    connectedCallback(){
        getUserTasks({}).then(data=>{
            console.log(data);
                if(data){
                   for(let i in data){
                       let projectTasks = [];
                       let keyP;
                        for(let j in data[i]){
                            projectTasks.push(data[i][j]);
                            keyP = data[i][j].Project_Assigned_Resource__c;
                            
                        }
                        this.userTasks.push({project: i , tasks : projectTasks, id : keyP})
                   }
                    console.log(JSON.parse(JSON.stringify(this.userTasks)));
                }
                else{
                    console.log('No data');
                }
            

        }).catch(data=>{
            console.log('CATCH DE METODO IMPERATIVO');
        });
    }
}
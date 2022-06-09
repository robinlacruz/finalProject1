import { LightningElement,api} from 'lwc';

export default class CompletedTasks extends LightningElement {

    @api completedTasks;
    
    connectedCallback(){
    }
}
import { LightningElement, api,wire } from 'lwc';
import getPayingParentHierarchy from '@salesforce/apex/PayingParentHierarchyController.getPayingParentHierarchy'

export default class PayingParentHierarchy extends LightningElement {
    @api recordId;
    treeItems = [];
    @wire(getPayingParentHierarchy,{currentAccId:'$recordId'})
    treeArray({error, data}){
        if(data){
            this.treeItems = JSON.parse(data);
        }else if (error){
            console.log( 'Error is ' + JSON.stringify( error ) );
        }
    }
}
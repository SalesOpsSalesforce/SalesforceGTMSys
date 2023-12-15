import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLeadDetails from '@salesforce/apex/DataDeletionController.getLeadDataByEmail';

export default class DataDeletion extends LightningElement {
    @track emailAddress;
    @track leads;

    handleChange(event) {
        const email = event.target.value;
        if (email) {
            this.emailAddress = email;
        }
    }

    handleClick(event) {
        this.error = '';
        if (this.emailAddress == null && this.emailAddress == '') {
            // display error;
            this.error = 'Email address can not be empty.';
            return false;
        }
        getLeadDetails( {
            'email' : this.emailAddress
        })
        .then(result => {
            debugger;
            this.leads = result;
        })
        .catch(error => {
            this.error = error;
        });
    }

    get leadJSON () {
        if (this.leads && this.leads === 'Success') {
            const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Successfully updated!',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            //return this.leads;
        }else if(this.leads){
            const evt = new ShowToastEvent({
                title: 'Error',
                message: this.leads,
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
    }
}
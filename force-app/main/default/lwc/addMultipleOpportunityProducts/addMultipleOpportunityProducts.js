import { LightningElement, track, wire, api} from 'lwc';
import LightningConfirm from 'lightning/confirm';
import modal from "@salesforce/resourceUrl/custommodal";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getOpportunityProduct from '@salesforce/apex/UpdateOpportunityProduct.getOpportunityProduct';
import updateProduct from '@salesforce/apex/UpdateOpportunityProduct.updateProduct';
import updateAllProduct from '@salesforce/apex/UpdateOpportunityProduct.updateAllProduct';
import deleteProduct from '@salesforce/apex/UpdateOpportunityProduct.deleteProduct';
import { loadStyle } from "lightning/platformResourceLoader";
import Klaviyo_Customer_Platform_w_Email from '@salesforce/label/c.Klaviyo_Customer_Platform_w_Email'
import Klaviyo_Email from '@salesforce/label/c.Klaviyo_Email'
import Klaviyo_Customer_Platform from '@salesforce/label/c.Klaviyo_Customer_Platform'
import Opportunity_Stage from '@salesforce/label/c.Opportunity_Stage'
import Klaviyo_One from '@salesforce/label/c.Klaviyo_One'
import MPO_LWC_Lock_Down_Discount_Fields from '@salesforce/label/c.MPO_LWC_Lock_Down_Discount_Fields'

export default class AddMultipleOpportunityProducts extends LightningElement {
    label = {
        Klaviyo_Customer_Platform_w_Email,
        Klaviyo_Email,
        Klaviyo_Customer_Platform,
        Opportunity_Stage,
        Klaviyo_One,
        MPO_LWC_Lock_Down_Discount_Fields
    };
    @api recordId;
    connectedCallback() {
        setTimeout(() => {
            this.getCompleteData();
        }, 5);
        loadStyle(this, modal);
    }
    disconnectedCallback(){
        eval("$A.get('e.force:refreshView').fire();");
    }
    @track isKlaviyoEmail = false;
    @track isKlaviyoCustomerPlatform = false;
    @track paymentMethod = '';
    //columns = columns;
    @api isLoaded = false;
    showSpinner = false;
    @track copyData = [];
    @track deletedData = [];
    @track data = [];
    @track genricData;
    @track draftValues = [];
    @track columns =[];
    @track listOfItemVariables =[];
    @track mapOfProducts =[];
    @track mapOfProductsDiscount = [];
    @track mapOfProductsUsage = [];
    @track mapOfOriginalOpportunity = [];
    @track blankOLI;
    lastSavedData = [];
    @track isFooterButtonVisible = false;
    @track isOpportunityClosed = false;
    @track opportunityStage = false;
    @track mapOfProductOptyValues = [];
    @track showOpty = false;
    @track optyData = [];
    @track opportunityId;
    @track deleteRecordId = '';
    @track deleteProductId = '';
    @track isForDelete = false;
    @track showFlow = false;
    @track flowName;
    @track flowInputVariables = [];
    @track mapOfDiscount = [];
    @track mapOfDefaultUsage =[];
    @track mapOfLockedUsage =[];
    //here I pass picklist option so that this wire method call after above method
    getCompleteData(){
        let workingData = [];
        this.data = [];
        getOpportunityProduct({opportunityId : this.recordId, fieldSetName : 'OpportunityMPOFieldSet', ObjectName : 'OpportunityLineItem'})
        .then((data) =>{
            this.genricData = data;
            if (data) {
                this.columns = data.listOfFieldDetails;
                this.blankOLI = data.blankOli;
                this.listOfItemVariables = data.listOfItemVariables;
                this.isOpportunityClosed = data.isOpportunityClosed;
                this.paymentMethod = data.paymentMethod;
                this.mapOfProducts = data.mapOfProducts;
                this.opportunityStage = data.opportunityStage;
                this.mapOfProductsDiscount = data.mapOfProductsDiscount;
                this.mapOfProductOptyValues = data.mapOfProductOptyValues;
                this.mapOfProductsUsage = data.mapOfProductsUsage;
                this.opportunityId = data.opportunityId;
                this.mapOfDiscount = data.mapOfDiscount;
                this.mapOfOriginalOpportunity = data.mapOfOriginalOpportunity;
                this.mapOfDefaultUsage = data.mapOfDefaultUsage;
                this.mapOfLockedUsage = data.mapOfLockedUsage;
                for(let v in data.listOfItemVariables) {
                    let newData = [];
                    let productId;
                    for(let w in this.columns) {
                        if(this.columns[w].fieldAPI == 'Product2Id__c'){
                            productId = data.listOfItemVariables[v].oli[this.columns[w].fieldAPI];
                        }
                        if(this.columns[w].fieldAPI != 'Action'){
                            if(this.columns[w].fieldAPI != 'List_Price__c' && this.columns[w].fieldAPI != 'UnitPrice' && this.columns[w].fieldAPI != 'TotalPrice'){
                                if(data.listOfItemVariables[v].oli[this.columns[w].fieldAPI] != undefined){
                                    if(this.columns[w].fieldAPI == 'Usage_Limit__c'){
                                        newData.push({
                                            fieldAPI : this.columns[w].fieldAPI,
                                            classDetails : this.columns[w].classDetails,
                                            disabled : false,
                                            fieldValue : data.listOfItemVariables[v].oli[this.columns[w].fieldAPI],
                                            fieldType : this.columns[w].fieldType,
                                            labelValue : this.mapOfProducts[productId]
                                        });
                                    }/*else if(this.columns[w].fieldAPI == 'Discount__c'){
                                        newData.push({
                                            fieldAPI : this.columns[w].fieldAPI,
                                            classDetails : this.columns[w].classDetails,
                                            disabled : this.mapOfProductsDiscount[productId],
                                            fieldValue : data.listOfItemVariables[v].oli[this.columns[w].fieldAPI],
                                            fieldType : this.columns[w].fieldType,
                                            labelValue : ''
                                        });
                                    }*/else if(this.columns[w].fieldAPI == 'Discount_Coupon__c' || this.columns[w].fieldAPI == 'Discount__c' || this.columns[w].fieldAPI == 'Discount_Length_of_Months__c'){
                                        newData.push({
                                            fieldAPI : this.columns[w].fieldAPI,
                                            classDetails : this.columns[w].classDetails,
                                            disabled : true,
                                            fieldValue : data.listOfItemVariables[v].oli[this.columns[w].fieldAPI],
                                            fieldType : this.columns[w].fieldType,
                                            labelValue : ''
                                        });
                                    }else{
                                        newData.push({
                                            fieldAPI : this.columns[w].fieldAPI,
                                            classDetails : this.columns[w].classDetails,
                                            disabled : false,
                                            fieldValue : data.listOfItemVariables[v].oli[this.columns[w].fieldAPI],
                                            fieldType : this.columns[w].fieldType,
                                            labelValue : ''
                                        });
                                    }
                                    
                                }else{
                                    if(this.columns[w].fieldAPI == 'Usage_Limit__c'){
                                        newData.push({
                                            fieldAPI : this.columns[w].fieldAPI,
                                            classDetails : this.columns[w].classDetails,
                                            disabled : false,
                                            fieldValue : data.listOfItemVariables[v].oli[this.columns[w].fieldAPI],
                                            fieldType : this.columns[w].fieldType,
                                            labelValue : this.mapOfProducts[productId]
                                        });
                                    }/*else if(this.columns[w].fieldAPI == 'Discount__c'){
                                        newData.push({
                                            fieldAPI : this.columns[w].fieldAPI,
                                            classDetails : this.columns[w].classDetails,
                                            disabled : this.mapOfProductsDiscount[productId],
                                            fieldValue : data.listOfItemVariables[v].oli[this.columns[w].fieldAPI],
                                            fieldType : this.columns[w].fieldType,
                                            labelValue : ''
                                        });
                                    }*/else if(this.columns[w].fieldAPI == 'Discount_Coupon__c' || this.columns[w].fieldAPI == 'Discount__c' || this.columns[w].fieldAPI == 'Discount_Length_of_Months__c'){
                                        newData.push({
                                            fieldAPI : this.columns[w].fieldAPI,
                                            classDetails : this.columns[w].classDetails,
                                            disabled : true,
                                            fieldValue : data.listOfItemVariables[v].oli[this.columns[w].fieldAPI],
                                            fieldType : this.columns[w].fieldType,
                                            labelValue : ''
                                        });
                                    }else{
                                        newData.push({
                                            fieldAPI : this.columns[w].fieldAPI,
                                            classDetails : this.columns[w].classDetails,
                                            disabled : false,
                                            fieldValue : data.listOfItemVariables[v].oli[this.columns[w].fieldAPI],
                                            fieldType : this.columns[w].fieldType,
                                            labelValue : ''
                                        });
                                    }
                                    
                                }
                                
                            }else{
                                newData.push({
                                    fieldAPI : this.columns[w].fieldAPI,
                                    classDetails : this.columns[w].classDetails,
                                    disabled : true,
                                    fieldValue : data.listOfItemVariables[v].oli[this.columns[w].fieldAPI],
                                    fieldType : this.columns[w].fieldType,
                                    labelValue : ''
                                });
                            }
                            if(this.columns[w].fieldAPI == 'Product2Id__c'){
                                if(data.listOfItemVariables[v].oli[this.columns[w].fieldAPI] == this.label.Klaviyo_Customer_Platform){
                                    this.isKlaviyoCustomerPlatform = true;
                                }
                                if(data.listOfItemVariables[v].oli[this.columns[w].fieldAPI] == this.label.Klaviyo_Email){
                                    this.isKlaviyoEmail = true;
                                }
                            }
                        }
                    }
                    workingData.push({
                        oli : data.listOfItemVariables[v].oli,
                        disableValue : data.listOfItemVariables[v].disableValue,
                        recordId : data.listOfItemVariables[v].recordId,
                        classDetails : data.listOfItemVariables[v].classDetails,
                        wData : newData
                    });
                }

                if (this.isOpportunityClosed === false && this.label.MPO_LWC_Lock_Down_Discount_Fields === 'Yes') {
                    workingData.forEach(eachRow => {
                        if (this.mapOfProductsDiscount[eachRow.oli.Product2Id] === false) {
                            eachRow.wData.forEach(eachColumn => {
                                if (this.paymentMethod === 'Stripe') {
                                    if (eachColumn.fieldAPI === 'Discount_Coupon__c') {
                                        eachColumn.disabled = false;
                                    }
                                    if (eachColumn.fieldAPI === 'Usage_Period__c') {
                                        //eachColumn.disabled = false;
                                    }
                                } else {
                                    if (eachColumn.fieldAPI === 'Discount__c' || eachColumn.fieldAPI === 'Discount_Length_of_Months__c') {
                                        eachColumn.disabled = false;
                                    }
                                    if (eachColumn.fieldAPI === 'Usage_Period__c') {
                                        //eachColumn.disabled = true;
                                    }
                                }
                                
                            })
                        }
                    })
                }

                if (this.isOpportunityClosed === false) {
                    workingData.forEach(eachRow => {
                        if (this.mapOfProductsDiscount[eachRow.oli.Product2Id] === false) {
                            eachRow.wData.forEach(eachColumn => {
                                if (this.paymentMethod === 'Stripe') {
                                    if (eachColumn.fieldAPI === 'Usage_Period__c') {
                                        eachColumn.disabled = true;
                                    }
                                } else {
                                    if (eachColumn.fieldAPI === 'Usage_Period__c') {
                                        eachColumn.disabled = false;
                                    }
                                }
                                
                            })
                        }

                        if (this.mapOfProductsUsage[eachRow.oli.Product2Id] === true) {
                            eachRow.wData.forEach(eachColumn => {
                                if (this.paymentMethod != 'Stripe') {
                                    if (eachColumn.fieldAPI === 'Usage_Period__c') {
                                        eachColumn.disabled = true;
                                    }
                                }
                            })
                        }

                        if (this.mapOfLockedUsage[eachRow.oli.Product2Id]) {
                            eachRow.wData.forEach(eachColumn => {
                                if (eachColumn.fieldAPI === 'Usage_Period__c') {
                                        eachColumn.disabled = true;
                                }
                            })
                        }

                    })
                }

                if (this.isOpportunityClosed === false && this.label.MPO_LWC_Lock_Down_Discount_Fields === 'No') {
                    workingData.forEach(eachRow => {
                        if (this.mapOfProductsDiscount[eachRow.oli.Product2Id] === false) {
                            eachRow.wData.forEach(eachColumn => {
                                if (eachColumn.fieldAPI === 'Discount_Coupon__c' || eachColumn.fieldAPI === 'Discount__c' || eachColumn.fieldAPI === 'Discount_Length_of_Months__c') {
                                    eachColumn.disabled = false;
                                }
                                
                            })
                        }
                    })
                }
                this.data = workingData;
                this.isFooterButtonVisible = true;
                this.isLoaded = true;
            } else if (error) {
                console.log(error);
                alert('Error : ' + error);
                this.data = undefined;
            }
            
        })
        .catch((error) =>{
            console.log(error);
            alert('Error : ' + error);
            this.data = undefined;
        })
    }

    showToast(titleValue, variantValue, messageValue) {
        const evt = new ShowToastEvent({
            title: titleValue,
            message: messageValue,
            variant: variantValue,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /*handleEdit(event){
        if(this.isOpportunityClosed){
            this.showToast('Error', 'error', 'Opportunity is Closed not able to edit Products');
            return;
        }
        let workingData = [];
        const selectedRecordId = event.target.name;
        for(let v in this.data) {
            let newData = [];
            for(let w in this.columns) {
                if(this.columns[w].fieldAPI != 'Action'){
                    if(this.data[v].recordId == selectedRecordId) {
                        if(this.columns[w].fieldAPI != 'List_Price__c' && this.columns[w].fieldAPI != 'UnitPrice' && this.columns[w].fieldAPI != 'TotalPrice'){
                            newData.push({
                                fieldAPI : this.columns[w].fieldAPI,
                                classDetails : this.columns[w].classDetails,
                                disabled : false,
                                fieldValue : this.data[v].oli[this.columns[w].fieldAPI],
                                fieldType : this.columns[w].fieldType
                            });
                        }else{
                            newData.push({
                                fieldAPI : this.columns[w].fieldAPI,
                                classDetails : this.columns[w].classDetails,
                                disabled : true,
                                fieldValue : this.data[v].oli[this.columns[w].fieldAPI],
                                fieldType : this.columns[w].fieldType
                            });
                        }
                    }else{
                        newData.push({
                            fieldAPI : this.columns[w].fieldAPI,
                            classDetails : this.columns[w].classDetails,
                            disabled : true,
                            fieldValue : this.data[v].oli[this.columns[w].fieldAPI],
                            fieldType : this.columns[w].fieldType
                        });
                    }
                }
            }
            if(this.data[v].recordId == selectedRecordId) {
                workingData.push({
                    oli : this.data[v].oli,
                    disableValue : false,
                    recordId : this.data[v].recordId,
                    classDetails : this.data[v].classDetails,
                    wData : newData
                });
            }else{
                workingData.push({
                    oli : this.data[v].oli,
                    disableValue : true,
                    recordId : this.data[v].recordId,
                    classDetails : this.data[v].classDetails,
                    wData : newData
                });
            }
        }
        this.data = workingData;
    };*/

    handleChange(event){
        let productIdT;
        let discountId;
        const current = this,
            dataParamSet = event.target.dataset;
        if (dataParamSet)  {
            if (dataParamSet.item) {
                const value = event.target.value,
                    fieldName = dataParamSet.colname;
                    if(fieldName == 'Product2Id__c'){
                        productIdT = value;
                    }
                    if(fieldName == 'Discount_Coupon__c'){
                        discountId = value;
                    }
                    //Remove validation based on billing method
                    /*
                    if(fieldName == 'Product2Id__c'){
                        productIdT = value;
                        if(this.paymentMethod == 'Stripe' && (value == this.label.Klaviyo_Customer_Platform || value == this.label.Klaviyo_Email)){
                            this.showToast('Error', 'error', 'You are not able to add Klaviyo Email or Klaviyo Customer Platform.');
                        }
                    }
                    */
                let tableDataSet = JSON.parse(JSON.stringify(current.data));
                /***********************************************************************************************/
                if(this.label.MPO_LWC_Lock_Down_Discount_Fields === 'Yes'){
                    tableDataSet.forEach(eachData => {
                        if (eachData.recordId === dataParamSet.item) {
                            if (eachData.wData && eachData.wData.length > 0) {
                                eachData.wData.forEach(wDataEach => {
                                    if (productIdT) {
                                        if (this.paymentMethod === 'Stripe') {
                                            if (wDataEach.fieldAPI === 'Discount_Coupon__c') {
                                                wDataEach.disabled = false;
                                            }
                                            if (wDataEach.fieldAPI === 'Discount_Length_of_Months__c') {
                                                wDataEach.disabled = true;
                                            }
                                            if (wDataEach.fieldAPI === 'Discount__c') {
                                                wDataEach.disabled = true;
                                            }
                                            if (wDataEach.fieldAPI === 'Usage_Period__c') {
                                                wDataEach.disabled = true;
                                            }
                                        } else {
                                            if (wDataEach.fieldAPI === 'Discount_Coupon__c') {
                                                wDataEach.disabled = true;
                                            }
                                            if (wDataEach.fieldAPI === 'Discount_Length_of_Months__c') {
                                                wDataEach.disabled = false;
                                            }
                                            if (wDataEach.fieldAPI === 'Discount__c') {
                                                wDataEach.disabled = false;
                                            }
                                            if (wDataEach.fieldAPI === 'Usage_Period__c') {
                                                wDataEach.disabled = false;
                                            }
                                            if (this.mapOfProductsUsage[productIdT] === true) {
                                                if (wDataEach.fieldAPI === 'Usage_Period__c') {
                                                    wDataEach.disabled = true;
                                                }
                                            }
                                        }
                                    }
                                    
                                })
                            }
                        }
                    })
                }
                /***********************************************************************************************/
                //alert(productIdT + this.mapOfProductsDiscount[productIdT]);
                tableDataSet.forEach(eachData => {
                    if (eachData.recordId === dataParamSet.item) {
                        if (eachData.wData && eachData.wData.length > 0) {
                            eachData.wData.forEach(wDataEach => {
                                if (wDataEach.fieldAPI === fieldName) {
                                    wDataEach.fieldValue = value;
                                    eachData.oli[fieldName] = value;
                                }
                                if (wDataEach.fieldAPI === 'Usage_Limit__c' && productIdT) {
                                    wDataEach.labelValue = this.mapOfProducts[productIdT];
                                }
                                if(this.mapOfProductsDiscount[productIdT] === true){
                                    if (wDataEach.fieldAPI === 'Discount__c' && productIdT) {
                                        wDataEach.disabled = this.mapOfProductsDiscount[productIdT];
                                    }
                                    if (wDataEach.fieldAPI === 'Discount_Coupon__c' && productIdT) {
                                        wDataEach.disabled = this.mapOfProductsDiscount[productIdT];
                                    }
                                    if (wDataEach.fieldAPI === 'Discount_Length_of_Months__c' && productIdT) {
                                        wDataEach.disabled = this.mapOfProductsDiscount[productIdT];
                                    }
                                }
                                if(productIdT && this.mapOfProductsUsage[productIdT] === true && this.paymentMethod != 'Stripe'){
                                    if (wDataEach.fieldAPI === 'Usage_Period__c') {
                                        wDataEach.disabled = true;
                                    }
                                }
                                if(wDataEach.fieldAPI === 'Usage_Period__c'){
                                    if (productIdT && fieldName == 'Product2Id__c' && this.mapOfDefaultUsage[productIdT]) {
                                        wDataEach.fieldValue = this.mapOfDefaultUsage[productIdT];
                                    }
                                    if (productIdT && this.mapOfLockedUsage[productIdT]) {
                                        wDataEach.disabled = this.mapOfLockedUsage[productIdT];
                                    }
                                }
                            })
                        }
                    }
                }) 
                if(fieldName == 'Discount_Coupon__c' && discountId && this.mapOfDiscount[discountId] != undefined){
                    tableDataSet.forEach(eachData => {
                        if (eachData.recordId === dataParamSet.item) {
                            if (eachData.wData && eachData.wData.length > 0) {
                                eachData.wData.forEach(wDataEach => {
                                    if (wDataEach.fieldAPI === 'Discount__c') {
                                        wDataEach.fieldValue = this.mapOfDiscount[discountId].Discount__c;
                                        wDataEach.disabled = true;
                                    }
                                    if (wDataEach.fieldAPI === 'Discount_Length_of_Months__c') {
                                        wDataEach.fieldValue = this.mapOfDiscount[discountId].Length_of_Months__c;
                                        wDataEach.disabled = true;
                                    }
                                    if (wDataEach.fieldAPI === 'Discount_Coupon__c') {
                                        wDataEach.disabled = true;
                                    }
                                })
                            }
                        }
                    }) 
                }
                if(fieldName == 'Discount_Coupon__c' && this.paymentMethod === 'Stripe'){
                    tableDataSet.forEach(eachData => {
                        if (eachData.recordId === dataParamSet.item) {
                            if (eachData.wData && eachData.wData.length > 0) {
                                eachData.wData.forEach(wDataEach => {
                                    if (wDataEach.fieldAPI === 'Discount_Coupon__c' && (wDataEach.fieldValue === '' || wDataEach.fieldValue === undefined)) {
                                        eachData.wData.forEach(wDataEachCol => {
                                            if(wDataEachCol.fieldAPI === 'Discount__c' || wDataEachCol.fieldAPI === 'Discount_Length_of_Months__c'){
                                                wDataEachCol.fieldValue = 0;
                                            }
                                        })
                                    }
                                })
                            }
                        }
                    }) 
                }
                current.data = null;
                current.data = tableDataSet;
                if(fieldName == 'Product2Id__c' && this.mapOfProductOptyValues[productIdT] != undefined && this.opportunityStage){
                    this.optyData = [];
                    this.mapOfProductOptyValues[productIdT].forEach(eachData => {
                        if(eachData.fieldType === 'New'){
                            this.optyData.push({
                                key : eachData.key , value : '', productId : productIdT, action : 'New'
                            });
                        }
                    })
                    if(this.optyData != '' && this.optyData){
                        this.showOpty = true;
                    }
                }
                if(fieldName == 'Product2Id__c'){
                    if(value == this.label.Klaviyo_Customer_Platform && !this.isKlaviyoEmail){
                        this.addOtherProduct(this.label.Klaviyo_Email);
                    }else if(value == this.label.Klaviyo_Email && !this.isKlaviyoCustomerPlatform){
                        this.addOtherProduct(this.label.Klaviyo_Customer_Platform);
                    }
                }
            }
        }
    };

    async confirmDelete(recordIdForDelete, productIdForDelete){
        const popupresult = await LightningConfirm.open({
            message: 'Please confirm if you want to delete Product. This will delete product from Opportunity.',
            variant: 'headerless',
            label: 'Confirmation',
            // setting theme would have no effect
        });
        if(popupresult){
            if(productIdForDelete && this.mapOfProductOptyValues[productIdForDelete] != undefined && this.mapOfOriginalOpportunity[this.opportunityId + productIdForDelete] === undefined){
                this.optyData = [];
                this.mapOfProductOptyValues[productIdForDelete].forEach(eachData => {
                    if(eachData.fieldType === 'Delete'){
                        this.optyData.push({
                            key : eachData.key , value : '', productId : productIdForDelete, action : 'Delete'
                        });
                    }
                })
                if(this.optyData != '' && this.optyData){
                    this.deleteRecordId = recordIdForDelete;
                    this.deleteProductId = productIdForDelete;
                    this.isForDelete = true;
                    this.showOpty = true;
                }else{
                    this.isLoaded = false;
                    deleteProduct({recordIdForDelete : recordIdForDelete, mapOfProductOptyValues : JSON.stringify(this.mapOfProductOptyValues), opportunityId : this.opportunityId})
                        .then((data) =>{
                            if (data) {
                                if(data == 'Success'){
                                    this.showToast('Success', 'success', 'Product deleted successfully');
                                    this.getCompleteData();
                                }
                                else{
                                    this.isLoaded = true;
                                    this.showToast('Error', 'error', JSON.stringify(data));    
                                }
                            }
                        })
                        .catch((error) =>{
                            this.isLoaded = true;
                            this.showToast('Error', 'error', JSON.stringify(error.body.exceptionType));
                        })
                }
            }else{
                this.isLoaded = false;
                deleteProduct({recordIdForDelete : recordIdForDelete, mapOfProductOptyValues : JSON.stringify(this.mapOfProductOptyValues), opportunityId : this.opportunityId})
                    .then((data) =>{
                        if (data) {
                            if(data == 'Success'){
                                this.showToast('Success', 'success', 'Product deleted successfully');
                                this.getCompleteData();
                            }else{
                                this.isLoaded = true;
                                this.showToast('Error', 'error', JSON.stringify(data));
                            }
                        }
                    })
                    .catch((error) =>{
                        this.isLoaded = true;
                        this.showToast('Error', 'error', JSON.stringify(error.body.exceptionType));
                    })
            }
        }
    };

    handleDelete(event){
        if(this.isOpportunityClosed){
            this.showToast('Error', 'error', 'Opportunity is Closed not able to delete Products');
            return;
        }
        let isAmendedSubs = false;
        const selectedRecordId = event.target.name;
        let productIdForDelete;
        for(let v in this.data) {
            if(this.data[v].recordId == selectedRecordId) {
                if(this.data[v].oli != null && this.data[v].oli.Amended_Subscription__c){
                    isAmendedSubs = true;
                }
                if(selectedRecordId.length > 10 && this.data[v].oli != null){
                    productIdForDelete = this.data[v].oli.Product2Id__c;
                }
            }
        }
        if(isAmendedSubs){
            this.showToast('Error', 'error', 'Product is Amended Subscription. Not able to delete.');
        }else{
            this.confirmDelete(selectedRecordId, productIdForDelete);
        }
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
        
     };

    handleSave(event){
        if(this.isOpportunityClosed){
            this.showToast('Error', 'error', 'Opportunity is Closed not able to save Products');
            return;
        }
        let isDuplicate = false;
        let isBundle = false;
        let isBundleAmend = false;
        let isCombo1 = false;
        let isCombo1Amend = false;
        let isCombo2 = false;
        let isCombo2Amend = false;
        for(let v in this.data) {
            for(let w in this.data[v].wData){
                for(let vv in this.data) {
                    for(let x in this.data[vv].wData){
                        if(this.data[v].wData[w].fieldAPI == 'Product2Id__c' && this.data[vv].wData[x].fieldAPI == 'Product2Id__c' && v != vv){
                            if(this.data[v].wData[w].fieldValue == this.data[vv].wData[x].fieldValue){
                                isDuplicate = true;
                            }
                            if(this.data[v].wData[w].fieldValue == this.label.Klaviyo_Customer_Platform_w_Email){
                                isBundle = true;
                                if(this.data[v].oli != null && this.data[v].oli.Usage_Limit__c == 0){
                                    isBundleAmend = true;
                                }
                            }
                            if(this.data[v].wData[w].fieldValue == this.label.Klaviyo_Email){
                                isCombo1 = true;
                                if(this.data[v].oli != null && this.data[v].oli.Usage_Limit__c == 0){
                                    isCombo1Amend = true;
                                }
                            }
                            if(this.data[v].wData[w].fieldValue == this.label.Klaviyo_Customer_Platform){
                                isCombo2 = true;
                                if(this.data[v].oli != null && this.data[v].oli.Usage_Limit__c == 0){
                                    isCombo2Amend = true;
                                }
                            }
                            //Remove validation based on billing method
                            /*
                            if(this.paymentMethod == 'Stripe' && (this.data[v].wData[w].fieldValue == this.label.Klaviyo_Customer_Platform || this.data[v].wData[w].fieldValue == this.label.Klaviyo_Email)){
                                this.showToast('Error', 'error', 'You are not able to add Klaviyo Email or Klaviyo Customer Platform.');
                                return;
                            }
                            */
                        }
                    }
                }
                
            }
        }
        if(isDuplicate){
            this.showToast('Error', 'error', 'Remove duplicate Product.');
            return;
        }
        if((isBundle && isCombo1) || (isBundle && isCombo2)){
            if(isBundle && isBundleAmend && isCombo1 && isCombo2){

            }else if(isCombo1 && isCombo2 && isCombo1Amend && isCombo2Amend && isBundle){

            }else{
                this.showToast('Error', 'error', 'Klaviyo Customer Platform w Email can not be added with Klaviyo Email either with Klaviyo Customer Platform');
                return;
            }
        }
        if((isCombo1 && !isCombo2) || (!isCombo1 && isCombo2)){
            this.showToast('Error', 'error', 'Klaviyo Email either with Klaviyo Customer Platform are mandatory');
            return;
        }
        const selectedRecordId = event.target.name;
        let newData = [];
        let workingData = [];
        let columnsDetails = this.columns;
        let fieldDetails;
        
        for(let v in this.data) {
            newData = [];
            newData.push({
                key : 'Id' , value : this.data[v].recordId, fieldType : 'ID'
            });
            newData.push({
                key : 'OpportunityId' , value : this.recordId, fieldType : 'REFERENCE'
            });
            for(let w in this.data[v].wData){
                if(this.data[v].wData[w].fieldAPI != 'List_Price__c' && this.data[v].wData[w].fieldAPI != 'UnitPrice' && this.data[v].wData[w].fieldAPI != 'TotalPrice' && this.data[v].wData[w].fieldAPI != 'Product2Id__c'){
                    newData.push({
                        key : this.data[v].wData[w].fieldAPI, value : this.data[v].wData[w].fieldValue, fieldType : this.data[v].wData[w].fieldType
                    });
                }
                if(this.data[v].wData[w].fieldAPI === 'Product2Id__c'){
                    newData.push({
                        key : 'Product2Id', value : this.data[v].wData[w].fieldValue, fieldType : this.data[v].wData[w].fieldType
                    });
                    newData.push({
                        key : this.data[v].wData[w].fieldAPI, value : this.data[v].wData[w].fieldValue, fieldType : this.data[v].wData[w].fieldType
                    });
                }
                if(this.data[v].wData[w].fieldAPI == 'Product2Id__c' && this.data[v].wData[w].fieldValue.length < 5){
                    this.showToast('Error', 'error', 'Please add the Product.');
                    return;
                }
                if(this.paymentMethod != 'Stripe' && this.data[v].wData[w].fieldAPI == 'Usage_Period__c' && this.data[v].wData[w].disabled == false && (this.data[v].wData[w].fieldValue === undefined || this.data[v].wData[w].fieldValue === '')){
                    this.showToast('Error', 'error', 'Please add the Usage Period.');
                    return;
                }
            }
            workingData.push({
                key : this.data[v].recordId, lineItemData : newData
            });
        }
        this.isLoaded = false;
            updateAllProduct({mapOfString : JSON.stringify(workingData), mapOfProductOptyValues : JSON.stringify(this.mapOfProductOptyValues), opportunityId : this.opportunityId})
            .then((data) =>{
                if (data) {
                    if(data == 'Success'){
                        this.showToast('Success', 'success', 'Products saved successfully');
                        this.getCompleteData();
                    }else{
                        this.isLoaded = true;
                        this.showToast('Error', 'error', JSON.stringify(data));
                    }
                }
            })
            .catch((error) =>{
                this.isLoaded = true;
                if(error){
                    this.showToast('Error', 'error', error);
                }
                
            })
    };

    addNew(event){
        let bOli = this.blankOLI;
        if(this.isOpportunityClosed){
            this.showToast('Error', 'error', 'Opportunity is Closed not able to add Products');
            return;
        }
        let newData = [];
        for(let w in this.columns) {
            if(this.columns[w].fieldAPI != 'Action'){
                if(this.columns[w].fieldAPI != 'List_Price__c' && this.columns[w].fieldAPI != 'UnitPrice' && this.columns[w].fieldAPI != 'TotalPrice'){
                    newData.push({
                        fieldAPI : this.columns[w].fieldAPI,
                        classDetails : this.columns[w].classDetails,
                        disabled : false,
                        fieldValue : null,
                        fieldType : this.columns[w].fieldType,
                        labelValue : ''
                    });
                }else{
                    newData.push({
                        fieldAPI : this.columns[w].fieldAPI,
                        classDetails : this.columns[w].classDetails,
                        disabled : true,
                        fieldValue : 0,
                        fieldType : this.columns[w].fieldType,
                        labelValue : ''
                    });
                }
                
            }
        }
        bOli['Id'] = (this.data.length + 1).toString();
        this.data.push({
            oli : bOli,
            disableValue : false,
            recordId : (this.data.length + 1).toString(),
            classDetails : this.listOfItemVariables[0].classDetails,
            wData : newData
        });
    };

    addOtherProduct(productIdT){
        let bOli = this.blankOLI;
        let newData = [];
        for(let w in this.columns) {
            if(this.columns[w].fieldAPI != 'Action'){
                if(this.columns[w].fieldAPI != 'Product2Id__c' && this.columns[w].fieldAPI != 'List_Price__c' && this.columns[w].fieldAPI != 'UnitPrice' && this.columns[w].fieldAPI != 'TotalPrice'){
                    if(this.columns[w].fieldAPI == 'Usage_Limit__c'){
                        newData.push({
                            fieldAPI : this.columns[w].fieldAPI,
                            classDetails : this.columns[w].classDetails,
                            disabled : false,
                            fieldValue : 0,
                            fieldType : this.columns[w].fieldType,
                            labelValue : this.mapOfProducts[productIdT]
                        });
                    }else if(this.columns[w].fieldAPI == 'Discount_Coupon__c'){
                        if(this.label.MPO_LWC_Lock_Down_Discount_Fields === 'Yes'){
                            if(this.paymentMethod === 'Stripe' && this.mapOfProductsDiscount[productIdT] === false){
                                newData.push({
                                    fieldAPI: this.columns[w].fieldAPI,
                                    classDetails: this.columns[w].classDetails,
                                    disabled: false,
                                    fieldValue: null,
                                    fieldType: this.columns[w].fieldType,
                                    labelValue: ''
                                });
                            }else{
                                newData.push({
                                    fieldAPI: this.columns[w].fieldAPI,
                                    classDetails: this.columns[w].classDetails,
                                    disabled: true,
                                    fieldValue: null,
                                    fieldType: this.columns[w].fieldType,
                                    labelValue: ''
                                });
                            }
                        }else{
                            newData.push({
                                fieldAPI: this.columns[w].fieldAPI,
                                classDetails: this.columns[w].classDetails,
                                disabled: this.mapOfProductsDiscount[productIdT],
                                fieldValue: null,
                                fieldType: this.columns[w].fieldType,
                                labelValue: ''
                            });
                        }
                    }else if(this.columns[w].fieldAPI == 'Discount__c' || this.columns[w].fieldAPI == 'Discount_Length_of_Months__c'){
                        if(this.label.MPO_LWC_Lock_Down_Discount_Fields === 'Yes'){
                            if(this.paymentMethod === 'Stripe'){
                                newData.push({
                                    fieldAPI: this.columns[w].fieldAPI,
                                    classDetails: this.columns[w].classDetails,
                                    disabled: true,
                                    fieldValue: 0,
                                    fieldType: this.columns[w].fieldType,
                                    labelValue: ''
                                });
                            }else if(this.mapOfProductsDiscount[productIdT] === false){
                                newData.push({
                                    fieldAPI: this.columns[w].fieldAPI,
                                    classDetails: this.columns[w].classDetails,
                                    disabled: false,
                                    fieldValue: 0,
                                    fieldType: this.columns[w].fieldType,
                                    labelValue: ''
                                });
                            }else{
                                newData.push({
                                    fieldAPI: this.columns[w].fieldAPI,
                                    classDetails: this.columns[w].classDetails,
                                    disabled: true,
                                    fieldValue: 0,
                                    fieldType: this.columns[w].fieldType,
                                    labelValue: ''
                                });
                            }
                        }else{
                            newData.push({
                                fieldAPI: this.columns[w].fieldAPI,
                                classDetails: this.columns[w].classDetails,
                                disabled: this.mapOfProductsDiscount[productIdT],
                                fieldValue: 0,
                                fieldType: this.columns[w].fieldType,
                                labelValue: ''
                            });
                        }
                    }else if(this.columns[w].fieldAPI == 'Usage_Period__c'){
                        let usagePeriodForSet = '';
                        let usagePeriodDisable = false;

                        if ((productIdT && this.mapOfProductsUsage[productIdT] === true && this.paymentMethod != 'Stripe') || this.paymentMethod === 'Stripe') {
                            usagePeriodDisable = true;
                        }

                        if(this.mapOfDefaultUsage[productIdT]){
                            usagePeriodForSet = this.mapOfDefaultUsage[productIdT];
                        }
                        if(this.mapOfLockedUsage[productIdT]){
                            usagePeriodDisable = this.mapOfLockedUsage[productIdT];
                        }
                        newData.push({
                            fieldAPI : this.columns[w].fieldAPI,
                            classDetails : this.columns[w].classDetails,
                            disabled : usagePeriodDisable,
                            fieldValue : usagePeriodForSet,
                            fieldType : this.columns[w].fieldType,
                            labelValue : ''
                        });
                    }else{
                        newData.push({
                            fieldAPI : this.columns[w].fieldAPI,
                            classDetails : this.columns[w].classDetails,
                            disabled : false,
                            fieldValue : 0,
                            fieldType : this.columns[w].fieldType,
                            labelValue : ''
                        });
                    }
                    
                }else if(this.columns[w].fieldAPI == 'Product2Id__c'){
                    newData.push({
                        fieldAPI : this.columns[w].fieldAPI,
                        classDetails : this.columns[w].classDetails,
                        disabled : false,
                        fieldValue : productIdT,
                        fieldType : this.columns[w].fieldType,
                        labelValue : ''
                    });
                }else{
                    newData.push({
                        fieldAPI : this.columns[w].fieldAPI,
                        classDetails : this.columns[w].classDetails,
                        disabled : true,
                        fieldValue : 0,
                        fieldType : this.columns[w].fieldType,
                        labelValue : ''
                    });
                }
                
            }
        }
        bOli['Id'] = (this.data.length + 1).toString();
        this.data.push({
            oli : bOli,
            disableValue : false,
            recordId : (this.data.length + 1).toString(),
            classDetails : this.listOfItemVariables[0].classDetails,
            wData : newData
        });
    };

    handleClone(event) {
        const selectedRecordId = event.target.name;
        if (!this.isOpportunityClosed) {
            this.handleCloneSecond(selectedRecordId);

        } else {
            this.showToast('Error', 'error', 'Cannot clone Opportunity Product for a Closed Won or Closed Lost Opportunity');
        }

    };

    async handleCloneSecond(selectedRecordId){
        const popupresult = await LightningConfirm.open({
            message: 'Please confirm if you want to clone Product. This will create new opportunity and product.',
            variant: 'headerless',
            label: 'Confirmation',
            // setting theme would have no effect
        });
        if(popupresult){
            if(selectedRecordId.length > 10 ){
                this.flowInputVariables = [];
                this.flowName = 'Sub_flow_MPO_LWC_Opp_Clone_and_move_OLI';
                this.flowInputVariables = [
                    {name:"sobjId",type:"String",value : this.opportunityId},
                    {name:"sobjOLIId",type:"String",value : selectedRecordId}
                ];
                this.showFlow = true;
            }else {
                this.showToast('Error', 'error', 'This product is not commited yet.');
            }
        }
    }

    handleFlowStatusChange(event) {
		if (event.detail.status === "FINISHED" || event.detail.status === "FINISHED_SCREEN") {
			this.showToast('Success', 'success', 'Product cloned successfully.');
            this.showFlow = false;
            this.getCompleteData();
		}else{
            this.showToast('Error', 'error', 'Product not cloned due to some error in flow.');
            this.showFlow = false;
        }
	};

    handleSaveValues(event) {
        let isValid = false;
        this.optyData.forEach(eachDataOpty => {
            this.mapOfProductOptyValues[eachDataOpty.productId].forEach(eachData => {
                if(eachDataOpty.key === eachData.key && eachDataOpty.action === eachData.fieldType){
                    eachData.value = eachDataOpty.value;
                }
            })
            if(eachDataOpty.value === '' || eachDataOpty.value === null || eachDataOpty.value === undefined){
                isValid = true;
            }
        })
        if(isValid){
            this.showToast('Error', 'error', 'All fields are required');
            return;
        }else{
            this.showOpty = false;
            if(this.isForDelete && this.deleteRecordId != '' && this.deleteProductId != ''){
                this.isLoaded = false;
                    deleteProduct({recordIdForDelete : this.deleteRecordId, mapOfProductOptyValues : JSON.stringify(this.mapOfProductOptyValues), opportunityId : this.opportunityId})
                        .then((data) =>{
                            if (data) {
                                if(data == 'Success'){
                                    this.deleteRecordId = '';
                                    this.deleteProductId = '';
                                    this.isForDelete = false;
                                    this.showToast('Success', 'success', 'Product deleted successfully');
                                    this.getCompleteData();
                                }else{
                                    this.isLoaded = true;
                                    this.showToast('Error', 'error', JSON.stringify(data));
                                }
                            }
                        })
                        .catch((error) =>{
                            this.isLoaded = true;
                            this.showToast('Error', 'error', JSON.stringify(error.body.exceptionType));
                        })
            }
        }
        
    };

    handleChangeOpty(event){
        const current = this,
        dataParamSet = event.target.dataset;
        if (dataParamSet)  {
            if (dataParamSet.item) {
                const value = event.target.value,
                fieldName = dataParamSet.colname;
                this.optyData.forEach(eachData => {
                    if(fieldName == eachData.key){
                        eachData.value = value;
                    }
                })
            }
        }
    }
}
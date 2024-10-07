/**
 * @class name        : refreshView
 * @description       : Refesh view when a platform event is received
 * @author            : 07-10-2024
 * @created on        : Rubén Sánchez González
 * @last modified on  : 07-10-2024
 * @last modified by  : Rubén Sánchez González - ruben.s.gonzalez@accenture.com
**/
import { LightningElement, api } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { updateRecord } from 'lightning/uiRecordApi';

export default class RefreshView extends LightningElement {
    @api recordId;

   
    connectedCallback() {
        this.handleSubscribe();
        this.registerErrorListener();
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = (response) => {
            console.log('New message received : ', JSON.stringify(response));
            this.payload = JSON.stringify(response);
            debugger;
            if(this.recordId == response.data.payload.QUFV_fld_idObjectRecord__c){
                eval("$A.get('e.force:refreshView').fire();");
            }   
            // Response contains the payload of the new message received
        };

        const channelName = '/event/[platformeventApiName__e]';
        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on successful subscribe call
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
           
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
}
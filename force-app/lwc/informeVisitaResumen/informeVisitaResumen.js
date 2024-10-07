/**
 * @class name        : informeVisitaResumen
 * @description       : LWC to display info related to the visit
 * @created on        : 18-09-2024
 * @last modified on  : 07-10-2024
 **/
import { LightningElement, api, wire } from 'lwc'
import { getRecord } from 'lightning/uiRecordApi'
import { TEMAS_TRATADOS, FIELDS_INFORME } from 'c/informeVisitaNuevo'
import gestorCuentaPermission from '@salesforce/customPermission/QUFV_cp_gestorCuenta'

export default class InformeVisitaResumen extends LightningElement {
  @api informeId

  subject
  negociation
  market
  recycleSustainability
  technicalAdvice
  satisfactionComplaints
  logistics
  administrative
  additionalInformation

  temasDisplay = TEMAS_TRATADOS

  @wire(getRecord, {
    recordId: '$informeId',
    fields: FIELDS_INFORME,
  })
  wiredRecord({ error, data }) {
    if (error) {
      console.error('Error:', error)
    } else if (data) {
      this.subject = data.fields.QUFV_fld_eventSubject__c?.value
      this.negociation = data.fields.QUFV_fld_negociation__c?.value
      this.market = data.fields.QUFV_fld_market__c?.value
      this.recycleSustainability =
        data.fields.QUFV_fld_recycleSustainability__c?.value
      this.technicalAdvice = data.fields.QUFV_fld_technicalAdvice__c?.value
      this.satisfactionComplaints = data.fields.QUFV_fld_feedback__c?.value
      this.logistics = data.fields.QUFV_fld_logistic__c?.value
      this.administrative = data.fields.QUFV_fld_administrative__c?.value
      this.additionalInformation = data.fields.QUFV_fld_informeVisita__c?.value

      // Update temasDisplay with the actual values
      this.temasDisplay = this.temasDisplay.map((tema) => ({
        ...tema,
        value: this[tema.name],
      }))
    }
  }

  get isFFVV() {
    return gestorCuentaPermission
  }
  get isATD() {
    return !gestorCuentaPermission
  }
}

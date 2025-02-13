/**
 * @class name        : capacidadDetail
 * @description       : Layout for detail and edit of a capacity.
 * @author            : Rubén Sánchez González
 * @created on        : 17-10-2024
 * @last modified on  : 18-12-2024
 * @last modified by  : Rubén Sánchez González
 **/
import { api, wire } from 'lwc'
import LightningModal from 'lightning/modal'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import { getRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi'
import FAMILIA_FIELD from '@salesforce/schema/QUFV_obj_capacidad__c.QUFV_fld_family__c'
import insertCapacidad from '@salesforce/apex/Capacidad.insertCapacidad'
import upsertCapacidad from '@salesforce/apex/Capacidad.upsertCapacidad'
import deleteCapacidad from '@salesforce/apex/Capacidad.deleteCapacidad'
import deleteAll from '@salesforce/apex/capacidad.deleteAll'

const LABEL_DETAIL = 'Detalle de capacidad'
const LABEL_EDIT = 'Editar capacidad'
const LABEL_DELETE = 'Eliminar capacidad'
const LABEL_NEW_RECORD = 'Nueva capacidad'
const FIELDS_CAPACIDAD = [
  'QUFV_obj_capacidad__c.Name',
  'QUFV_obj_capacidad__c.QUFV_fld_idExterno__c',
  'QUFV_obj_capacidad__c.QUFV_fld_account__c',
  'QUFV_obj_capacidad__c.QUFV_fld_sumi__c',
  'QUFV_obj_capacidad__c.QUFV_fld_year__c',
  'QUFV_obj_capacidad__c.QUFV_fld_family__c',
  'QUFV_obj_capacidad__c.QUFV_fld_anualConsumption__c',
  'QUFV_obj_capacidad__c.QUFV_fld_competitors__c',
  'QUFV_obj_capacidad__c.QUFV_fld_lastModifiedDate__c',
  'QUFV_obj_capacidad__c.QUFV_fld_comments__c',
  'QUFV_obj_capacidad__c.RecordTypeId',
]
const FIELDS_ACCOUNT = [
  'Account.Id',
  'Account.Name',
  'Account.Name',
  'Account.QUFV_fld_codigo__c',
]
export default class CapacidadDetail extends LightningModal {
  @api capacidadId
  @api cliente
  @api year
  @api familia
  @api action
  @api manual
  loading = true
  _isEditing = false
  _isViewing = false
  _isDeleting = false
  _isDeletingAll = false
  _isCreating = false
  labelHeader = LABEL_DETAIL

  _capacidadName
  _cliente
  _sumi
  clienteName
  clienteCode
  _year
  _familia
  consumo
  competidores
  fechaDato = new Date().toISOString().split('T')[0]
  comentarios
  optionsFamilia = []
  disableFamilia
  disableYear
  rtId

  displayInfo = {
    primaryField: 'Name',
    additionalFields: ['QUFV_fld_codigo__c'],
  }
  matchingInfo = {
    primaryField: { fieldPath: 'Name' },
    additionalFields: [{ fieldPath: 'QUFV_fld_codigo__c' }],
  }
  filter
  disableCliente = true

  get missingRecord() {
    return !this.capacidadId
  }

  get isMobile() {
    const userAgent = navigator.userAgent || navigator.vendor || window.opera
    return this.mobileRender || /android|ipad|iphone|ipod/i.test(userAgent)
  }

  get labelNew() {
    return this.isMobile ? 'Crear' : 'Crear registro'
  }

  get labelDelete() {
    return this.isMobile ? 'Borrar' : 'Borrar capacidades de familia'
  }

  connectedCallback() {
    // case values come from qufv_lwc_capacidadTree.js ACTION_ROWS_CHILD & ACTION_ROWS_PARENT
    switch (this.action) {
      case 'show_details':
        this._isViewing = true
        this.labelHeader = LABEL_DETAIL
        break
      case 'edit':
        this._isEditing = true
        this.labelHeader = LABEL_EDIT
        break
      case 'delete':
        this._isDeleting = true
        this.labelHeader = LABEL_DELETE
        break
      case 'deleteAll':
        this._isDeletingAll = true
        this.labelHeader = LABEL_DELETE
        break
      case 'new':
        this._isCreating = true
        this.labelHeader = LABEL_NEW_RECORD
        break
      default:
        break
    }
    this._year = this.year
    this._familia = this.familia
    this._cliente = this.cliente
    this.loading = false
  }

  @wire(getRecord, { recordId: '$capacidadId', fields: FIELDS_CAPACIDAD })
  capacidadData({ error, data }) {
    if (data) {
      this._capacidadName = data.fields?.Name?.value
      this._year = data.fields?.QUFV_fld_year__c?.value
      this._familia = data.fields?.QUFV_fld_family__c?.value
      this._sumi = data.fields?.QUFV_fld_sumi__c?.value
      this.consumo = data.fields?.QUFV_fld_anualConsumption__c?.value
      this.competidores = data.fields?.QUFV_fld_competitors__c?.value
      this.fechaDato = data.fields?.QUFV_fld_lastModifiedDate__c?.value
      this.comentarios = data.fields?.QUFV_fld_comments__c?.value
      this.rtId = data.fields?.RecordTypeId?.value
      this.disableFamilia = true
      this.disableYear = true
    } else if (error) {
      console.error('Error fetching capacidad data:', error)
    }
  }

  @wire(getRecord, { recordId: '$cliente', fields: FIELDS_ACCOUNT })
  clienteData({ error, data }) {
    if (data) {
      this._cliente = data.fields?.Id?.value
      this.clienteName = data.fields?.Name?.value
      this.clienteCode = data.fields?.QUFV_fld_codigo__c?.value
      this.filter = {
        criteria: [
          {
            fieldPath: 'QUFV_fld_codigo__c',
            operator: 'like',
            value: `%${this.clienteCode}%`,
          },
        ],
      }
      this.disableCliente = false
    } else if (error) {
      console.error('Error fetching cliente data:', error)
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: '012000000000000AAA',
    fieldApiName: FAMILIA_FIELD,
  })
  picklistFamiliaResults(result) {
    this.optionsFamilia = result.data?.values
  }

  // #region Handler functions
  handleCloseClick() {
    this.close('canceled')
  }

  handleEdit() {
    this._isViewing = false
    this._isEditing = true
    this.labelHeader = LABEL_EDIT
    this.notifyParent()
  }

  changeDefault(evt) {
    this[evt.target.name] = evt.detail.value
  }

  changeRecordPicker(evt) {
    this[evt.target.name] = evt.detail.recordId
  }

  handleSave() {
    if (!this.validateInputs()) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Faltan datos obligatorios',
          message: 'Por favor, rellena todos los campos marcados.',
          variant: 'error',
        }),
      )
      return
    }
    this.submitCapacidad()
  }

  async handleDelete() {
    if (this._isDeleting) {
      await this.handleDBAction(deleteCapacidad, null, 'eliminar')
    } else if (this._isDeletingAll) {
      await this.handleDBAction(deleteAll, null, 'borrar familia')
    }
  }

  submitCapacidad() {
    this.loading = true
    const params = JSON.stringify({
      Id: this.capacidadId,
      Name: this._capacidadName,
      QUFV_fld_idExterno__c: this._capacidadName,
      QUFV_fld_account__c: this._cliente,
      QUFV_fld_sumi__c: this._sumi,
      QUFV_fld_year__c: this._year,
      QUFV_fld_family__c: this._familia.trim().split(' ')[0],
      QUFV_fld_anualConsumption__c: this.consumo,
      QUFV_fld_competitors__c: this.competidores,
      QUFV_fld_lastModifiedDate__c: this.fechaDato,
      QUFV_fld_comments__c: this.comentarios,
      RecordTypeId: this.rtId,
    })
    if (this._isEditing) {
      this.handleDBAction(upsertCapacidad, params, 'actualizar')
    } else if (this._isCreating) {
      this.handleDBAction(insertCapacidad, params, 'insertar')
    }
  }

  notifyParent() {
    const editedRecord = new CustomEvent('edited', {
      detail: {
        capacidad: this.capacidadId,
      },
    })
    this.dispatchEvent(editedRecord)
  }

  avoidLetters(event) {
    // Allow control keys (backspace, delete, tab, escape, enter, etc.)
    if (
      event.key === 'Backspace' ||
      event.key === 'Delete' ||
      event.key === 'Tab' ||
      event.key === 'Escape' ||
      event.key === 'Enter' ||
      (event.key === 'a' && event.ctrlKey === true) || // Allow Ctrl+A
      (event.key === 'c' && event.ctrlKey === true) || // Allow Ctrl+C
      (event.key === 'v' && event.ctrlKey === true) || // Allow Ctrl+V
      (event.key === 'x' && event.ctrlKey === true) || // Allow Ctrl+X
      event.key === 'ArrowLeft' ||
      event.key === 'ArrowRight' // Allow arrow keys
    ) {
      return
    }
    // Allow numbers and decimal separator
    const validKeys = /^[0-9.,]$/
    if (validKeys.test(event.key)) {
      return
    }
    // Prevent all other keys
    event.preventDefault()
  }
  // #endregion Handler functions

  // #region Aux functions
  async handleDBAction(functionName, parameters, labelAction) {
    this.loading = true
    let succeded = false
    // if the function does not use a parameter, it does not affect
    await functionName({
      capacidadId: this.capacidadId,
      jsonParams: parameters,
      anno: this.year,
      familia: this.familia,
      clientId: this.cliente,
    })
      .then(() => {
        succeded = true
      })
      .catch((error) => {
        console.error(`Error ${labelAction} capacidad: `, error)
        this.dispatchEvent(
          new ShowToastEvent({
            title: `Error al ${labelAction}`,
            message: `Ha ocurrido un error al ${labelAction} la capacidad: ${error.message}.`,
            variant: 'error',
          }),
        )
      })
    this.waitAndConfirm(succeded)
  }

  async waitAndConfirm(succeded) {
    await notifyRecordUpdateAvailable([{ recordId: this.capacidadId }])
    if (succeded) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Solicitud completada',
          message: 'Se ha completado su petición.',
          variant: 'success',
        }),
      )
      this.notifyParent()
      this.loading = false
      this.close('success')
    }
  }

  validateInputs() {
    let allValid = true
    if (this._isEditing) {
      allValid = this.evalAndReport(['consumo', 'fechaDato'])
    } else if (this._isCreating) {
      allValid = this.evalAndReport([
        '_cliente',
        '_familia',
        '_year',
        'consumo',
        'fechaDato',
      ])
    }
    return allValid
  }

  evalAndReport(fieldList) {
    let allValid = true
    fieldList.forEach((field) => {
      const fieldHTML = this.template.querySelector(`[data-name='${field}']`)
      if (!this[field] || !fieldHTML?.checkValidity()) {
        fieldHTML?.reportValidity()
        allValid = false
      }
    })
    return allValid
  }
  // #endregion Aux functions
}

/**
 * @class name        : informeVisitaNuevo
 * @description       : Form to create a new visit report. For FFVV and ATD users. Common for both.
 * @author            : Rubén Sánchez González
 * @created on        : 13-09-2024
 * @last modified on  : 07-10-2024
 * @last modified by  : Rubén Sánchez González
 **/
import { LightningElement, api, wire } from 'lwc'
import { getRecord } from 'lightning/uiRecordApi'
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import UserId from '@salesforce/user/Id'
import gestorCuentaPermission from '@salesforce/customPermission/QUFV_cp_gestorCuenta'
import INFORME_OBJECT from '@salesforce/schema/QUFV_obj_informeVisita__c'
import MOTIVO_FIELD from '@salesforce/schema/QUFV_obj_informeVisita__c.QUATD_fld_motivo__c'
import IMPORTANCIA_FIELD from '@salesforce/schema/QUFV_obj_informeVisita__c.QUFV_fld_importancia__c'
import TIPO_REUNION_FIELD from '@salesforce/schema/QUFV_obj_informeVisita__c.QUFV_fld_tiporeunion__c'
import getProductos from '@salesforce/apex/QUFV_cls_informeVisitaNuevo_cc.getProductos'
import getAplicacion from '@salesforce/apex/QUFV_cls_informeVisitaNuevo_cc.getAplicacion'
import newInforme from '@salesforce/apex/QUFV_cls_informeVisitaNuevo_cc.newInforme'
import getVisitInfo from '@salesforce/apex/QUFV_cls_informeVisitaNuevo_cc.getVisitInfo'
import setInformeSent from '@salesforce/apex/QUFV_cls_informeVisitaNuevo_cc.updateInformeStatus'
import sendEmail from '@salesforce/apex/QUFV_cls_crearInformeVisita_cc.enviarEmail'

const FIELDS_ACCOUNT = ['Account.Name', 'Account.QUFV_fld_codigo__c']
const FIELDS_INFORME = [
  'QUFV_obj_informeVisita__c.QUFV_fld_eventSubject__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_cliente__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_fechaVisita__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_importancia__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_tiporeunion__c',
  'QUFV_obj_informeVisita__c.QUATD_fld_motivo__c',
  'QUFV_obj_informeVisita__c.QUATD_fld_resumen__c',
  'QUFV_obj_informeVisita__c.QUATD_fld_acciones__c',
  'QUFV_obj_informeVisita__c.QUATD_fld_usuarioAsociado__c',
  'QUFV_obj_informeVisita__c.QUATD_fld_palabrasClave__c',
  'QUFV_obj_informeVisita__c.QUATD_fld_asistentes__c',
  'QUFV_obj_informeVisita__c.QUATD_fld_productos__c',
  'QUFV_obj_informeVisita__c.QUATD_fld_aplicacion__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_negociation__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_market__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_recycleSustainability__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_technicalAdvice__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_feedback__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_logistic__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_administrative__c',
  'QUFV_obj_informeVisita__c.QUFV_fld_informeVisita__c',
  'QUFV_obj_informeVisita__c.OwnerId',
]
export { FIELDS_INFORME }

const TEMAS_TRATADOS = [
  {
    label: 'Negociación',
    name: 'negociation',
    apiName: 'QUFV_fld_negociation__c',
    iconName: 'utility:comments',
    placeholder: `Precios Repsol/ Volumen | Rappel | Información competencia | Situación oferta/ demanda`,
  },
  {
    label: 'Mercado',
    name: 'market',
    apiName: 'QUFV_fld_market__c',
    iconName: 'utility:cart',
    placeholder: `Sector que atienden | Situación de su demanda | Posición competencia | Clientes que atienden | Información sobre sus competidores directos`,
  },
  {
    label: 'Sostenibilidad/ Circularidad/ Reciclado',
    name: 'recycleSustainability',
    apiName: 'QUFV_fld_recycleSustainability__c',
    iconName: 'utility:rotate',
    placeholder: `Interés de clientes sobre productos circulares | Reducción CO2 | Mass-balance | Otros`,
  },
  {
    label: 'Asesoramiento técnico/ Homologaciones/ Desarrollo',
    name: 'technicalAdvice',
    apiName: 'QUFV_fld_technicalAdvice__c',
    iconName: 'utility:service_contract',
    placeholder: `Colaboraciones técnicas | Nuevos desarrollos | Homologaciones | Volúmenes potenciales`,
  },
  {
    label: 'Satisfacción/ Quejas/ Reclamaciones',
    name: 'satisfactionComplaints',
    apiName: 'QUFV_fld_feedback__c',
    iconName: 'utility:feed',
    placeholder: `Valoraciones sobre relación | Servicios | Entregas | Posición competencia | Registro de reclamaciones`,
  },
  {
    label: 'Aspectos logísticos',
    name: 'logistics',
    apiName: 'QUFV_fld_logistic__c',
    iconName: 'utility:rules',
    placeholder: `Información específica sobre algún tema relacionado con la logística o el servicio que necesitan `,
  },
  {
    label: 'Aspectos administrativos',
    name: 'administrative',
    apiName: 'QUFV_fld_administrative__c',
    iconName: 'utility:org_chart',
    placeholder: `Solicitud gestión temas administrativos (facturas, documentación, etc)`,
  },
  {
    label: 'Información adicional (general)',
    name: 'additionalInformation',
    apiName: 'QUFV_fld_informeVisita__c',
    iconName: 'utility:minimize_window',
    placeholder: `Información adicional que no se ajuste a las otras categorías`,
    lastItem: true,
  },
]
export { TEMAS_TRATADOS }

export default class InformeVisitaNuevoQU extends LightningElement {
  // #region variables
  @api informeId
  _informeId
  _clienteId
  @api
  get clienteId() {
    return this._clienteId
  }

  set clienteId(value) {
    this._clienteId = value
  }
  @api visitaId
  @api informeNew = false
  @api hideSubmit = false

  _listInformeRT
  _ownerId
  informe
  cliente
  asunto
  fechaVisita
  optionsImportancia = []
  optionsTipoReunion = []
  optionsMotivos = []
  optionsProducto = []
  optionsAplicacion = []
  importancia
  tipoReunion
  motivosOriginales = []
  motivos = []
  asistentes
  colaborador
  resumen
  acciones
  clave
  producto = []
  aplicacion
  visitaDisabled
  showEmail = false
  emailList

  // Temas tratados
  temasTratados = TEMAS_TRATADOS
  notPickedTema = false
  notAcciones = false
  notResumen = false
  negociation
  market
  recycleSustainability
  technicalAdvice
  satisfactionComplaints
  logistics
  administrative
  additionalInformation

  matchingInfo = {
    primaryField: { fieldPath: 'Name' },
    additionalFields: [{ fieldPath: 'QUFV_fld_codigoGestor__c' }],
  }
  matchingInfoCliente = {
    primaryField: { fieldPath: 'Name' },
    additionalFields: [{ fieldPath: 'QUFV_fld_codigo__c' }],
  }
  filterAccount = {
    criteria: [
      {
        fieldPath: 'RecordType.DeveloperName',
        operator: 'eq',
        value: 'RQO_rt_Solicitante',
      },
      {
        fieldPath: 'RecordType.DeveloperName',
        operator: 'eq',
        value: 'RQO_rt_Destinatario_de_Mercanc_as',
      },
    ],
    filterLogic: '(1 OR 2)',
  }
  // #endregion variables

  // #region wires
  @wire(getRecord, { recordId: '$informeId', fields: FIELDS_INFORME })
  informeData({ error, data }) {
    if (data) {
      this._informeId = this.informeId
      this.asunto = data.fields.QUFV_fld_eventSubject__c.value
      this.updateClienteId(data.fields.QUFV_fld_cliente__c.value)
      this.fechaVisita = data.fields.QUFV_fld_fechaVisita__c.value
      this.importancia = data.fields.QUFV_fld_importancia__c?.value
      this.tipoReunion = data.fields.QUFV_fld_tiporeunion__c?.value
      this.motivos = this.convertMultiPickToArray(
        data.fields.QUATD_fld_motivo__c?.value,
      )
      this.asistentes = data.fields.QUATD_fld_asistentes__c?.value
      this.resumen = data.fields.QUATD_fld_resumen__c.value
      this.acciones = data.fields.QUATD_fld_acciones__c.value
      this.clave = data.fields.QUATD_fld_palabrasClave__c.value
      if (this.isATD) {
        this.producto = this.convertMultiPickToArray(
          data.fields.QUATD_fld_productos__c?.value,
        )
        this.aplicacion = data.fields.QUATD_fld_aplicacion__c?.value
      }
      this._ownerId = data.fields.OwnerId.value
      this.fillColaborador(data.fields.QUATD_fld_usuarioAsociado__c?.value)
      this.temasTratados = this.fillAndCheckTemas(data)
      this.notifyEdit()
    } else if (error) {
      console.error('Error fetching informe data:', error)
    }
  }

  @wire(getRecord, { recordId: '$clienteId', fields: FIELDS_ACCOUNT })
  clienteData({ error, data }) {
    if (data) {
      this.cliente = data
      if (
        this.canEdit &&
        this.template.querySelector(`[data-name='cliente']`)?.value
      )
        this.template.querySelector(`[data-name='cliente']`).value =
          this.clienteId
    } else if (error) {
      console.error('Error fetching cliente data:', error)
    }
  }

  @wire(getObjectInfo, { objectApiName: INFORME_OBJECT })
  informeObjInfo({ error, data }) {
    if (data) {
      this._listInformeRT = data.recordTypeInfos
    } else if (error) {
      console.error('Error fetching informe object info:', error)
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: '$_informeRT',
    fieldApiName: MOTIVO_FIELD,
  })
  picklistMotivoResults(result) {
    this.handlePicklistValues(result, 'optionsMotivos')
  }

  @wire(getPicklistValues, {
    recordTypeId: '$_informeRT',
    fieldApiName: IMPORTANCIA_FIELD,
  })
  picklistImportanciaResults(result) {
    this.handlePicklistValues(result, 'optionsImportancia')
  }

  @wire(getPicklistValues, {
    recordTypeId: '$_informeRT',
    fieldApiName: TIPO_REUNION_FIELD,
  })
  picklistTipoReunionResults(result) {
    this.handlePicklistValues(result, 'optionsTipoReunion')
  }
  // #endregion wires

  // #region getters
  get isFFVV() {
    return gestorCuentaPermission
  }
  get isATD() {
    return !gestorCuentaPermission
  }

  get clienteName() {
    return this.cliente?.fields.Name.value
  }
  get clienteCode() {
    return this.cliente?.fields.QUFV_fld_codigo__c.value
  }
  get clienteFill() {
    return `${this.clienteCode} - ${this.clienteName}`
  }
  get clienteDisabled() {
    return !!this.cliente
  }
  get canEdit() {
    return (
      this.informeNew || UserId === this.colaborador || UserId === this._ownerId
    )
  }
  get isColaborador() {
    return UserId === this.colaborador
  }
  get _informeRT() {
    if (!this._listInformeRT) return null
    let rtName
    if (this.colaborador) {
      rtName = 'Informe Conjunto'
    } else if (this.isFFVV) {
      rtName = 'Informe FFVV'
    } else if (this.isATD) {
      rtName = 'Informe ATD'
    } else {
      return null
    }
    for (const value of Object.values(this._listInformeRT)) {
      if (value.name === rtName) {
        return value.recordTypeId
      }
    }
    return null
  }
  get loaded() {
    return this.canEdit || this._ownerId
  }
  // #endregion getters

  // #region handlers
  connectedCallback() {
    if (this.isATD) {
      getProductos()
        .then((result) => {
          this.optionsProducto = this.convertToLabelValueList(result)
        })
        .catch((error) => {
          console.error('Error fetching productos:', error)
        })
      getAplicacion()
        .then((result) => {
          this.optionsAplicacion = this.convertToLabelValueList(result)
        })
        .catch((error) => {
          console.error('Error fetching aplicacion:', error)
        })
    }
    if (this.visitaId) {
      getVisitInfo({ visitaId: this.visitaId })
        .then((result) => {
          this.asunto = result.Subject
          this.fechaVisita = result.StartDateTime
          this.visitaDisabled = true
          this.updateClienteId(result.AccountId)
        })
        .catch((error) => {
          console.error('Error fetching visita info:', error)
        })
    }
  }

  renderedCallback() {
    if (this.colaborador) {
      this.fillColaborador(this.colaborador)
    }
    if (this.informeNew) {
      this.notifyEdit(true)
    }
  }

  changeDefault(evt) {
    this[evt.target.name] = evt.detail.value
  }

  changeRecordPicker(evt) {
    this[evt.target.name] = evt.detail.recordId
  }

  handleCheckboxChange(event) {
    const temaName = event.target.name
    this.temasTratados = this.temasTratados.map((tema) => {
      if (tema.name === temaName) {
        if (!tema.warned && this[temaName] && !event.target.checked) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Texto no guardado',
              message:
                'Si desmarca el tema tratado se perderá el texto incluido.',
              variant: 'info',
            }),
          )
          event.target.checked = true
          return { ...tema, selected: true, warned: true, valid: true }
        }
        if (!event.target.checked) {
          this[temaName] = null
        }
        return {
          ...tema,
          selected: event.target.checked,
          warned: false,
          valid: true,
          value: this[temaName],
        }
      }
      return tema
    })
  }

  @api
  handleSave() {
    if (!this.validateInputs()) return false
    this.submitInforme()
    return true
  }

  @api
  handleSaveAndSend() {
    if (!this.validateInputs()) return false
    this.showEmail = true
    this.submitInforme()
    return true
  }

  captureEmailList(event) {
    this.emailList = event.detail.listEmail
  }

  @api
  sendEmail() {
    if (!this.emailList) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Email no enviado',
          message: 'Introduzca al menos un email para enviar el informe.',
          variant: 'error',
        }),
      )
      return
    }
    setInformeSent({ informeId: this._informeId })
    sendEmail({ eventoId: this._informeId, destinatarios: this.emailList })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Enviando email',
            message: 'El email se ha encolado para su envío.',
            variant: 'infor',
          }),
        )
        this.notifyParent(this.informeId)
      })
      .catch((error) => {
        console.error('Error sending email:', error)
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error al enviar',
            message: `Ha ocurrido un error al enviar el email: ${error}`,
            variant: 'error',
          }),
        )
      })
  }
  // #endregion handlers

  // #region aux methods
  updateClienteId(value) {
    if (this._clienteId === null) {
      this._clienteId = this._clienteId || value // do not override if already filled
    }
  }

  handlePicklistValues({ errors, data }, target) {
    if (data) {
      this[target] = Array.from(data.values).sort((a, b) => {
        if (a.label < b.label) {
          return -1
        }
        if (a.label > b.label) {
          return 1
        }
        return 0
      })
    } else if (errors) {
      console.error(`Error fetching ${target}:`, errors)
    }
  }

  validateInputs() {
    let allValid = true

    // standard validity
    const fields2Validate = [
      'asunto',
      'fechaVisita',
      'motivos',
    ]
    fields2Validate.forEach((field) => {
      if (!this[field] || !this[field][0]) {
        this.template.querySelector(`[data-name='${field}']`)?.reportValidity()
        allValid = false
      }
    })

    // custom validity temasTratados checkbox-group
    const anyTemaSelected = this.temasTratados.some((tema) => tema.selected);
    this.notPickedTema = !anyTemaSelected;
    allValid = allValid && anyTemaSelected;

    // custom validity temasTratados and input-rich-text
    this.temasTratados = this.temasTratados.map((tema) => {
      if (tema.selected && !this[tema.name]) {
        allValid = false
        return { ...tema, valid: false }
      }
      return { ...tema, valid: true }
    })

    this.notAcciones = !this.acciones
    this.notResumen = !this.resumen
    allValid = allValid && this.acciones && this.resumen

    if (!allValid) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Falta información',
          message:
            'Revise el formulario. Falta información obligatoria por rellenar.',
          variant: 'error',
        }),
      )
    }

    return allValid
  }

  submitInforme() {
    const params = JSON.stringify({
      informe: this.informeId,
      rtInforme: this._informeRT,
      cliente: this.clienteId,
      visita: this.visitaId,
      asunto: this.asunto,
      fechaVisita: this.fechaVisita,
      importancia: this.importancia,
      reunion: this.tipoReunion,
      motivos: Object.values(this.motivos).join(';'),
      asistentes: this.asistentes,
      colaborador: this.colaborador,
      resumen: this.resumen,
      acciones: this.acciones,
      clave: this.clave,
      productos: Object.values(this.producto).join(';'),
      aplicacion: this.aplicacion,
      negociation: this.negociation,
      market: this.market,
      recycleSustainability: this.recycleSustainability,
      technicalAdvice: this.technicalAdvice,
      satisfactionComplaints: this.satisfactionComplaints,
      logistics: this.logistics,
      administrative: this.administrative,
      additionalInformation: this.additionalInformation,
      isFFVV: this.isFFVV,
      isATD: this.isATD,
      enviado: false,
    })
    newInforme({ jsonParams: params })
      .then((result) => {
        console.log('Informe guardado con ID:', result)
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Informe guardado',
            message: 'El informe se ha guardado correctamente.',
            variant: 'success',
          }),
        )
        this._informeId = result
        this.notifyParent(result, !this.showEmail)
      })
      .catch((error) => {
        console.error('Error saving informe:', error)
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error al guardar',
            message: `Ha ocurrido un error al guardar el informe: ${error}`,
            variant: 'error',
          }),
        )
      })
  }

  fillAndCheckTemas(data) {
    return this.temasTratados.map((tema) => {
      const fieldValue = data.fields[tema.apiName]?.value
      if (fieldValue) {
        this[tema.name] = fieldValue
        return {
          ...tema,
          selected: true,
          warned: false,
          valid: true,
          value: fieldValue,
        }
      }
      return { ...tema, selected: false, warned: false }
    })
  }

  convertMultiPickToArray(input) {
    // Check if the input is a string
    if (typeof input !== 'string') {
      return []
    }
    // Split the input string by ';'
    return input.split(';') || []
  }

  convertToLabelValueList(inputObject) {
    const labelValueList = []
    for (const [key, value] of Object.entries(inputObject)) {
      labelValueList.push({ label: value, value: key })
    }
    return labelValueList
  }

  fillColaborador(value) {
    this.colaborador = value
    const colaboradorElement = this.template.querySelector(
      `[data-name='colaborador']`,
    )
    if (colaboradorElement && this.colaborador)
      colaboradorElement.value = this.colaborador
  }

  notifyParent(informeId, completed = true) {
    const newInformeEvent = new CustomEvent('newinforme', {
      detail: {
        informe: informeId,
        completed: completed,
      },
    })
    this.dispatchEvent(newInformeEvent)
  }

  notifyEdit(enable=false) {
    if (!this.canEdit && !enable) return
    const canEdit = new CustomEvent('canedit', {
      detail: {
        edit: this.canEdit || enable,
      },
    })
    this.dispatchEvent(canEdit)
  }
  // #endregion aux methods
}

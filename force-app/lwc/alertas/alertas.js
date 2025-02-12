/**
 * @class name        : alertas
 * @description       : LWC for showing alerts and enable user to active / deactive them
 * @author            : Rubén Sánchez González
 * @created on        : 20-01-2025
 * @last modified on  : 04-02-2025
 * @last modified by  : Rubén Sánchez González
 **/
import { LightningElement, api } from 'lwc'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation'
import getOptions from '@salesforce/apex/QUFV_cls_alertasConfig.getAlertOptions'
import getAlertUser from '@salesforce/apex/QUFV_cls_alertasConfig.getAlertUser'
import updateAlerts from '@salesforce/apex/QUFV_cls_alertasConfig.updateAlerts'

const CHECKED_ICON = 'utility:alert'
const UNCHECKED_ICON = 'utility:notification_off'
const ALL_CLIENTS = 'para todos los clientes de su cartera'
const THIS_CLIENT = 'exclusivamente para este cliente'

export default class AlertasFFVV extends NavigationMixin(LightningElement) {
  @api recordId // account id
  categories = []
  additionalText = ALL_CLIENTS
  loading = true
  disableSave = true
  modalViewing = false

  get fromClient() {
    return !!this.recordId
  }

  get labelSave() {
    return window.innerWidth < 768 ? 'Guardar' : 'Guardar cambios';
  }

  async connectedCallback() {
    await this.getAlertOptions()
    await this.getUserActivation()
    if (this.fromClient) {
      this.additionalText = THIS_CLIENT
    }
    this.loading = false
  }

  async getAlertOptions() {
    await getOptions()
      .then((result) => {
        console.log('result', result)
        this.categories = this.buildCategories(result)
      })
      .catch((error) => {
        console.error('error', error)
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error',
            message: 'Error al obtener las opciones de alerta',
            variant: 'error',
          }),
        )
      })
  }

  buildCategories(data) {
    const mapCategories = {}
    data.forEach((item) => {
      const category = item.QUFV_fld_categoria__c
      if (!mapCategories[category]) {
        mapCategories[category] = []
      }
      mapCategories[category].push({
        Id: null,
        QUFV_fld_categoria__c: item.QUFV_fld_categoria__c,
        DeveloperName: item.DeveloperName,
        Label: item.Label,
        QUFV_fld_nombreAlerta__c: item.QUFV_fld_nombreAlerta__c,
        QUFV_fld_tipo_alerta__c: item.QUFV_fld_tipo_alerta__c,
        QUFV_fld_cuenta__c: null,
        QUFV_fld_activo__c: false,
        icon: UNCHECKED_ICON,
        changed: false,
      })
    })

    const iterableCategories = Object.keys(mapCategories).map((key) => {
      return { key, values: mapCategories[key] }
    })

    return iterableCategories
  }

  getUserActivation() {
    getAlertUser({ accountId: this.recordId }).then((result) => {
      console.log('result', result)
      this.updateCategories(result)
    })
  }

  updateCategories(data) {
    data.forEach((item) => {
      const category = item.QUFV_fld_categoria__c
      const tipoAlerta = item.QUFV_fld_tipo_alerta__c

      const categoryObj = this.categories.find((cat) => cat.key === category)
      if (categoryObj) {
        const row = categoryObj.values.find(
          (elem) => elem.QUFV_fld_tipo_alerta__c === tipoAlerta,
        )
        if (row) {
          row.Id = item.Id
          if (this.fromClient) row.QUFV_fld_cuenta__c = this.recordId
          row.QUFV_fld_activo__c = item.QUFV_fld_activo__c
          row.icon = row.QUFV_fld_activo__c ? CHECKED_ICON : UNCHECKED_ICON
        }
      }
    })
    this.categories = [...this.categories]
  }

  handleCheck(evt) {
    const tipoAlerta = evt.currentTarget.dataset.name
    const category = evt.currentTarget.dataset.category

    // Find the specific category
    const categoryObj = this.categories.find((cat) => cat.key === category)
    if (categoryObj) {
      // Find the specific row within the category
      const row = categoryObj.values.find(
        (item) => item.QUFV_fld_tipo_alerta__c === tipoAlerta,
      )
      if (row) {
        // Toggle the selected state and update the icon
        row.QUFV_fld_activo__c = !row.QUFV_fld_activo__c
        row.QUFV_fld_cuenta__c = this.fromClient ? this.recordId : null
        row.icon = row.QUFV_fld_activo__c ? CHECKED_ICON : UNCHECKED_ICON
        row.changed = true
      }
    }

    // Update the categories to trigger reactivity
    this.categories = [...this.categories]
    this.disableSave = false
  }

  showModal() {
    this.modalViewing = true
  }

  hideModal() {
    this.modalViewing = false
  }

  handleSave() {
    this.modalViewing = false
    this.disableSave = true

    // Build a list of values that have the changed attribute==true
    const valuesChanged = this.categories.reduce((acc, category) => {
      const changedItems = category.values.filter((item) => item.changed)
      return acc.concat(changedItems)
    }, [])

    updateAlerts({
      accountId: this.recordId,
      alertsChanged: valuesChanged,
    })
      .then((result) => {
        if (result) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Configuración guardada',
              message: 'Alertas actualizadas correctamente',
              variant: 'success',
            }),
          )
          // turn changed param to false
          this.categories.forEach((category) => {
            category.values.forEach((item) => {
              item.changed = false
            })
          })
        } else
          this.showError(
            'Error al actualizar las alertas, por favor contacte con su administrador',
          )
      })
      .catch((error) => {
        this.showError(error.body.message)
      })
      .finally(() => {
        // reload from DB after saving
        this.getUserActivation()
      })
  }

  showError(error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Error',
        message: error,
        variant: 'error',
      }),
    )
  }

  goToGeneral() {
    this[NavigationMixin.Navigate]({
      type: 'standard__navItemPage',
      attributes: {
        appTarget: 'QUFV_tab_Alertas',
      },
    })
  }
}

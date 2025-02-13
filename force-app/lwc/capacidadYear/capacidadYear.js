/**
 * @class name        : capacidadYear
 * @description       : List of the years of capacities of the client.
 * @author            : Rubén Sánchez González
 * @created on        : 14-10-2024
 * @last modified on  : 17-12-2024
 * @last modified by  : Rubén Sánchez González
 **/
import { LightningElement, api, wire, track } from 'lwc'
import { CurrentPageReference } from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import gestorCuentaPermission from '@salesforce/customPermission/QUFV_cp_gestorCuenta'
import getCapacidades from '@salesforce/apex/capacidad.getCapacidades'
import modalCapacidad from 'c/capacidadDetail'

export default class CapacidadYears extends LightningElement {
  @api recordId
  @api mobileRender
  @track navigationData = []
  @track capacidades = []
  @track initiallySelected
  @track currentContent
  loading = true
  loadedCapacidad = false
  capacidadesOfYear
  areCapacidades = false
  selectedCapacidad
  @track persistExpanded = []
  excelYearSelector = false
  sections = []
  valuesYears = []
  optionsFamilies = []
  valuesFamilies = []
  includeSUMI

  @wire(CurrentPageReference) currentPageReference

  // #region handlers
  connectedCallback() {
    getCapacidades({ clientId: this._recordId })
      .then((result) => {
        if (!result || !result[0]) {
          console.log('Sin capacidades existentes')
          return
        }
        this.areCapacidades = true
        this.capacidades = result
        const yearsSet = new Set()
        const familiesSet = new Set()
        result.forEach((capacidad) => {
          yearsSet.add(capacidad.QUFV_fld_year__c)
          familiesSet.add(capacidad.QUFV_fld_family__c)
        })
        this.buildSections([...yearsSet])
        this.optionsFamilies = [...familiesSet].map((family) => {
          return { label: family, value: family }
        })
        this.valuesFamilies = [...familiesSet]
        this.setCapacidadesSubset()
      })
      .catch((data) => {
        console.error('Error getting capacities:', data)
      })
      .finally(() => {
        this.loading = false
      })
  }

  buildSections(yearsList) {
    const sections = []
    yearsList.forEach((year) => {
      sections.push({
        label: year,
        name: `year${year}`,
        value: `${year}`,
      })
      this.valuesYears.push(`${year}`)
    })
    this.navigationData = null
    this.navigationData = [{ label: 'Capacidades por año', items: sections }]
    this.initiallySelected = sections[0]?.name
    this.currentContent ??= this.initiallySelected.substring(4)
    this.sections = sections
  }

  handleSelect(event) {
    const selected = event.detail.name.substring(4)
    if (!selected) return
    this.currentContent = selected
    this.setCapacidadesSubset()
  }

  setCapacidadesSubset() {
    this.capacidadesOfYear = []
    if (!this.isMobile)
      this.template.querySelector('c-qufv_lwc_capacidad-tree')?.collapseAll()
    this.capacidadesOfYear = JSON.parse(
      JSON.stringify(
        this.capacidades.filter((capacidad) => {
          return String(capacidad.QUFV_fld_year__c) === this.currentContent
        }),
      ),
    )
    this.loadedCapacidad = true
    this.template
      .querySelector('c-qufv_lwc_capacidad-tree')
      ?.setCapacidades(this.capacidadesOfYear)
  }

  expandAll() {
    this.template.querySelector('c-qufv_lwc_capacidad-tree')?.expandAll()
  }
  collapseAll() {
    this.template.querySelector('c-qufv_lwc_capacidad-tree')?.collapseAll()
  }

  handleNewClick() {
    this.selectedCapacidad = null // ensure not capacity is selected
    this.openModal({ action: 'new' })
  }

  treeButtonPressed(event) {
    this.selectedCapacidad = event.detail.capacidadId
    const details = event.detail

    this.openModal(details)
  }

  async openModal(capacidad) {
    const result = await modalCapacidad.open({
      size: 'medium',
      description: 'Modal de detalle de capacidad',
      content: 'c-qufv_lwc_capacidad-detail',
      capacidadId: this.selectedCapacidad,
      cliente: this._recordId,
      year: this.currentContent,
      familia: capacidad.family,
      action: capacidad.action,
      manual: capacidad.cantidadManual,

      onedited: (e) => {
        e.stopPropagation()
      },
    })

    if (result && result !== 'canceled') {
      this.persistExpanded = this.template
        .querySelector('c-qufv_lwc_capacidad-tree')
        ?.getExpandedRows()
      this.connectedCallback() // reload data
      if (capacidad.action === 'deleteAll') {
        window.location.reload()
      }
    }
  }

  handleExcel() {
    let capacidadesFiltered = this.capacidades.filter((capacidad) => {
      return this.valuesYears.includes(String(capacidad.QUFV_fld_year__c))
    })
    capacidadesFiltered = capacidadesFiltered.filter((capacidad) => {
      return this.valuesFamilies.includes(String(capacidad.QUFV_fld_family__c))
    })

    if (!capacidadesFiltered.length) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'No existen datos',
          message: 'No hay datos de capacidades para la combinación de años y familias indicada.',
          variant: 'error',
        }),
      )
      return
    }

    let data = this.template
      .querySelector('c-qufv_lwc_capacidad-tree')
      .getFormattedData(capacidadesFiltered)
      .map((item) => {
        const newItem = { ...item }
        for (const key in newItem) {
          // make boolean values readable
          if (newItem[key] === true) {
            newItem[key] = 'SÍ'
          }
        }
        return newItem
      })
    if (!this.includeSUMI) {
      data = data.filter((row) => {
        return row.parentRow
      })
    }
    let columns = this.template
      .querySelector('c-qufv_lwc_capacidad-tree')
      .getColumns()
    columns = columns.slice(0, columns.length - 1) // remove the last column (actions)
    const columnsPreExcel = [
      {
        label: 'Año',
        fieldName: 'QUFV_fld_year__c',  
        type: 'number',
        sortable: true,
      },
    ]
    const columnsPostExcel = [
      {
        label: 'Comentarios',
        fieldName: 'QUFV_fld_comments__c',
        type: 'text',
        sortable: true,
      },
    ]
    const columnTotalOnlyMain = {
      label: 'Capacidad de compra cabecera',
      fieldName: 'totalConsumo',
      type: 'number',
      sortable: true,
    }
    columns = [...columnsPreExcel, ...columns, ...columnsPostExcel]
    // add column after column fieldName:'consumo'
    const index = columns.findIndex(column => column.fieldName === 'consumo');
    if (index !== -1 && this.includeSUMI) {
        columns.splice(index + 1, 0, columnTotalOnlyMain);
    }
    
    this.hideExcelYearSelector()
    const fileName = `Cap ${data[0].clienteName.substring(0, 22)}`
    this.template
      .querySelector('c-qutt_lwc_download-excel')
      .exportXLSX(data, columns, true, fileName)
  }

  showExcelYearSelector() {
    this.excelYearSelector = true
  }

  hideExcelYearSelector() {
    this.excelYearSelector = false
  }

  handleExcelSelector(evt) {
    this[evt.target.name] = evt.target.value
  }
  handleExcelCheck(evt) {
    this[evt.target.name] = evt.target.checked
  }
  // #endregion handlers

  // #region getters
  get _recordId() {
    return this.recordId || this.currentPageReference?.attributes?.recordId
  }

  get isFFVV() {
    return gestorCuentaPermission
  }

  get isATD() {
    return !gestorCuentaPermission
  }

  get isMobile() {
    const userAgent = navigator.userAgent || navigator.vendor || window.opera
    return this.mobileRender || /android|ipad|iphone|ipod/i.test(userAgent)
  }
  // #endregion getters
}

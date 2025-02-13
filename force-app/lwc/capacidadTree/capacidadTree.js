/**
 * @class name        : capacidadTree
 * @description       : Table of capacities for client for the given year.
 * @author            : Rubén Sánchez González
 * @created on        : 14-10-2024
 * @last modified on  : 17-12-2024
 * @last modified by  : Rubén Sánchez González
 **/
import { LightningElement, api } from 'lwc'

// #region constants
export const CAPACITY_ICON = 'utility:cart'
export const SALES_ICON = 'utility:insert_template'
export const DELETE_ICON = 'utility:delete'
const _SPACE = '\u00A0'

export const COLUMNS_TREE_GRID = [
  {
    type: 'text',
    fieldName: 'familia',
    label: 'Familia/ Producto',
    initialWidth: 200,
  },
  {
    type: 'url',
    fieldName: 'clienteLink',
    label: 'Cliente',
    typeAttributes: {
      label: { fieldName: 'clienteName' },
    },
    initialWidth: 200,
    wrapText: true,
  },
  {
    type: 'number',
    fieldName: 'ventas',
    label: 'Ventas (ton)',
    sortable: true,
    cellAttributes: {
      iconName: { fieldName: 'ventasIcon' },
    },
  },
  {
    type: 'number',
    fieldName: 'consumo',
    label: 'Capacidad de compra (ton)',
    sortable: true,
    cellAttributes: {
      iconName: { fieldName: 'consumoIcon' },
    },
  },
  {
    type: 'number',
    fieldName: 'cuota',
    label: 'Cuota Repsol',
    sortable: true,
    cellAttributes: {
      iconName: 'utility:percent',
      iconPosition: 'right',
    },
  },
  {
    type: 'date-local',
    fieldName: 'fechaDato',
    label: 'Fecha revisión dato',
    initialWidth: 135,
  },
  {
    type: 'text',
    fieldName: 'competidores',
    label: 'Competidores',
    wrapText: true,
  },
]

export const ACTION_ROWS_CHILD = [
  {
    label: 'Más detalles',
    name: 'show_details',
    iconName: 'utility:info_alt',
  },
  {
    label: 'Editar',
    name: 'edit',
    iconName: 'utility:edit',
  },
  {
    label: 'Eliminar registro',
    name: 'delete',
    iconName: DELETE_ICON,
  },
]

export const ACTION_ROWS_PARENT = [
  {
    label: 'Borrar datos familia',
    name: 'deleteAll',
    iconName: DELETE_ICON,
  },
]

// #endregion constants

export default class CapacidadTree extends LightningElement {
  @api year
  @api capacidades
  @api gridExpandedRows

  gridColumns
  gridData
  datatableData
  capacidadId
  family
  cantidadManual
  get isCurrentYear() {
    const currentYear = new Date().getFullYear()
    const currentMonth = new Date().getMonth() // 0-based index (0 = January, 1 = February, ..., 11 = December)
    // Check if the year is the current year or the next year up to February
    return (
      this.year === String(currentYear) ||
      (this.year === String(currentYear + 1) && currentMonth <= 1)
    )
  }

  get isMobile() {
    const userAgent = navigator.userAgent || navigator.vendor || window.opera
    return /android|ipad|iphone|ipod/i.test(userAgent)
  }

  capacityIcon = CAPACITY_ICON
  salesIcon = SALES_ICON

  // #region Functions
  async connectedCallback() {
    await this.setCapacidades()
    await this.setColumns()
  }

  setColumns() {
    this.gridColumns = [
      ...COLUMNS_TREE_GRID,
      {
        type: 'action',
        typeAttributes: { rowActions: this.getRowActions.bind(this) },
      },
    ]
  }

  getRowActions(row, doneCallback) {
    let actions
    if (row.parentRow) {
      actions = [...ACTION_ROWS_CHILD, ...ACTION_ROWS_PARENT]
    } else {
      actions = ACTION_ROWS_CHILD
    }
    doneCallback(actions)
  }

  @api
  setCapacidades(capacidades) {
    let dataRow = this.buildCapacidadesTree(capacidades)
    this.gridData = dataRow
    this.datatableData = this.flattenData(dataRow)
  }

  buildCapacidadesTree(capacidades) {
    if (!this.capacidades && !capacidades) return null
    let fullData = capacidades || this.capacidades
    let dataRow = []
    fullData.map((capacidad) => {
      let mainRow = dataRow.find(
        (row) =>
          String(row.familia) === capacidad.QUFV_fld_family__c &&
          String(row.QUFV_fld_year__c) === String(capacidad.QUFV_fld_year__c),
      )

      if (!mainRow) {
        mainRow = this.createMainRow(capacidad)
        dataRow.push(mainRow)
      }

      mainRow = this.updateMainRow(mainRow, capacidad)
      if (capacidad.QUFV_fld_sumi__r?.Id) {
        mainRow._children ??= []
        mainRow._children.push(this.createChildRow(capacidad))
      }

      return mainRow
    })

    return dataRow
  }

  @api
  expandAll() {
    const grid = this.template.querySelector('lightning-tree-grid')
    grid.expandAll()
  }

  @api
  collapseAll() {
    const grid = this.template.querySelector('lightning-tree-grid')
    grid.collapseAll()
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name
    const row = event.detail.row
    this.capacidadId = row.Id
    this.family = row.familia
    this.cantidadManual = row.consumo

    this.notifyParent(actionName)
  }

  notifyParent(action = 'show_details') {
    const showRecordCapacidad = new CustomEvent('showrecord', {
      detail: {
        capacidadId: this.capacidadId,
        action: action,
        family: this.family,
        cantidadManual: this.cantidadManual,
      },
    })
    this.dispatchEvent(showRecordCapacidad)
  }

  @api
  getExpandedRows() {
    if (this.isMobile) return null
    const grid = this.template.querySelector('lightning-tree-grid')
    return [...grid.getCurrentExpandedRows()]
  }

  @api
  getFormattedData(capacidad) {
    let dataCapacidades = this.buildCapacidadesTree(capacidad)
    return this.flattenData(dataCapacidades)
  }

  @api
  getColumns() {
    return this.gridColumns
  }
  // #endregion Functions

  // #region Aux functions
  createMainRow(capacidad) {
    return {
      key: capacidad.QUFV_fld_family__c,
      familia: capacidad.QUFV_fld_family__c,
      clienteName: capacidad.QUFV_fld_account__r.Name,
      clienteLink: `/lightning/r/Account/${capacidad.QUFV_fld_account__r.Id}/view`,
      QUFV_fld_year__c: capacidad.QUFV_fld_year__c,
      ventas: 0,
      consumo: 0,
      fechaDato: '-',
      competidores: '',
      parentRow: true,
      consumoIcon: CAPACITY_ICON,
      ventasIcon: SALES_ICON,
    }
  }

  updateMainRow(mainRow, capacidad) {
    const fromCabecera = !capacidad.QUFV_fld_sumi__r?.Id
    if (fromCabecera) {
      mainRow.Id = capacidad.Id
      mainRow.Name = capacidad.Name
      mainRow.consumo = capacidad.QUFV_fld_anualConsumption__c
      mainRow.totalConsumo = mainRow.consumo
      mainRow.ventas = capacidad.QUFV_fld_consolidatedSales__c
      mainRow.fechaDato = capacidad.QUFV_fld_lastModifiedDate__c
      mainRow.cuota = this.getCuota(mainRow.ventas, mainRow.consumo)
    }
    mainRow.cuota = this.getCuota(mainRow.ventas, mainRow.consumo)

    const competitorsSet = new Set(
      mainRow.competidores ? mainRow.competidores.split(', ') : [],
    )
    if (capacidad.QUFV_fld_competitors__c) {
      capacidad.QUFV_fld_competitors__c.split(', ').forEach((competitor) =>
        competitorsSet.add(competitor),
      )
    }
    mainRow.competidores = Array.from(competitorsSet).join(', ')
    return mainRow
  }

  createChildRow(capacidad) {
    const client = capacidad.QUFV_fld_sumi__r?.Id
      ? capacidad.QUFV_fld_sumi__r
      : capacidad.QUFV_fld_account__r
    return {
      ...capacidad,
      key: `${capacidad.QUFV_fld_family__c}-${capacidad.Id}`,
      familia: `${_SPACE} ${capacidad.QUFV_fld_family__c} (${client.RecordType.Name})`,
      clienteName: `${_SPACE}${_SPACE} ${client.Name}`,
      clienteLink: `/lightning/r/Account/${client.Id}/view`,
      ventas: capacidad.QUFV_fld_consolidatedSales__c,
      consumo: capacidad.QUFV_fld_anualConsumption__c,
      cuota: this.getCuota(
        capacidad.QUFV_fld_consolidatedSales__c,
        capacidad.QUFV_fld_anualConsumption__c,
      ),
      fechaDato: capacidad.QUFV_fld_lastModifiedDate__c,
      competidores: capacidad.QUFV_fld_competitors__c,
    }
  }

  getCuota(num, denom) {
    if (!denom) return '0.00' // avoid division by 0
    return ((num / denom) * 100).toFixed(2)
  }

  flattenData(data, parentId = null) {
    let flatData = []
    data.forEach((item) => {
      let newItem = { ...item }
      delete newItem._children
      newItem.parentId = parentId
      flatData.push(newItem)
      if (item._children) {
        flatData = flatData.concat(this.flattenData(item._children, item.id))
      }
    })
    return flatData
  }
  // #endregion Aux functions
}

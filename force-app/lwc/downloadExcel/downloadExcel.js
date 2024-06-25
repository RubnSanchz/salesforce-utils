/**
 * @class name        : qutt_lwc_downloadExcel
 * @description       : Método de descarga a excel de un datatable
 * @usage             : View force-app/lwc/downloadExcel/usage.md
 * @author            : Rubén Sánchez González
 * @created on        : 27-02--2024
 * @last modified on  : 06-06-2024
 * @last modified by  : Rubén Sánchez González
 **/
import { LightningElement, api } from 'lwc'
import { loadScript } from 'lightning/platformResourceLoader'
import xlsxResource from '@salesforce/resourceUrl/REP_sr_xlsx'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

const DATE_RESERVED_WORDS = ['F.', 'Fecha']
const TIME_RESERVED_WORDS = ['Hora']

export default class DownloadExcelQUTT extends LightningElement {
	connectedCallback() {
		loadScript(this, xlsxResource + '/xlsx.full.min.js')
	}

	// #region Main
	@api
	exportXLSX(data, columns, showToggle = true, docName = 'Albaranes') {
		if (showToggle) {
			const event = new ShowToastEvent({
				title: 'Descargando',
				message: 'Descargando fichero Excel de la vista actual',
			})
			this.dispatchEvent(event)
		}

		const d = new Date()
		const documentName = `${docName} ${d.getFullYear()}-${
			d.getMonth() + 1
		}-${d.getDate()}.xlsx`
		const columnLabels = columns.map((col) => col.label)
		const columnKeys = columns.map((col) =>
			col.type !== 'url' ? col.fieldName : col.typeAttributes.label.fieldName,
		)
		const dataProcessed = data.map((elem) =>
			this.processRow(elem, columnLabels, columnKeys),
		)

		const sheet = XLSX.utils.json_to_sheet(dataProcessed)
		const workbook = XLSX.utils.book_new()
		XLSX.utils.book_append_sheet(workbook, sheet, docName)

		this.disableDownload = false
		return XLSX.writeFileXLSX(workbook, documentName)
	}
	// #endregion Main

	// #region Auxiliar functions
	refactor(arg) {
		return JSON.parse(JSON.stringify(arg))
	}

	formatTimeIfValid(value) {
		let hours = Math.floor(value / (1000 * 60 * 60))
		let minutes = Math.floor((value % (1000 * 60 * 60)) / (1000 * 60))
		let seconds = Math.floor((value % (1000 * 60)) / 1000)

		if (
			this.isInRange(hours, 0, 24) &&
			this.isInRange(minutes, 0, 60) &&
			this.isInRange(seconds, 0, 60)
		) {
			return `${hours.toString().padStart(2, '0')}:${minutes
				.toString()
				.padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
		}

		return value
	}

	formatDateIfValid(value) {
		if (value) {
			let parts = value.split('-')
			if (parts.length === 3) return `${parts[2]}-${parts[1]}-${parts[0]}`
		}
		return value
	}

	isInRange(value, min, max) {
		return value >= min && value < max
	}

	checkReservedWords(value, reservedWords) {
		return reservedWords.some((word) =>
			value.toLowerCase().includes(word.toLowerCase()),
		)
	}

	processRow(elem, columnLabels, columnKeys) {
		let row = {}
		for (let index = 0; index < columnLabels.length; index++) {
			let val = elem[columnKeys[index]] // Default, just pick value stored on the object

			// Convert to date if it's a date
			if (this.checkReservedWords(columnLabels[index], DATE_RESERVED_WORDS))
				val = this.formatDateIfValid(val)
			// Convert to time if it's a time
			if (this.checkReservedWords(columnLabels[index], TIME_RESERVED_WORDS))
				val = typeof val === 'number' ? this.formatTimeIfValid(val) : val

			row[columnLabels[index]] = val || ' '
		}
		return row
	}
	// #endregion Auxiliar functions
}

/**
 * @class name        : ListViewEnhanced.js
 * @description       : Muestra una lista mejorada de registros. Imita a las list views permitiendo varios niveles de profundidad en listas y funcionalidades custom
 * @author            : Rubén Sánchez González
 * @created on        : 23-09-2022
 * @last modified on  : 08-03-2023
 * @last modified by  : Rubén Sánchez González
 * @controller class  : none
**/
import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import xlsxResource from '@salesforce/resourceUrl/REP_sr_xlsx';

import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';
import USER_PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import USER_ROLE_NAME from '@salesforce/schema/User.UserRole.Name';

const SHOW = 'slds-show';
const HIDE = 'slds-hide';
export default class ListViewEnhanced extends NavigationMixin(LightningElement) {

    @api columns = [];
    @api records = [];
    
    @api objectName = 'Obj. Name default';
    @api headerContent = 'Header default';
    @api iconName;
    @api overtablemessage;
    @api errorMessage;
    @api recordsFullAmount;
    
    @api enableInfiniteScroll;
    @api customSorting;
    @track loading = false;    
    @track loadingTable = false;
    @track showModal = HIDE;
    @track showCollapsible = HIDE;

    get numRecord() {
        return this.records?.length;
    }

    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAME,USER_PROFILE_NAME,USER_ROLE_NAME]}) 
    userDetails({error, data}) {
        if (data) {
            this.dispatchEvent(
                new CustomEvent("getuserdata", { detail: {
                    Id      : USER_ID,
                    Name    : data?.fields?.Name?.value,
                    ProfName: data?.fields?.Profile?.value?.fields?.Name?.value,
                    RoleName: data?.fields?.UserRole?.value?.fields?.Name?.value
                } }) 
            );
        } else if (error) {
            console.log('Error: '+error?.body?.message);
        }
    }

    connectedCallback() {
        loadScript(this, xlsxResource + '/xlsx.full.min.js');
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        this.dispatchEvent(
            new CustomEvent("sort", { detail: {
                sortField : this.sortBy,
                sortDirec : this.sortDirection
            } }) 
        );
        if (this.customSorting) return;
        let parseData = this.refactor(this.records);
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.records = parseData;
    }

    loadMoreData() {
        this.dispatchEvent(
            new CustomEvent("requestmoredata", { detail: true }) 
        );
    }

    closeModal() {
        this.toggleModal(false);
    }

    @api
    toggleModal(statusOpen = true) {
        this.showModal = statusOpen? SHOW : HIDE;
    }

    @api
    toggleCollapsible(statusOpen = true) {
        this.showCollapsible = statusOpen? SHOW : HIDE;
    }
    
    @api
    toggleLoading(statusOpen = true) {
        this.loading = statusOpen;
    }

    @api
    toggleTableSpinner(statusOpen = true) {
        this.loadingTable = statusOpen;
    }
    
    @api
    moveToTop() {
        const topDiv = this.template.querySelector('[data-id="topPage"]');
        topDiv.scrollIntoView({behavior: "smooth", block: "center", inline: "nearest"});
    }

    @api
    exportCSV( columns = this.refactor(this.columns), records = this.refactor(this.records), showToggle = true ){
        if (showToggle) {
            const event = new ShowToastEvent({
                title: 'Descargando',
                message: 'Descargando fichero CSV de la vista actual',
            });
            this.dispatchEvent(event);
        }

        const documentName = this.headerContent;
        const colRefact = columns&&columns[0]? columns: this.refactor(this.columns)
        let csv = this.convertArrayOfObjectsToCSV(colRefact, records);
        let d = new Date();

        let link = window.document.createElement("a");
        link.setAttribute("href", "data:text/csv;charset=utf-8,%EF%BB%BF" + encodeURI(csv));
        link.setAttribute("download", documentName + ' ' + d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate() + '.csv');
        link.click();
    }

    convertArrayOfObjectsToCSV(columns, records) {
        const normalizeStrings = (data) => {
            let normalString = [];
            data.forEach(d => normalString.push(
                d.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
            ));
            return normalString;
        }

        const columnLabels = normalizeStrings(columns.map(foo => foo.label));
        const columnKeys   = columns.map(foo => foo.type !='url'? foo.fieldName : foo.typeAttributes.label.fieldName);
        const data         = this.template.querySelector("lightning-datatable").getSelectedRows()[0]? this.template.querySelector("lightning-datatable").getSelectedRows() : records;
        let csvStringResult = '', counter, columnDivider = ';', lineDivider = '\n';
        csvStringResult += columnLabels.join(columnDivider);
        csvStringResult += lineDivider;
        for (let i = 0; i < data.length; i++) {
            counter = 0;
            for (let sTempkey in columnKeys) {
                if (!columnKeys.hasOwnProperty(sTempkey)) {
                    continue;
                }
                let skey = columnKeys[sTempkey];
                if (counter > 0) {
                    csvStringResult += columnDivider;
                }

                csvStringResult += this.getcsvStringValue(data[i][skey]);
                counter++;
            }
            csvStringResult += lineDivider;
        }
        return csvStringResult;
    }

    getcsvStringValue(data) {
        let value = '';
        if (data===true) {
            value = 'Sí';
        } else if (data===false) {
            value = 'No';
        } else if (data!==null) {
            value = data;
        }
        return value;
    }

    @api
    exportXLSX( columns = this.refactor(this.columns), records = this.refactor(this.records), showToggle = true ){
        if (showToggle) {
            const event = new ShowToastEvent({
                title: 'Descargando',
                message: 'Descargando fichero Excel de la vista actual',
            });
            this.dispatchEvent(event);
        }

        const d = new Date();
        const documentName  = this.headerContent+ ' ' + d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate() + '.xlsx';
        const _colRefact    = columns&&columns[0]? columns: this.refactor(this.columns)
        const _columnLabels = _colRefact.map(col => col.label);
        const _columnKeys   = _colRefact.map(col => col.type !='url'? col.fieldName : col.typeAttributes.label.fieldName);
        let   _data         = this.template.querySelector("lightning-datatable").getSelectedRows()[0]? this.template.querySelector("lightning-datatable").getSelectedRows() : records;
        const dataProcessed = _data.map( elem => {
            let row = {};
            for (let index = 0; index < _columnLabels.length; index++) {
                row[_columnLabels[index]] = elem[_columnKeys[index]] || " ";
            }
            return row
        })

        const sheet = XLSX.utils.json_to_sheet( dataProcessed );
        const workbook = XLSX.utils.book_new();

        XLSX.utils.book_append_sheet(workbook, sheet, this.objectName);

        this.disableDownload = false
        return XLSX.writeFileXLSX(
            workbook,
            documentName
        );

    }
    
    eventRefeshView() {
        this.dispatchEvent(
            new CustomEvent("refreshview", { detail: true }) 
        );
    }

    refactor(arg){
        return JSON.parse(JSON.stringify(arg))
    }

    @api
    getSelectedRows(){
      return JSON.parse(JSON.stringify( this.template.querySelector("lightning-datatable").getSelectedRows() ));
    }

}
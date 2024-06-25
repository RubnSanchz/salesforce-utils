# How to import and use this component

> [!WARNING]
> The static resource needs to be downloaded and imported in environment previously.
> Route: [text](../../staticResources/REP_sr_xlsx.zip)

<br>

It has to be embeeded on another component, for example a datatable component and be called through JS to its @api function decorated.
This is an example on code to be inserted on the parent component.

``` html
<c-download-excel></c-download-excel>
<lightning-button-icon-stateful 
    icon-name="utility:download" 
    alternative-text="Exportar a Excel"
    onclick={handleIconExcel} class="slds-m-left_medium">
</lightning-button-icon-stateful>
```

``` js
handleIconExcel() {
    // Retrieve the data to download
    const recordsSelected = this.template
        .querySelector('c-monitor')
        .getSelectedRows()
    const allRecords = this.template
        .querySelector('c-monitor')
        .getFilteredRecords()
    const data = recordsSelected.length > 0 ? recordsSelected : allRecords
    const columns = this.template
        .querySelector('c-monitor')
        .getColumns()
        .slice(1) //Slice to remove 'Textos' column

    this.template
        .querySelector('c-download-excel')
        .exportXLSX(data, columns)
}
```

/* 
  * Description: NodeJS para calcular los previso de las órdenes de servicio. Recupera de BBDD el estado actual de los registros.
  * Usage: node recalculatePrices.mjs -f <fichero_input> [-o <offset_query>]
  * Results: results/<fichero_input>-documentumId.csv
*/

import {
    createReadStream,
    mkdirSync,
    createWriteStream,
    readFileSync,
} from 'fs'

import csv from 'csv-parser'
import { parse } from 'json2csv'
import { globSync } from 'glob'

import yargs from 'yargs/yargs'
import { hideBin } from 'yargs/helpers'
import { exec } from 'child_process';
import { getSystemErrorMap } from 'util'

const reset = "\x1b[0m";
const bgGray = "\x1b[47m";
const fgCyan = "\x1b[36m";
const bgCyan = "\x1b[46m";

const argv = yargs(hideBin(process.argv))
    .option('file', {
        alias: 'f',
        describe: 'Input File',
        type: 'string',
        requiresArg: false,
        required: false,
    })
    .option('offset', {
        alias: 'o',
        describe: 'Offset para la Query',
        type: 'string',
        requiresArg: false,
        required: false,
    })
    .parseSync()


const FOLDER_SOURCE = 'Notes/source'
const FOLDER_RESULT = 'Notes/results'
mkdirSync(FOLDER_SOURCE, { recursive: true })
mkdirSync(FOLDER_RESULT, { recursive: true })
const targetFile = `${FOLDER_SOURCE}/presupuestos-input.csv`
const writeStream = createWriteStream(`${FOLDER_RESULT}/presupuestos-toUpdate.csv`)

function doCommand(comando) {
    return new Promise((resolve, reject) => {
        exec(comando, (error, stdout, stderr) => {
            if (error) {
                reject(`Error: ${error}`)
            } else {
                resolve(stdout)
            }
        });
    });
}

const QUERY_ALL = `SELECT Id, CPSVA_fld_importeFactura__c, CPSVA_fld_importeTotalOrden__c, CPSVA_fld_precioTotalCliente__c, CPSVA_fld_precioTotalbusiness__c,
            (SELECT CPSVA_fld_precioTotal__c, CPSVA_fld_importeTotalConIVA__c FROM ProductRequests),
            (SELECT CPSVA_fld_esDelCliente__c, CPSVA_fld_precio__c, CPSVA_fld_importeConIVA__c FROM ProductRequestLineItems WHERE CPSVA_fld_activo__c = true)`
const QUERY_COUNT = 'SELECT count(Id)'
const QUERY_FROM  = ' FROM WorkOrder WHERE RecordType.Developername = \'CPSVA_rt_ordenCorrectivo\''
const OFFSET_SOQL = argv.offset? `OFFSET ${argv.offset}` : ``

async function onExec() {
    try {
        // contamos cuántos registros se debe traer la query, ya que por defecto tiene un máximo de 50_000
        let runningQuery = `sfdx data query -o business--prod -r csv -q \"${QUERY_COUNT}${QUERY_FROM}\"`
        console.log(`info: recuperando cantidad de registros a procesar`)
        const NUM_RECORDS = (await doCommand(runningQuery)).split('\n')[ 1 ].trim()

        // lanzamos query a BD
        runningQuery = `sfdx data query -o business--prod -r csv -q \"${QUERY_ALL}${QUERY_FROM} ORDER BY LastModifiedDate ASC LIMIT ${NUM_RECORDS} ${OFFSET_SOQL}\" > ${targetFile}`
        console.log(`info: recuperando ${bgGray}${NUM_RECORDS}${reset} registros de BD`)
        await doCommand(runningQuery)
        console.log(`info: fichero input en ${fgCyan}${targetFile}${reset}`)

        parseFile(targetFile)

    } catch (error) {
        console.error('Ocurrión un error: ', error);
    }

}

function parseFile(file) {

    return new Promise((resolve) => {

        const HEADER_DOC = `"Id","CPSVA_fld_importeFactura__c","CPSVA_fld_importeTotalOrden__c","CPSVA_fld_precioTotalCliente__c","CPSVA_fld_precioTotalbusiness__c","_originalPricebusiness","_originalCliente"\n`
        writeStream.write(HEADER_DOC)

        console.log(`info: escribiendo fichero output...`)
        const inputStream = createReadStream(file, { encoding: 'utf8' })
        inputStream
            .pipe(
                csv({ separator: ",", }),
            )
            .on('data', (value) => {
                try {
                    // Por cada fila sumo columnas
                    let calcValue = 0
                    let calcValueIVA = 0
                    let calcbusiness = 0
                    let calcbusinessIVA = 0
                    let calcCliente = 0
                    let calcClienteIVA = 0

                    for (let i = 0; ; i++) {
                        if ([ "", undefined ].includes(value[ `ProductRequestLineItems.records.${i}.CPSVA_fld_precio__c` ])) break
                        calcValue += Number(value[ `ProductRequestLineItems.records.${i}.CPSVA_fld_precio__c` ])
                        calcValueIVA += Number(value[ `ProductRequestLineItems.records.${i}.CPSVA_fld_importeConIVA__c` ])

                        if (value[ `ProductRequestLineItems.records.${i}.CPSVA_fld_esDelCliente__c` ]) {
                            calcbusiness    += calcValue
                            calcbusinessIVA += calcValueIVA
                        }
                        else {
                            calcCliente    += calcValue
                            calcClienteIVA += calcValueIVA
                        }
                    }
                    
                    if (calcValue==0){
                        for (let i = 0; ; i++) {
                            if ([ "", undefined ].includes(value[ `ProductRequests.records.${i}.CPSVA_fld_precioTotal__c` ])) break
                            calcValue    += Number(value[ `ProductRequests.records.${i}.CPSVA_fld_precioTotal__c` ])
                            calcValueIVA += Number(value[ `ProductRequests.records.${i}.CPSVA_fld_importeTotalConIVA__c` ])
    
                            calcbusiness    += calcValue
                            calcbusinessIVA += calcValueIVA
                        }
                    }


                    // si cambia guardo valor para modificarlo
                    let cond1 = value.CPSVA_fld_importeFactura__c != calcValue
                    let cond2 = value.CPSVA_fld_precioTotalCliente__c != calcCliente
                    let cond3 = value.CPSVA_fld_precioTotalbusiness__c != calcbusiness
                    if (cond1 || cond2 || cond3) {
                        let line = `"${value.Id}","${calcValue}","${calcValueIVA}","${calcCliente}","${calcbusiness}","${value.CPSVA_fld_precioTotalCliente__c}","${value.CPSVA_fld_precioTotalbusiness__c}"\n`
                        writeStream.write(line)
                    }

                } catch (error) {
                    console.error(
                        `error while processing row ${error} ${value.CUSTOMER_ID}`,
                    )
                }
            })
            .on('close', () => {
                resolve()
                console.log(`info: escritura completa`)
                console.log(`Resultados en fichero:${fgCyan} ${FOLDER_RESULT}/presupuestos-toUpdate.csv${reset}`)
            })
    })


}

onExec()

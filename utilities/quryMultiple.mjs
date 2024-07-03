/* 
  * Description: NodeJS para extraer los documentumId de los ficheros asociados a las órdenes recibidas en el fichero input.
  * Usage: node extractDocumentumId.mjs -f <fichero_input>
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
    .option('object', {
        alias: 'o',
        describe: 'Object to query',
        type: 'string',
        requiresArg: false,
        required: dalse,
        default: 'WorkOrder',
      })
    .parseSync()

const FOLDER = 'Notes/results'
mkdirSync(FOLDER, { recursive: true })
const targetFile = argv.file?.split('/').at(-1).split('.')[ 0 ]
const writeStream = createWriteStream(`${FOLDER}/${targetFile}-documentumId.csv`) //  { flags: 'a' }: append
let ordenes = []

QUERY_WORKORDER = `SELECT id, CPSVA_fld_firmaTecnico__c, CPSVA_fld_firmaCliente__c FROM ServiceAppointment WHERE (REP_fld_orden__r.WorkOrderNumber = '${number}' or appointmentnumber = '${number}') AND REP_fld_trabajosFinalizados__c = true`

function parseFile(file) {
    return new Promise((resolve) => {
      const inputStream = createReadStream(file, { encoding: 'utf8' })
      inputStream
        .pipe(
          csv({ separator: ",", }),
        )
        .on('data', (value) => {
          try {
            
            ordenes.push(value)


          } catch (error) {
            console.error(
              `error while processing row ${error} ${value}`,
            )
          }
        })
        .on('close', () => {
          resolve()
        })
    })
}

function onEnd() {
}


const files = globSync(argv.file).reverse()

for (const file of files) {
    console.log(`info: parsing file ${file}`)
    await parseFile(file)
}
onEnd()






console.log(`📄 ${bgGray}Procesando un total de ${ordenes.length} órdenes${reset}`)

const ENDPOINT = ({
    URL       : 'https://soa.repsol.com:8243/D2-REST/repositories/repprodocum3',
    QUERY     : '?dql= SELECT',
    FROM      : 'FROM',
    TABLE     : 'do2_gdgas_documento',
    PAGINATION: ' &items-per-page=10'
})
const FIELDS =  [ 'r_object_id', 'object_name', 'atr_gdgas_cliente', 'title', 'atr_gdgas_orden' ]
/* ----------- otras columnas: ----------
r_object_type, atr_gdgas_subtipo, 
atr_gdgas_fec_captura, atr_gdgas_elemento, atr_gdgas_tipo_instalacion, atr_gdgas_clase, atr_gdgas_fec_documento, atr_gdgas_fec_caducidad, 
atr_gdgas_tipo_documento, atr_gdgas_archivo, atr_gdgas_observaciones, atr_gdgas_num_lote, atr_gdgas_escaner, atr_gdgas_num_documento, 
atr_gdgas_proveedor, atr_gdgas_num_paginas, atr_gdgas_tipo_mensaje, atr_gdgas_cod500, atr_gdgas_cod500_hist, 
atr_gdgas_instalacion, a_content_type,
*/

const fetchPromises = ordenes.map(orden => {
    // Build DOCUMENTUM PRODUCTION connection
    const FULL_ENDPOINT = `${ENDPOINT.URL}${ENDPOINT.QUERY} ${FIELDS.join(', ')} ${ENDPOINT.FROM} ${ENDPOINT.TABLE} WHERE atr_gdgas_orden= '${orden}' ${ENDPOINT.PAGINATION}`
    
    var myHeaders = new Headers();
    myHeaders.append("Content-Type", "application/vnd.emc.documentum+json");
    myHeaders.append("CRED_D2", "U1ZDX1NSR0dMUFJFUFNPTEdBUzpQYUE2YzI1Ng=="); // hased
    myHeaders.append("Authorization", "Basic U1ZDX1NPQV9TRl9DUFNWQTpUUU42SHR2Y0Zac3dyak11QXl0WHo3enNm");
    myHeaders.append("Cookie", "BIGipServer~TI_TECNOLOGIA_WEB~pool_soa_8243=3901050378.13088.0000");

    var requestOptions = {
        method: 'GET',
        headers: myHeaders,
        redirect: 'follow'
    };

    return fetch(FULL_ENDPOINT, requestOptions)
});

Promise.all(fetchPromises)
    .then(responses => Promise.all(responses.map(response => response.json())))
    .then(dataArray => {
        const HEADER_DOC = `"WorkOrderNumber_or_Client","DocumentTitle","DocumentumId"\n`
        writeStream.write(HEADER_DOC)
        // * Resultado del fetch de las operaciones
        // console.log(dataArray);
        dataArray.forEach(elem => {
            elem.entries?.forEach(entry => {
                let line = `"${entry.content.properties.atr_gdgas_cliente}","${entry.content.properties.object_name}","${entry.content.properties.r_object_id}"\n`
                const FILTER1 = entry.content.properties.object_name.startsWith('CERT_')
                const FILTER2 = entry.content.properties.object_name.startsWith('ALBA_FINAL_SA-')
                if (FILTER1 || FILTER2){
                    writeStream.write(line)
                }
            })
        })
        console.log(`${bgGray}Resultados en fichero:${reset} ${FOLDER}/${targetFile}-documentumId.csv`)
    })
    .catch(error => console.error('Error:', error))

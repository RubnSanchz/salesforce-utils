/*
 * Description: NodeJS para crear los registros necesarios de capacidades por cliente, familia y año.
 * Usage: node capacitiesRecords.mjs -f <fichero_input> [-y <año_capacidad>] [-a <subset_cuentas>]
 * Results: results/capacidades-toInsert.csv
 */

import {
  createReadStream,
  mkdirSync,
  createWriteStream,
  readFileSync,
} from 'fs'

import csv from 'csv-parser'
import { parse } from 'json2csv'

import yargs from 'yargs/yargs'
import { hideBin } from 'yargs/helpers'
import { exec } from 'child_process'
import { getSystemErrorMap } from 'util'

const reset = '\x1b[0m'
const bgGray = '\x1b[47m'
const fgCyan = '\x1b[36m'
const bgCyan = '\x1b[46m'
const fgRed = '\x1b[31m'
const SPLIT_LINE =
  '_______________________________________________________________'

const argv = yargs(hideBin(process.argv))
  .option('file', {
    alias: 'f',
    describe: 'Input File',
    type: 'string',
    requiresArg: false,
    required: false,
  })
  .option('year', {
    alias: 'y',
    describe: 'Año que se quiere sacar los datos',
    type: 'string',
    requiresArg: false,
    required: false,
  })
  .option('accounts', {
    alias: 'a',
    describe: 'Subset de cuentas que se quieren procesar (código cliente)',
    type: 'string',
    requiresArg: false,
    required: false,
  })
  .parseSync()

const FOLDER_SOURCE = 'Notes/source/Capacities'
const FOLDER_RESULT = 'Notes/results'
mkdirSync(FOLDER_SOURCE, { recursive: true })
mkdirSync(FOLDER_RESULT, { recursive: true })
const FILE_SOURCE = 'capacidades.csv'
const FILE_RESULT = 'capacidades-toInsert.csv'
const targetFile = `${FOLDER_SOURCE}/${FILE_SOURCE}`
const writeStream = createWriteStream(`${FOLDER_RESULT}/${FILE_RESULT}`)

const RT_AJUSTE = 'Ajuste Capacidad'
const RT_INTERMEDIOS = 'Capacidad Intermedios'
const RT_POLIOLEFINAS = 'Capacidad Poliolefinas'
const FAMILIES_INTERMEDIOS = ['GLICOLES', 'POLIOLES', 'ESTIRENO', 'OP']
const FAMILIES_POLIOLEFINAS = ['PEAD', 'PEBD', 'PEL', 'm-PEL', 'EVBA', 'PP']
const HEADER_DOC = [
  'Name',
  'RecordType:RecordType:Name',
  'QUFV_fld_account__r:Account:RQO_fld_idExterno__c',
  'QUFV_fld_sumi__r:Account:RQO_fld_idExterno__c',
  'QUFV_fld_year__c',
  'QUFV_fld_family__c',
  'QUFV_fld_anualConsumption__c',
  'QUFV_fld_consolidatedSales__c',
  'QUFV_fld_lastModifiedDate__c',
  'QUFV_fld_competitors__c',
  'QUFV_fld_comments__c',
  'QUFV_fld_idExterno__c',
]
const YEARS = [2020, 2021, 2022, 2023]

let capacidades = new Map()
let yearIteration = 0
let year
let env
let accounts
let recordCounts = {}

YEARS.forEach((yr) => {
  recordCounts[yr] = 0
})

// #region aux functions
function capitalizeFirstLetter(str) {
  if (!str) return str // Handle empty or null strings
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase()
}

function getRT(family) {
  const familyToRecordTypeMap = {
    [RT_INTERMEDIOS]: FAMILIES_INTERMEDIOS,
    [RT_POLIOLEFINAS]: FAMILIES_POLIOLEFINAS,
  }

  let rtLineaNegocio = ''
  for (const [recordType, families] of Object.entries(familyToRecordTypeMap)) {
    if (families.includes(family)) {
      rtLineaNegocio = recordType
      break
    }
  }
  return rtLineaNegocio
}

function formatDate(dateStr) {
  const [day, month, year] = dateStr.split('/');
  return `${year}-${month}-${day}`;
}
// #endregion aux functions

// #region main methods
async function onExec() {
  try {
    console.log(`info: running script...`)
    year = argv.year || YEARS[yearIteration]
    accounts = argv.accounts
    console.log(`info: file source ${fgCyan}${targetFile}${reset}`)
    await parseFile(targetFile)
    writeCapacidades()
  } catch (error) {
    console.error('error processing: ', error)
  }
}

function parseFile(file) {
  console.log(`info: processing source data csv...`)
  return new Promise((resolve) => {
    const inputStream = createReadStream(file, { encoding: 'utf8' })
    inputStream
      .pipe(csv({ separator: ',' }))
      .on('data', (value) => {
        const cleanedValue = {}
        for (const key in value) {
          cleanedValue[key.trim()] = value[key]
        }

        try {
          for (let i = 0; i < YEARS.length; i++) {
            year = argv.year || YEARS[i]

            // Skip processing conditions
            if ( accounts && !accounts .split(',') .some((account) => cleanedValue.clientCode.includes(account)) ) continue // Skip if account is not in subset
            if ( !cleanedValue[`consumo${year}`] ) continue // Skip if consumption is empty

            let clientCode, sumiCode
            if (cleanedValue.clientCode.length === 5) {
              clientCode = `00000${cleanedValue.clientCode}`
            } else {
              clientCode = `00000${cleanedValue.clientCode.slice(0, 5)}`
              sumiCode = cleanedValue.clientCode
            }

            // process data
            const KEY = `${cleanedValue.clientCode}-${year}-${capitalizeFirstLetter(cleanedValue.family)}`
            const KEY_PARENT = `${cleanedValue.clientCode.slice(0, 5)}-${year}-${capitalizeFirstLetter(cleanedValue.family)}-TOTAL`

            let capacidad
            if (capacidades.has(KEY_PARENT)) {
              capacidad = capacidades.get(KEY_PARENT)
              capacidad.QUFV_fld_consolidatedSales__c = Number(capacidad.QUFV_fld_consolidatedSales__c) + Number(cleanedValue[`ventas${year}`])
            } else {
              capacidad = {
                Name: KEY_PARENT,
                'RecordType:RecordType:Name': RT_AJUSTE,
                'QUFV_fld_account__r:Account:RQO_fld_idExterno__c': clientCode,
                'QUFV_fld_sumi__r:Account:RQO_fld_idExterno__c': null,
                QUFV_fld_year__c: year,
                QUFV_fld_family__c: capitalizeFirstLetter(cleanedValue.family),
                QUFV_fld_anualConsumption__c: 0,
                QUFV_fld_consolidatedSales__c: cleanedValue[`ventas${year}`] || 0,
                QUFV_fld_lastModifiedDate__c: null,
                QUFV_fld_competitors__c: null,
                QUFV_fld_comments__c: null,
                QUFV_fld_idExterno__c: KEY_PARENT,
              }
              recordCounts[year]++
            }
            capacidades.set(KEY_PARENT, capacidad)

            capacidad = {
              Name: KEY,
              'RecordType:RecordType:Name': getRT(cleanedValue.family),
              'QUFV_fld_account__r:Account:RQO_fld_idExterno__c': clientCode,
              'QUFV_fld_sumi__r:Account:RQO_fld_idExterno__c': sumiCode,
              QUFV_fld_year__c: year,
              QUFV_fld_family__c: capitalizeFirstLetter(cleanedValue.family),
              QUFV_fld_anualConsumption__c: cleanedValue[`consumo${year}`] || 0,
              QUFV_fld_consolidatedSales__c: cleanedValue[`ventas${year}`] || 0,
              QUFV_fld_lastModifiedDate__c: formatDate(cleanedValue.fDato) || null,
              QUFV_fld_competitors__c: cleanedValue.competidores || null,
              QUFV_fld_comments__c: cleanedValue.comentarios || null,
              QUFV_fld_idExterno__c: KEY,
            }
            capacidades.set(KEY, capacidad)
            
            recordCounts[year]++
            
          }
        } catch (error) {
          console.error(
            `error while processing row ${error} 
            ${cleanedValue.clientCode}-${year}-${capitalizeFirstLetter(cleanedValue.family)}`,
          )
        }
      })
      .on('close', () => {
        resolve()
        console.log(`info: data processed`)
        console.log(SPLIT_LINE)
      })
  })
}

function writeCapacidades() {
  console.log(`info: writing output file...`)
  
  const processedCapacidades = Array.from(capacidades.values())
  if (processedCapacidades.length === 0) {
    console.log(`error: ${fgRed}there are not capacities for the input data${reset}`)
    return
  }

  writeStream.write(parse(processedCapacidades))
  console.log(`info: writting succeded`)

  console.log(SPLIT_LINE)
  console.log('info: record counts per year:')
  for (const [year, count] of Object.entries(recordCounts)) {
    console.log(`  > Year ${year}: ${count} records`)
  }
  console.log(`  > TOTAL: ${processedCapacidades.length} records`)
  console.log(
    `Results on file:${fgCyan} ${FOLDER_RESULT}/${FILE_RESULT}${reset}`,
  )
}

// #endregion main methods

onExec()

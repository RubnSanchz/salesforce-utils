/*
 * Description: NodeJS para crear los registros necesarios de capacidades por cliente, familia y año.
 * Usage: node capacitiesRecords.mjs -f <fichero_input> [-e <entorno_ejecucion>] [-y <año_capacidad>] [-a <subset_cuentas>]
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
  .option('env', {
    alias: 'e',
    describe: 'Entorno de ejecución',
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

const RT_AJUSTE = 'QUFV_rt_ajusteCapacidad'
const RT_INTERMEDIOS = 'QUFV_rt_capacidadIntermedios'
const RT_POLIOLEFINAS = 'QUFV_rt_capacidadPoliolefinas'
const FAMILIES_INTERMEDIOS = ['GLICOLES', 'POLIOLES', 'ESTIRENO', 'OP']
const FAMILIES_POLIOLEFINAS = ['PEAD', 'PEBD', 'PEL', 'm-PEL', 'EVBA', 'PP']
const HEADER_DOC = [
  'Name',
  'RecordType:RecordType:Name',
  'QUFV_fld_account__c',
  'QUFV_fld_sumi__c',
  'QUFV_fld_year__c',
  'QUFV_fld_family__c',
  'QUFV_fld_anualConsumption__c',
  'QUFV_fld_consolidatedSales__c',
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
// #endregion aux functions

// #region main methods
async function onExec() {
  try {
    console.log(`info: running script...`)
    year = argv.year || YEARS[yearIteration]
    env = argv.env || 'pdes'
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
        try {
          // Skip processing if the line is empty
          if (!value?.clientCode) {
            return
          }

          for (let i = 0; i < YEARS.length; i++) {
            // Skip processing conditions
            if (accounts && !accounts.includes(value.clientCode)) continue
            if (!value[`consumo_${year}`]) continue

            // process data
            year = argv.year || YEARS[i]
            const KEY = `${value.clientCode}-${year}-${capitalizeFirstLetter(
              value.family,
            )}`

            if (capacidades.has(KEY)) {
              capacidades.get(`${KEY}-TOTAL`).QUFV_fld_consolidatedSales__c +=
                value.QUFV_fld_consolidatedSales__c
            } else {
              const KEY_PARENT = `${KEY}-TOTAL`
              let capacidad = {
                Name: KEY_PARENT,
                'RecordType:RecordType:Name': RT_AJUSTE,
                QUFV_fld_account__c: value[`${env}_Acc`],
                QUFV_fld_year__c: year,
                QUFV_fld_family__c: capitalizeFirstLetter(value.family),
                QUFV_fld_anualConsumption__c: 0,
                QUFV_fld_consolidatedSales__c: value[`ventas_${year}`],
                QUFV_fld_competitors__c: '',
                QUFV_fld_comments__c: '',
                QUFV_fld_idExterno__c: KEY_PARENT,
              }
              capacidades.set(KEY_PARENT, capacidad)

              capacidad = {
                Name: KEY,
                'RecordType:RecordType:Name': getRT(value.familiy),
                QUFV_fld_account__c: value[`${env}_Acc`],
                QUFV_fld_sumi__c: value[`${env}_sumi`],
                QUFV_fld_year__c: year,
                QUFV_fld_family__c: capitalizeFirstLetter(value.family),
                QUFV_fld_anualConsumption__c: value[`consumo_${year}`],
                QUFV_fld_consolidatedSales__c: value[`ventas_${year}`],
                QUFV_fld_competitors__c: value.competidores,
                QUFV_fld_comments__c: value.comentarios,
                QUFV_fld_idExterno__c: KEY,
              }
              capacidades.set(KEY, capacidad)

              recordCounts[year]++
            }
          }
        } catch (error) {
          console.error(
            `error while processing row ${error} ${value.CUSTOMER_ID}`,
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
  writeStream.write(HEADER_DOC.join(',') + '\n')
  writeStream.write(parse(Array.from(capacidades.values())))
  console.log(`info: writting succeded`)
  console.log(SPLIT_LINE)
  console.log('info: record counts per year:')
  for (const [year, count] of Object.entries(recordCounts)) {
    console.log(`  > Year ${year}: ${count} records`)
  }
  console.log(
    `Results on file:${fgCyan} ${FOLDER_RESULT}/${FILE_RESULT}${reset}`,
  )
}

// #endregion main methods

onExec()

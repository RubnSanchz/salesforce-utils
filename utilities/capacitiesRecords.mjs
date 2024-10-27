/*
 * Description: NodeJS para crear los registros necesarios de capacidades por cliente, familia y año.
 * Usage: node capacitiesRecords.mjs -f <fichero_input> [-y <año_capacidad>]
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
import { globSync } from 'glob'

import yargs from 'yargs/yargs'
import { hideBin } from 'yargs/helpers'
import { exec } from 'child_process'
import { getSystemErrorMap } from 'util'

const reset = '\x1b[0m'
const bgGray = '\x1b[47m'
const fgCyan = '\x1b[36m'
const bgCyan = '\x1b[46m'

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
  .parseSync()

const FOLDER_SOURCE = 'utilities/source'
const FOLDER_RESULT = 'utilities/results'
mkdirSync(FOLDER_SOURCE, { recursive: true })
mkdirSync(FOLDER_RESULT, { recursive: true })
const FILE_SOURCE = 'capacidades.csv'
const FILE_RESULT = 'capacidades-toInsert.csv'
const targetFile = `${FOLDER_SOURCE}/${FILE_SOURCE}`
const writeStream = createWriteStream(`${FOLDER_RESULT}/${FILE_RESULT}`)

// main method
async function onExec() {
  try {
    console.log(`info: fichero input en ${fgCyan}${targetFile}${reset}`)
    parseFile(targetFile)
  } catch (error) {
    console.error('Ocurrión un error: ', error)
  }
}

const RT_AJUSTE = 'QUFV_rt_ajusteCapacidad'
const RT_INTERMEDIOS = 'QUFV_rt_capacidadIntermedios'
const RT_POLIOLEFINAS = 'QUFV_rt_capacidadPoliolefinas'
const FAMILIES_INTERMEDIOS = ['GLICOLES', 'POLIOLES', 'ESTIRENO', 'OP']
const YEARS = [2020, 2021, 2022, 2023]

let capacidades = new Map()

function parseFile(file) {
  return new Promise((resolve) => {
    const HEADER_DOC = [
      'Name',
      'RecordType:RecordType:Name',
      'QUFV_fld_account__c',
      'QUFV_fld_sumi__c',
      'QUFV_fld_year__c',
      'QUFV_fld_family__c',
      'QUFV_fld_annualConsumption__c',
      'QUFV_fld_consolidatedSales__c',
      'QUFV_fld_competitors__c',
      'QUFV_fld_comments__c',
      'QUFV_fld_idExterno__c',
    ]
    writeStream.write(HEADER_DOC.join(','))

    console.log(`info: escribiendo fichero output...`)
    const inputStream = createReadStream(file, { encoding: 'utf8' })
    inputStream
      .pipe(csv({ separator: ',' }))
      .on('data', (value) => {
        try {
          // Por cada fila sumo columnas
          let yearIteration = 0
          let year = value.argv.offset || YEARS[yearIteration]
          let name = 
        } catch (error) {
          console.error(
            `error while processing row ${error} ${value.CUSTOMER_ID}`,
          )
        }
      })
      .on('close', () => {
        resolve()
        console.log(`info: escritura completa`)
        console.log(
          `Resultados en fichero:${fgCyan} ${FOLDER_RESULT}/${FILE_RESULT}${reset}`,
        )
      })
  })
}

onExec()

/**
 * @description       : JS Class for creating Anomalies from 500_DETA and 500_INST SAP files
 *                      Passed as parameters:
 *                     --fDETA: 500_DETA file
 *                     --fINST: 500_INST file
 * @author            : Rubén Sánchez González - ruben.s.gonzalez@accenture.com
 * @created on        : 21-11-2023
 * @last modified on  : 21-11-2023
 * @last modified by  : Rubén Sánchez González - ruben.s.gonzalez@accenture.com
**/

import {
    createReadStream,
    createWriteStream,
    mkdirSync,
    readFileSync,
} from 'fs'

import csv from 'csv-parser'
import { parse } from 'json2csv'
import { globSync } from 'glob'
import XLSX from 'xlsx';

import yargs from 'yargs/yargs'
import { hideBin } from 'yargs/helpers'
import { exit } from 'process';

const reset = "\x1b[0m";
const fgCyan = "\x1b[36m";

const argv = yargs(hideBin(process.argv))
    .option('fileDETA', {
        alias      : 'fDETA',
        describe   : 'Input File 500_DETA. Plain or xls/xlsx file',
        type       : 'string',
        requiresArg: false,
        required   : false,
    })
    .option('fileINST', {
        alias      : 'fINST',
        describe   : 'Input File 500_INST. Plain or xls/xlsx file',
        type       : 'string',
        requiresArg: false,
        required   : false,
    })
    .parseSync()


const today = new Date().toISOString().split('T')[ 0 ];

const FOLDER         = 'Notes/results'
const WORKING_FOLDER = 'Notes/source/Anomalias'
mkdirSync(FOLDER, { recursive: true })
mkdirSync(WORKING_FOLDER, { recursive: true })
const writeStreamDeta = createWriteStream(`${WORKING_FOLDER}/DETA_${today}.csv`)
const writeStreamInst = createWriteStream(`${WORKING_FOLDER}/INST_${today}.csv`)
const writeStreamR    = createWriteStream(`${FOLDER}/anomalias_${today}.csv`)

const HEADER_DETA = [ 'TRANSPORTE', 'ENTREGA', 'INSTALACION', 'FECHA_VISITA', 'ANOMALIA', 'DEPOSITO', 'RESPONSABLE' ]
const HEADER_INST = [ 'TRANSPORTE', 'ENTREGA', 'INSTALACION', 'FECHA_VISITA', 'TRANSPORTISTA', 'NIF_CONDUCTOR', 'MATRICULA_CISTERNA', 'COD_USUARIO', 'FECHA_SAP', 'HORA_SAP', 'OBSERVACIONES' ]

let anomalias = new Map()

const LENGTHS_DETA = [ 10, 10, 10, 8, 3, 18, 3 ]
const LENGTHS_INST = [ 10, 10, 10, 8, 10, 16, 12, 12, 8, 6, 400 ]

const XLSX_PATTERN_CAPITALIZED = /.*\.xlsx?$/i
const isDetaXLS = XLSX_PATTERN_CAPITALIZED.test(argv.fileDETA)
const isInstXLS = XLSX_PATTERN_CAPITALIZED.test(argv.fileINST)

// ______________________________________________________________________________________________________________________
// Read input files and Process them


// Analyze Deta File
if (isDetaXLS) {
    preProcessFilesXLS(argv.fileDETA)
} else {
    const files = globSync(argv.fileDETA).reverse() // Deta File
    for (const file of files) {
        console.log(`info: parsing file ${fgCyan}${file}${reset}`)
        preProcessFilesPlain(file)
    }
}
// Analyze Inst File
if (isInstXLS) {
    preProcessFilesXLS(argv.fileINST, false)
} else {
    const files = globSync(argv.fileINST).reverse() // Deta File
    for (const file of files) {
        console.log(`info: parsing file ${fgCyan}${file}${reset}`)
        preProcessFilesPlain(file, false)
    }
}


function preProcessFilesXLS(file, isDeta = true) {
    console.log(`info: parsing XLS file ${fgCyan}${file}${reset}`)
    const fileContent = readFileSync(file)
    const workbook = XLSX.read(fileContent, { type: 'buffer' });

    const sheetName = workbook.SheetNames[ 0 ]
    const worksheet = workbook.Sheets[ sheetName ]
    const jsonData  = XLSX.utils.sheet_to_json(worksheet)

    let lines = []
    if (isDeta) {
        writeStreamDeta.write(HEADER_DETA.join(',') + '\n')
        for (const row of jsonData) {
            const FECHA_VISITA = convertSerialDate(row.FECHA)
            const RESPONSABLE  = row.RESPON === 'REPSOL' ? '001' : '002'
            // [ 'TRANSPORTE', 'ENTREGA', 'INSTALACION', 'FECHA_VISITA', 'ANOMALIA', 'DEPOSITO', 'RESPONSABLE' ]
            const line = `${row.SHNUMBER},${row.DOC_NUMBER},${row.KUNNR},${FECHA_VISITA},0${row.CODIGO},${row.IDDEP},${RESPONSABLE}`
            lines.push(line)
        }
        console.log(`info: writing aux file ${fgCyan}${WORKING_FOLDER}/DETA_${today}.csv${reset}`)
        writeStreamDeta.write(lines.join('\n'))
        writeStreamDeta.end()
    }
    else {
        writeStreamInst.write(HEADER_INST.join(',') + '\n')
        for (const row of jsonData) {
            const FECHA_VISITA = convertSerialDate(row.FECHA)
            const FECHA_SAP    = convertSerialDate(row.UDATE)
            const HORA_SAP     = convertExcelTimeToHHMMSS(row.UZEIT)
            // [ 'TRANSPORTE', 'ENTREGA', 'INSTALACION', 'FECHA_VISITA', 'TRANSPORTISTA', 'NIF_CONDUCTOR', 'MATRICULA_CISTERNA', 'COD_USUARIO', 'FECHA_SAP', 'HORA_SAP', 'OBSERVACIONES' ]
            const line = `${row.SHNUMBER},${row.DOC_NUMBER},${row.KUNNR},${FECHA_VISITA},${row.LIFNR},${row.STCD1},${row.MATRIC},${row.UNAME},${FECHA_SAP},${HORA_SAP},${row.TEXTO}`
            lines.push(line)
        }
        console.log(`info: writing aux file ${fgCyan}${WORKING_FOLDER}/DETA_${today}.csv${reset}`)
        writeStreamInst.write(lines.join('\n'))
        writeStreamInst.end()
    }
}

function convertSerialDate(serialDate) {
    const excelEpoch = new Date(1899, 11, 31);
    const excelEpochAsUnixTimestamp = excelEpoch.getTime();
    const millisecondsPerDay = 24 * 60 * 60 * 1000;

    const date = new Date(excelEpochAsUnixTimestamp + serialDate * millisecondsPerDay);

    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');

    return `${year}${month}${day}`;
}

function convertExcelTimeToHHMMSS(excelTime) {
    const totalSeconds = Math.floor(excelTime * 24 * 60 * 60);
    const hours = Math.floor(totalSeconds / 3600).toString().padStart(2, '0');
    const minutes = Math.floor((totalSeconds % 3600) / 60).toString().padStart(2, '0');
    const seconds = (totalSeconds % 60).toString().padStart(2, '0');

    return `${hours}${minutes}${seconds}`;
}


function preProcessFilesPlain(file, isDeta = true) {
    console.log(`info: parsing plain file ${fgCyan}${file}${reset}`)
    const fileContent = readFileSync(file, 'utf8')
    const contentProcessed = splitByLength(fileContent, isDeta ? LENGTHS_DETA : LENGTHS_INST)
    if (isDeta) {
        writeStreamDeta.write(HEADER_DETA.join(',') + '\n')
        writeStreamDeta.write(contentProcessed)
    }
    else {
        writeStreamInst.write(HEADER_INST.join(',') + '\n')
        writeStreamInst.write(contentProcessed)
    }
}

// function that receives a plain text file and separates it into columns by length
function splitByLength(file, lengths, separator = ',') {
    let result = ''
    const lines = file.split(/\r?\n/)
    lines.slice(0, -1).forEach((line, index) => {
        let position = -1
        lengths.forEach((length) => {
            let slicePosition = position + length + 1 // +1 because of comma separator
            line = line.slice(0, slicePosition) + separator + line.slice(slicePosition)
            position = slicePosition
        })
        result += line + '\n'
    })
    return result
}


// ______________________________________________________________________________________________________________________
// Create output file

const FILE_DETA = `${WORKING_FOLDER}/DETA_${today}.csv`
const FILE_INST = `${WORKING_FOLDER}/INST_${today}.csv`

async function createAnomalies() {
    const inputStream1 = createReadStream(FILE_DETA, { encoding: 'utf8' })
    const inputStream2 = createReadStream(FILE_INST, { encoding: 'utf8' })

    const processStream1 = new Promise((resolve, reject) => {
        inputStream1
            .pipe(
                csv({ separator: ",", }),
            )
            .on('data', (value) => {
                try {
                    // Identify unique anomaly by TRANSPORTE|ENTREGA
                    const INTERNAL_KEY = `${value.TRANSPORTE}|${value.ENTREGA}`

                    // aux calculations
                    let masterRecordId  = `DATAGAS|${value.TRANSPORTE}|${value.ENTREGA}|${value.DEPOSITO}|${value.ANOMALIA}`
                    let assetIdentifier = `BP5|${value.INSTALACION}|${value.DEPOSITO}`
                    if (!value.DEPOSITO.startsWith("00000")) {
                        masterRecordId  = `DATAGAS|${value.TRANSPORTE}|${value.ENTREGA}|${value.ANOMALIA}`
                        assetIdentifier = null
                    }

                    let year  = value.FECHA_VISITA.substring(0, 4);
                    let month = value.FECHA_VISITA.substring(4, 6);
                    let day   = value.FECHA_VISITA.substring(6, 8);
                    let dateAnom = [ year, month, day ].join('-');

                    // Fill Anomalia
                    let anomalia = {
                        CPSVA_fld_masterRecordId__c                                 : masterRecordId,
                        CPSVA_fld_codigoTransporte__c                               : value.TRANSPORTE,
                        CPSVA_fld_codigoEntrega__c                                  : value.ENTREGA,
                        'CPSVA_fld_instalacion__r:Account:REP_fld_masterRecordId__c': `BP5|032|KNA1|0170|${value.INSTALACION}`,
                        CPSVA_fld_fechaVisita__c                                    : dateAnom,
                        CPSVA_fld_codigoAnomalia__c                                 : value.ANOMALIA,
                        'CPSVA_fld_equipo__r:Asset:REP_fld_identificador__c'        : assetIdentifier,
                        CPSVA_fld_responsable__c                                    : value.RESPONSABLE
                    }

                    // fill map of anomalies
                    anomalias.set(INTERNAL_KEY, anomalia)

                } catch (error) {
                    console.error(
                        `error while processing row ${error} DATAGAS|${value.TRANSPORTE}|${value.ENTREGA}|${value.DEPOSITO}|${value.ANOMALIA}`,
                    )
                }
            })
            .on('close', resolve)
    })

    const processStream2 = new Promise((resolve, reject) => {
        inputStream2
            .pipe(
                csv({ separator: ",", }),
            )
            .on('data', (value) => {
                try {
                    // Identify  unique anomaly by TRANSPORTE|ENTREGA
                    const INTERNAL_KEY = `${value.TRANSPORTE}|${value.ENTREGA}`
                    let anomalia = anomalias.get(INTERNAL_KEY);

                    // aux calculations
                    let dateAnom = value.FECHA_SAP.replace(/(\d{4})(\d{2})(\d{2})/, '$1-$2-$3');
                    let timeAnom = value.HORA_SAP?.match(/.{1,2}/g).join(':');
                    let dateTimeAnom = [ dateAnom, timeAnom ].join('T');

                    // keep filling anomalies
                    anomalia[ 'CPSVA_fld_transportista__r:Account:REP_fld_masterRecordId__c' ] = `BP5|032|KNA1|${value.TRANSPORTISTA}`
                    anomalia.CPSVA_fld_NIFConductor__c      = value.NIF_CONDUCTOR
                    anomalia.CPSVA_fld_matriculaCisterna__c = value.MATRICULA_CISTERNA
                    anomalia.CPSVA_fld_codigoUsuario__c     = value.COD_USUARIO
                    anomalia.CPSVA_fld_fechaRegistroSAP__c  = dateTimeAnom
                    anomalia.CPSVA_fld_descripcion__c       = value.OBSERVACIONES

                    // fill map of anomalies
                    anomalias.set(INTERNAL_KEY, anomalia)

                } catch (error) {
                    console.error(
                        `error while processing row ${error} DATAGAS|${value.TRANSPORTE}|${value.ENTREGA}|${value.DEPOSITO}|${value.ANOMALIA}`,
                    )
                }
            })
            .on('close', () => {
                resolve()
            })
    })

    // force order of execution 500_DETA -> 500_INST
    await processStream1
    await processStream2

    console.log(`info: writing file ${fgCyan}${FOLDER}/anomalias_${today}.csv${reset}`)
    writeStreamR.write(parse(Array.from(anomalias.values())))

    console.log(`info: process ended, written a total amount of ${anomalias.size} anomalies succesfully`)
}

createAnomalies()

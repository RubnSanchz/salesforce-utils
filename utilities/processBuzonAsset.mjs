/**
 * @description       : JS Class for filling the mailbox assinged from fCartera and fAsset Salesforce files
 *                      Passed as parameters:
 *                     --fCartera: BBDD origin for assignation. 'Centro' + 'modo envio' = 'buzon'
 *                     --fAsset: BBDD file to process and output. Fill 'buzon'
 * @author            : Rubén Sánchez González
 * @created on        : 05-07-2024
 * @last modified on  : 05-07-2024
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

import yargs from 'yargs/yargs'
import { hideBin } from 'yargs/helpers'
import { exit } from 'process';

const reset = "\x1b[0m";
const fgCyan = "\x1b[36m";

const argv = yargs(hideBin(process.argv))
    .option('fileCarteras', {
        alias      : 'fCartera',
        describe   : 'Input File 500_DETA. Plain or xls/xlsx file',
        type       : 'string',
        requiresArg: false,
        required   : false,
    })
    .option('fileAssets', {
        alias      : 'fAsset',
        describe   : 'Input File 500_INST. Plain or xls/xlsx file',
        type       : 'string',
        requiresArg: false,
        required   : false,
    })
    .parseSync()


const today = new Date().toISOString().split('T')[ 0 ];

const FOLDER         = 'utilities/results'
const WORKING_FOLDER = 'utilities/source/BuzonTT'
mkdirSync(FOLDER, { recursive: true })
mkdirSync(WORKING_FOLDER, { recursive: true })
const writeStreamR    = createWriteStream(`${FOLDER}/buzones_${today}.csv`)

let buzones = new Map()


// ______________________________________________________________________________________________________________________
// Create output file

const FILE_CARTERAS = `${WORKING_FOLDER}/Carteras_${today}.csv`
const FILE_ASSETS = `${WORKING_FOLDER}/Assets_${today}.csv`

async function createBuzon() {
    const inputStream1 = createReadStream(FILE_CARTERAS, { encoding: 'utf8' })
    const inputStream2 = createReadStream(FILE_ASSETS, { encoding: 'utf8' })

    let buzonesAssignment = new Map()
    const processStream1 = new Promise((resolve, reject) => {
        inputStream1
            .pipe(
                csv({ separator: ",", }),
            )
            .on('data', (value) => {
                try {
                    // console.log(`info: reading csv file ${fgCyan}${FILE_CARTERAS}${reset}`)
                    // Fill map from Carteras
                    const IDENTIFIER = `${value.QUTT_fld_centro__c}|${value.QUTT_fld_modoEnvio__c}`
                    // fill map of anomalies
                    buzonesAssignment.set(IDENTIFIER, value.QUTT_fld_buzonTerrestre__c)
                    // console.log(`info: ${buzonesAssignment.size} different mailboxes found`)

                } catch (error) {
                    console.error(
                        `error on inputStream1 while processing row ${error} ${value.QUTT_fld_centro__c}|${value.QUTT_fld_modoEnvio__c}`,
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
                    const IDENTIFIER = `${value.RQO_fld_centro__c}|${value['RQO_fld_idRelacion__r.QUSAC_fld_condicionExpedicion__c']}`
                    if ( buzonesAssignment.get(IDENTIFIER) ) {
                        let buzon = {
                            Id                        : value.Id,
                            QUTT_fld_buzonTerrestre__c: buzonesAssignment.get(IDENTIFIER),
                            _identif                  : IDENTIFIER
                        }
                        buzones.set(value.Id, buzon)
                    }

                } catch (error) {
                    console.error(
                        `error on inputStream2 while processing row ${error} ${value.QUTT_fld_centro__c}|${value.QUTT_fld_modoEnvio__c}`,
                    )
                }
            })
            .on('close', () => {
                resolve()
            })
    })

    // force order of execution Carteras -> Assets
    await processStream1
    await processStream2

    console.log(`info: writing file ${fgCyan}${FOLDER}/buzones_${today}.csv${reset}`)
    writeStreamR.write(parse(Array.from(buzones.values())))

    console.log(`info: process ended, written a total amount of ${fgCyan}${buzones.size}${reset} buzones succesfully`)
}

createBuzon()

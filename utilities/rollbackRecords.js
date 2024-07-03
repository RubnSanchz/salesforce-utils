import csv from 'csv-parser'
import { parse } from 'json2csv'
import { createReadStream, writeFileSync } from 'fs'

const SOURCE_FOLDER = 'sources'
const TARGET_FOLDER = 'results'
const SOURCE_FILE = 'saHistory'

let inputStream = createReadStream(`${SOURCE_FOLDER}/${SOURCE_FILE}.csv`, {
  encoding: 'utf8',
})

const sa = new Map()

inputStream
  .pipe(
    csv({
      separator: ',',
    }),
  )
  .on('data', (value) => {
    if (value.NewValue === 'REP_Cancelada') return
    sa.set(value.ServiceAppointmentId, {
      ...(sa.get(value.ServiceAppointmentId) || {}),
      Id: value.ServiceAppointmentId,
      [value.Field]: value.NewValue,
    })
  })
  .on('close', () => {
    const file = `${TARGET_FOLDER}/${SOURCE_FILE}.csv`
    console.debug(`info: writing ${sa.size} sa history in ${file}`)

    writeFileSync(file, parse([...sa.values()]))
  })
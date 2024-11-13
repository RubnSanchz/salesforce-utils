// Encryption: gpg --batch --passphrase "$GPG_PASSWORD" --symmetric --cipher-algo AES256 <route_to_file>
// Encryption usage: node gpg_encrypt.mjs -f <route_to_file> [-d <bool_delete_source_file>]

import { exec } from 'child_process'
import { promisify } from 'util'
import path from 'path'
import yargs from 'yargs/yargs'
import { hideBin } from 'yargs/helpers'
const execAsync = promisify(exec)

const argv = yargs(hideBin(process.argv))
  .option('file', {
    alias: 'f',
    describe: 'Input File',
    type: 'string',
    requiresArg: false,
    required: true,
  })
  .option('delete', {
    alias: 'd',
    describe: 'delete source file',
    type: 'boolean',
    requiresArg: false,
    required: false,
  })
  .parseSync()

// Function to encrypt a file
async function encryptFile(encryptedFilePath) {
  const passphrase = process.env.GPG_PASSWORD

  if (!passphrase) {
    throw new Error('GPG_PASSWORD environment variable is not set.')
  }

  // Build the GPG command to encrypt the file
  const command = `gpg --batch --passphrase "${passphrase}" --symmetric --cipher-algo AES256 "${encryptedFilePath}"`

  try {
    // Run the command
    await execAsync(command)
    console.log(
      `Encryption successful -- Encrypted file ${encryptedFilePath}.gpg`,
    )
    if (argv.delete) {
      await execAsync(`rm ${encryptedFilePath}`)
      console.log('Source file deleted')
    }
  } catch (error) {
    console.error('Error during encryption:', error.message)
  }
}

// Set the output in the same path as the encrypted file
const encryptedFilePath = argv.file

// call encrypt function
encryptFile(encryptedFilePath)

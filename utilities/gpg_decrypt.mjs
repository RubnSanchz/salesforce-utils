// Encryption: gpg --batch --passphrase "$GPG_PASSWORD" --symmetric --cipher-algo AES256 <route_to_file>
// *** remember to set the GPG_PASSWORD environment variable. Then export  GPG_PASSWORD
// Decryption usage: node decrypt_gpg.mjs -f <route_to_file>

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
  .help('help')
  .alias('help', 'h')
  .example('$0 -f /path/to/file.csv', 'Decrypt the specified file')
  .example('$0 -f /path/to/file.csv -d', 'Decrypt the specified file and delete the source file')
  .parseSync()

// Function to decrypt a file
async function decryptFile(encryptedFilePath, outputFilePath) {
  const passphrase = process.env.GPG_PASSWORD

  if (!passphrase) {
    throw new Error('GPG_PASSWORD environment variable is not set.')
  }

  // Build the GPG command to decrypt the file
  const command = `gpg --batch --yes --passphrase "${passphrase}" --decrypt "${encryptedFilePath}" > "${outputFilePath}"`

  try {
    // Run the command
    await execAsync(command)
    console.log(
      `Decryption successful -- Decrypted file saved to ${outputFilePath}`,
    )
    if (argv.delete) {
      await execAsync(`rm ${encryptedFilePath}`)
      console.log('Encrypted source file deleted')
    }
  } catch (error) {
    console.error('Error during decryption:', error.message)
  }
}

// Set the output in the same path as the encrypted file
const encryptedFilePath = argv.file
const directory = path.dirname(encryptedFilePath)
const fileNameWithoutExtension = path.basename(encryptedFilePath, '.gpg')
const outputFilePath = path.join(directory, fileNameWithoutExtension)

// call decrypt function
decryptFile(encryptedFilePath, outputFilePath)

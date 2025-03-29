import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'
import { deployContract } from './deploymentUtils'

async function main() {
  const [deployer] = await ethers.getSigners()

  const v3QuoteVerifier = process.env.V3_QUOTE_VERIFIER_ADDRESS
  if (!v3QuoteVerifier) {
    throw new Error('V3_QUOTE_VERIFIER_ADDRESS not set')
  }

  const mrEnclave = process.env.MR_ENCLAVE
  if (!mrEnclave) {
    throw new Error('MR_ENCLAVE not set')
  }

  const mrSigner = process.env.MR_SIGNER
  if (!mrSigner) {
    throw new Error('MR_SIGNER not set')
  }

  const esperssoTEEVerifier = await deployContract(
    'EspressoTEEVerifier',
    deployer,
    [mrEnclave, mrSigner, v3QuoteVerifier],
    true
  )
  console.log(
    'EspressoTEEVerifier deployed at address:',
    esperssoTEEVerifier.address
  )
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })

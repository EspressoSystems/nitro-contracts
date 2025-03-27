import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'
import { deployContract } from './deploymentUtils'

async function main() {
  const [deployer] = await ethers.getSigners()

  const esperssoTEEVerifier = await deployContract(
    'EspressoTEEVerifierMock',
    deployer,
    [],
    true
  )
  console.log(
    'EspressoTEEVerifierMock deployed at address:',
    esperssoTEEVerifier.address
  )
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })

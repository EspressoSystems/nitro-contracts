import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'
import { deployContract } from './deploymentUtils'

async function main() {
  const [deployer] = await ethers.getSigners()

  const pccsRouterAddress = process.env.PCCS_ROUTER_ADDRESS as string
  if (!pccsRouterAddress) {
    throw new Error('PCCS_ROUTER_ADDRESS not set')
  }

  const esperssoTEEVerifier = await deployContract(
    'EspressoTEEVerifier',
    deployer,
    [pccsRouterAddress],
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

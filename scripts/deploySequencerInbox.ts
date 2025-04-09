import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'
import { deployContract } from './deploymentUtils'

async function main() {
  const [deployer] = await ethers.getSigners()

  const SequencerInbox = await deployContract(
    'SequencerInbox',
    deployer,
    [117964, '0x1ce0ec7b1813b0d7322190c548af383b67b27d3d', false],
    true
  )
  console.log('SequencerInbox deployed at address:', SequencerInbox.address)
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })

import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'
import { deployContract } from './deploymentUtils'

async function main() {
  const [deployer] = await ethers.getSigners()

  const SequencerInbox = await deployContract(
    'SequencerInbox',
    deployer,
    [process.env.MAX_DATA_SIZE, process.env.READER_ADDRESS, process.env.IS_USING_FEE_TOKEN],
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

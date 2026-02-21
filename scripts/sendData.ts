import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'

async function main() {
  const [signer] = await ethers.getSigners()

  // Replace with your deployed contract address
  const contractAddress = '0xbA6E2502B4Ef771582bD4517182440cC6D31c8e7'

  // Get contract interface from artifacts
  const DataLogger = await ethers.getContractAt(
    'DataLogger',
    contractAddress,
    signer
  )

  // Generate 100 KB of data (zero bytes or random)
  const dataSize = 50 * 1024 // 90 KB
  const buffer = Buffer.alloc(dataSize, 0x42) // fill with 'B' = 0x42

  console.log(`Sending ${dataSize / 1024} KB of calldata...`)

  const tx = await DataLogger.postData(buffer, {
    gasLimit: BigNumber.from(2_000_000),
  })

  console.log('Transaction sent! Hash:', tx.hash)
  await tx.wait()
  console.log('Transaction confirmed.')
}

main().catch(error => {
  console.error(error)
  process.exit(1)
})

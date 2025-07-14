import { ethers } from 'hardhat'
import { ContractFactory, Contract, Overrides } from 'ethers'
import '@nomiclabs/hardhat-ethers'
import { deployContract } from './deploymentUtils'
import { ArbSys__factory } from '../build/types'
import { ARB_SYS_ADDRESS } from '@arbitrum/sdk/dist/lib/dataEntities/constants'
import { Toolkit4844 } from '../test/contract/toolkit4844'

async function _isRunningOnArbitrum(signer: any): Promise<Boolean> {
  const arbSys = ArbSys__factory.connect(ARB_SYS_ADDRESS, signer)
  try {
    await arbSys.arbOSVersion()
    return true
  } catch (error) {
    return false
  }
}

async function main() {
  const [signer] = await ethers.getSigners()

  try {

    const rollupCreator = await deployContract('RollupCreator', signer)
    // deploy Sequencer Inbox,
    const isOnArb = await _isRunningOnArbitrum(signer)
    const reader4844 = isOnArb
      ? ethers.constants.AddressZero
      : (await Toolkit4844.deployReader4844(signer)).address

    // NOTE: maxDataSize is set for an L3, if deploying an L2 use "const maxDataSize = 117964"
    const maxDataSize = 104857
    const ethSequencerInbox = await deployContract('SequencerInbox', signer, [
      maxDataSize,
      reader4844,
      false,
    ])

    const erc20SequencerInbox = await deployContract('SequencerInbox', signer, [
      maxDataSize,
      reader4844,
      true,
    ])

    const bridgeCreator = await deployContract('BridgeCreator', signer, [
      [
        // BRIDGE_ADDRESS,
        ethSequencerInbox.address,
        // INBOX_ADDRESS,
        // RollupEventInbox,
        // Outbox,
      ],
      [
        // ERC20Bridge address,
        erc20SequencerInbox.address,
        // ERC20Inbox address ,
        // ERC20RollupEventInbox address ,
        // ERC20Outbox address ,
      ],
    ])

    // deploy OSP

    const prover0 = await deployContract('OneStepProver0', signer)
    const proverMem = await deployContract('OneStepProverMemory', signer)
    const proverMath = await deployContract('OneStepProverMath', signer)
    const proverHostIo = await deployContract('OneStepProverHostIo', signer)
    const osp: Contract = await deployContract('OneStepProofEntry', signer, [
      prover0.address,
      proverMem.address,
      proverMath.address,
      proverHostIo.address,
    ])

    // Call setTemplates with the deployed contract addresses
    console.log('Waiting for the Template to be set on the Rollup Creator')
    await rollupCreator.setTemplates(
      bridgeCreator.address,
      osp,
      // ChallengeManager address,
      // RollupAdmin address,
      // RollupUser address,
      // UpgradeExecutor address,
      // ValidatorUtils address,
      // ValidatorWalletCreator address,
      // deployHelper address
    )
    console.log('Template is set on the Rollup Creator')
  } catch (error) {
    console.error(
      'Deployment failed:',
      error instanceof Error ? error.message : error
    )
  }
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })

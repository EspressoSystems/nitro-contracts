import { ethers } from 'hardhat'
import '@nomiclabs/hardhat-ethers'
import { deployAllContracts } from '../deploymentUtils'
import { createRollup } from '../rollupCreation'
import { promises as fs } from 'fs'
import { BigNumber } from 'ethers'
import { execSync } from 'child_process'
import * as path from 'path'

async function main() {
  /// read env vars needed for deployment
  let childChainName = process.env.CHILD_CHAIN_NAME as string
  if (!childChainName) {
    throw new Error('CHILD_CHAIN_NAME not set')
  }

  let deployerPrivKey = process.env.DEPLOYER_PRIVKEY as string
  if (!deployerPrivKey) {
    throw new Error('DEPLOYER_PRIVKEY not set')
  }

  let parentChainRpc = process.env.PARENT_CHAIN_RPC as string
  if (!parentChainRpc) {
    throw new Error('PARENT_CHAIN_RPC not set')
  }

  if (!process.env.PARENT_CHAIN_ID) {
    throw new Error('PARENT_CHAIN_ID not set')
  }


  const deployerWallet = new ethers.Wallet(
    deployerPrivKey,
    new ethers.providers.JsonRpcProvider(parentChainRpc)
  )

  const maxDataSize =
    process.env.MAX_DATA_SIZE !== undefined
      ? ethers.BigNumber.from(process.env.MAX_DATA_SIZE)
      : ethers.BigNumber.from(117964)

  /// get fee token address, if undefined use address(0) to have ETH as fee token
  let feeToken = process.env.FEE_TOKEN_ADDRESS as string
  if (!feeToken) {
    feeToken = ethers.constants.AddressZero
  }
  let feeTokenPricer = process.env.FEE_TOKEN_PRICER_ADDRESS as string
  if (!feeTokenPricer) {
    feeTokenPricer = ethers.constants.AddressZero
  }

  /// get stake token address, if undefined deploy WETH and set it as stake token
  let stakeToken = process.env.STAKE_TOKEN_ADDRESS as string
  if (!stakeToken) {
    console.log('Deploying WETH')
    const wethFactory = (await ethers.getContractFactory('TestWETH9')).connect(
      deployerWallet
    )
    const weth = await wethFactory.deploy('Wrapped Ether', 'WETH')
    await weth.deployTransaction.wait()
    await weth.deployed()
    stakeToken = weth.address
    console.log('WETH deployed at', stakeToken)
  }

  // Deploy mock TEE verifiers via forge script from the espresso-tee-contracts submodule
  const teeContractsDir = path.join(__dirname, '../../lib/espresso-tee-contracts')
  console.log('Deploying mock TEE verifiers via forge script')
  execSync(`mkdir -p ${path.join(teeContractsDir, 'deployments')}`)
  const forgeOutput = execSync(
    `forge script scripts/DeployMockTEEVerifiers.s.sol:DeployMockTEEVerifiers --rpc-url ${parentChainRpc} --private-key ${deployerPrivKey} --broadcast`,
    { cwd: teeContractsDir }
  ).toString()
  const match = forgeOutput.match(/EspressoTEEVerifierMock deployed at: (0x[0-9a-fA-F]{40})/)
  if (!match) {
    throw new Error('Failed to parse EspressoTEEVerifierMock address from forge output:\n' + forgeOutput)
  }
  const espressoTEEVerifierAddress = match[1]
  console.log('EspressoTEEVerifierMock deployed at:', espressoTEEVerifierAddress)

  /// deploy templates and rollup creator
  console.log('Deploy RollupCreator')
  const contracts = await deployAllContracts(deployerWallet, maxDataSize, false)

  console.log('Set templates on the Rollup Creator')
  await (
    await contracts.rollupCreator.setTemplates(
      contracts.bridgeCreator.address,
      contracts.osp.address,
      contracts.challengeManager.address,
      contracts.rollupAdmin.address,
      contracts.rollupUser.address,
      contracts.upgradeExecutor.address,
      contracts.validatorWalletCreator.address,
      contracts.deployHelper.address,
      { gasLimit: BigNumber.from('300000') }
    )
  ).wait()

  /// Create rollup
  const chainId = (await deployerWallet.provider.getNetwork()).chainId
  console.log(
    'Create rollup on top of chain',
    chainId,
    'using RollupCreator',
    contracts.rollupCreator.address
  )

  const result = await createRollup(
    deployerWallet,
    true,
    contracts.rollupCreator.address,
    feeToken,
    feeTokenPricer,
    stakeToken,
    espressoTEEVerifierAddress,
  )

  if (!result) {
    throw new Error('Rollup creation failed')
  }

  const { rollupCreationResult, chainInfo } = result

  /// store deployment address
  // chain deployment info
  const chainDeploymentInfo =
    process.env.CHAIN_DEPLOYMENT_INFO !== undefined
      ? process.env.CHAIN_DEPLOYMENT_INFO
      : 'deploy.json'
  await fs.writeFile(
    chainDeploymentInfo,
    JSON.stringify(rollupCreationResult, null, 2),
    'utf8'
  )

  // child chain info
  chainInfo['chain-name'] = childChainName
  const childChainInfo =
    process.env.CHILD_CHAIN_INFO !== undefined
      ? process.env.CHILD_CHAIN_INFO
      : 'l2_chain_info.json'
  await fs.writeFile(
    childChainInfo,
    JSON.stringify([chainInfo], null, 2),
    'utf8'
  )
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })

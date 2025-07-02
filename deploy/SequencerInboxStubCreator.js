import { Toolkit4844 } from '../test/contract/toolkit4844'

module.exports = async hre => {
  const { deployments, getNamedAccounts, ethers } = hre
  const { deployer } = await getNamedAccounts()

<<<<<<< HEAD
  const bridge = await ethers.getContract('BridgeStub')

  const espressoTEEVerifierInboxFac = await ethers.getContractFactory(
    'EspressoTEEVerifierMock'
  )
  const espressoTEEVerifier = await espressoTEEVerifierInboxFac.deploy()
  await espressoTEEVerifier.deployed()

=======
  const bridge = await deployments.get('BridgeStub')
>>>>>>> 8b17454ca87e4aa0c66d70844e6fbdcf57f7c43c
  const reader4844 = await Toolkit4844.deployReader4844(
    await ethers.getSigner(deployer)
  )
  const maxTime = {
    delayBlocks: 10000,
    futureBlocks: 10000,
    delaySeconds: 10000,
    futureSeconds: 10000,
  }
  await deployments.deploy('SequencerInboxStub', {
    from: deployer,
    args: [
      bridge.address,
      deployer,
      maxTime,
      117964,
      reader4844.address,
      false,
<<<<<<< HEAD
      espressoTEEVerifier.address,
=======
      true,
>>>>>>> 8b17454ca87e4aa0c66d70844e6fbdcf57f7c43c
    ],
  })
}

module.exports.tags = ['SequencerInboxStub', 'test']
module.exports.dependencies = ['BridgeStub']

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import 'forge-std/Test.sol';
import './util/TestUtil.sol';
import '../../src/bridge/Bridge.sol';
import '../../src/bridge/SequencerInbox.sol';
import { Reader4844 } from '../../src/mocks/Reader4844.sol';
import { IGasRefunder } from '../../src/libraries/IGasRefunder.sol';
import { EspressoTEEVerifierBlobsMock } from '../../src/mocks/EspressoTEEVerifierBlobsMock.sol';
import { IEspressoTEEVerifier } from '../../src/bridge/IEspressoTEEVerifier.sol';
import { BufferConfig } from '../../src/bridge/DelayBufferTypes.sol';
contract RollupMock {
  address public immutable owner;

  constructor(address _owner) {
    owner = _owner;
  }
}

contract SequencerInboxBlobsTEE is Test {
  address adminTEE = address(141);
  address rollupOwner = address(137);
  address proxyAdmin = address(140);
  address dummyInbox = address(139);

  uint256 maxDataSize = 10000;
  ISequencerInbox.MaxTimeVariation maxTimeVariation =
    ISequencerInbox.MaxTimeVariation({
      delayBlocks: 10,
      futureBlocks: 10,
      delaySeconds: 100,
      futureSeconds: 100
    });
  bytes sampleQuote = hex'00';
  IEspressoTEEVerifier espressoTEEVerifier;
  function setUp() public {
    vm.startPrank(adminTEE);
    espressoTEEVerifier = new EspressoTEEVerifierBlobsMock();
    string memory quotePath = '/test/foundry/configs/blobs_attestation.bin';
    string memory inputFile = string.concat(vm.projectRoot(), quotePath);
    sampleQuote = vm.readFileBinary(inputFile);
    vm.stopPrank();
  }

  function deployRollup() internal returns (SequencerInbox, Bridge) {
    RollupMock rollupMock = new RollupMock(rollupOwner);
    Bridge bridgeImpl = new Bridge();
    Bridge bridge = Bridge(
      address(
        new TransparentUpgradeableProxy(address(bridgeImpl), proxyAdmin, '')
      )
    );

    bridge.initialize(IOwnable(address(rollupMock)));
    vm.prank(rollupOwner);
    bridge.setDelayedInbox(dummyInbox, true);
    // we created a mock reader4844 which returns the data hashes related to the attestation we are using
    // for testing
    Reader4844 reader4844 = new Reader4844();
    SequencerInbox seqInboxImpl = new SequencerInbox(
      maxDataSize,
      reader4844,
      false,
      false
    );
    SequencerInbox seqInboxProxy = SequencerInbox(
      TestUtil.deployProxy(address(seqInboxImpl))
    );

    BufferConfig memory bufferConfigDefault = BufferConfig({
      threshold: type(uint64).max,
      max: type(uint64).max,
      replenishRateInBasis: 714
    });
    seqInboxProxy.initialize(
      IBridge(bridge),
      maxTimeVariation,
      bufferConfigDefault,
      address(espressoTEEVerifier)
    );

    vm.prank(rollupOwner);
    seqInboxProxy.setIsBatchPoster(tx.origin, true);

    vm.prank(rollupOwner);
    bridge.setSequencerInbox(address(seqInboxProxy));

    return (seqInboxProxy, bridge);
  }

  function testAddSequencerL2BatchFromBlobs() public {
    vm.prank(rollupOwner);
    (SequencerInbox seqInbox, Bridge bridge) = deployRollup();
    uint256 sequenceNumber = 1;
    uint256 afterDelayedMessagesRead = 3;
    IGasRefunder gasRefunder = IGasRefunder(address(0));
    uint256 prevMessageCount = 1;
    uint256 newMessageCount = 3;

    vm.prank(tx.origin);
    vm.expectRevert();

    //  We expect the TEE attestation quote to be validated
    vm.expectEmit();
    emit ISequencerInbox.TEEAttestationQuoteVerified(sequenceNumber);
    seqInbox.addSequencerL2BatchFromBlobs(
      sequenceNumber,
      afterDelayedMessagesRead,
      gasRefunder,
      prevMessageCount,
      newMessageCount,
      sampleQuote
    );
  }
}

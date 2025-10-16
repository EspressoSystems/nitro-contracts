// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "./util/TestUtil.sol";
import "../../src/bridge/Bridge.sol";
import "../../src/bridge/SequencerInbox.sol";
import {Reader4844} from "../../src/mocks/Reader4844.sol";
import {IGasRefunder} from "../../src/libraries/IGasRefunder.sol";
// import {EspressoTEEVerifierBlobsMock} from "../../src/mocks/EspressoTEEVerifierBlobsMock.sol";
import {EspressoTEEVerifier} from "../../lib/espresso-tee-contracts/src/EspressoTEEVerifier.sol";
import {EspressoSGXTEEVerifier} from
    "../../lib/espresso-tee-contracts/src/EspressoSGXTEEVerifier.sol";
import {IEspressoTEEVerifier} from
    "../../lib/espresso-tee-contracts/src/interface/IEspressoTEEVerifier.sol";
import {IEspressoNitroTEEVerifier} from
    "../../lib/espresso-tee-contracts/src/interface/IEspressoNitroTEEVerifier.sol";
import {EspressoNitroTEEVerifier} from
    "../../lib/espresso-tee-contracts/src/EspressoNitroTEEVerifier.sol";

import {CertManager} from "@nitro-validator/CertManager.sol";

contract RollupMock {
    address public immutable owner;

    constructor(
        address _owner
    ) {
        owner = _owner;
    }
}

contract SequencerInboxBlobsTEE is Test {
    address adminTEE = address(141);
    address rollupOwner = address(137);
    address proxyAdmin = address(140);
    address dummyInbox = address(139);
    address v3QuoteVerifier = address(0x6E64769A13617f528a2135692484B681Ee1a7169);
    bytes32 enclaveHash =
        bytes32(0x01f7290cb6bbaa427eca3daeb25eecccb87c4b61259b1ae2125182c4d77169c0);
    address signerAddr = address(0x5f0B0D79E7F051903b08E30a3d6eA50D80333932);
    bytes32 pcr0Hash = bytes32(0xc980e59163ce244bb4bb6211f48c7b46f88a4f40943e84eb99bdc41e129bd293);

    uint256 maxDataSize = 10000;
    ISequencerInbox.MaxTimeVariation maxTimeVariation = ISequencerInbox.MaxTimeVariation({
        delayBlocks: 10,
        futureBlocks: 10,
        delaySeconds: 100,
        futureSeconds: 100
    });
    bytes sampleQuote = hex"00";
    EspressoTEEVerifier espressoTEEVerifier;
    EspressoNitroTEEVerifier espressoNitroTEEVerifier;
    EspressoSGXTEEVerifier espressoSGXTEEVerifier;

    address reader4844 = address(0xf6134C5849Fe8177163747288d41283B271B1624);

    function setUp() public {
        vm.createSelectFork(
            "https://rpc.ankr.com/eth_sepolia/10a56026b3c20655c1dab931446156dea4d63d87d1261934c82a1b8045885923"
        );
        espressoSGXTEEVerifier = new EspressoSGXTEEVerifier(enclaveHash, v3QuoteVerifier);
        espressoNitroTEEVerifier = new EspressoNitroTEEVerifier(pcr0Hash, new CertManager());
        espressoTEEVerifier =
            new EspressoTEEVerifier(espressoSGXTEEVerifier, espressoNitroTEEVerifier);
        string memory quotePath = "/test/foundry/configs/blobs_attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);

        sampleQuote = vm.readFileBinary(inputFile);

        vm.warp(1_744_220_000);
        string memory attestationPath = "/test/foundry/configs/nitro-attestation.bin";
        string memory attestationFile = string.concat(vm.projectRoot(), attestationPath);
        bytes memory attestation = vm.readFileBinary(attestationFile);

        string memory signaturePath = "/test/foundry/configs/sig-attestation.bin";
        string memory sigFile = string.concat(vm.projectRoot(), signaturePath);
        bytes memory signature = vm.readFileBinary(sigFile);

        vm.expectEmit();
        emit IEspressoNitroTEEVerifier.AWSSignerRegistered(signerAddr, pcr0Hash);
        espressoTEEVerifier.registerSigner(
            attestation, signature, IEspressoTEEVerifier.TeeType.NITRO
        );
        bool value =
            espressoTEEVerifier.registeredSigners(signerAddr, IEspressoTEEVerifier.TeeType.NITRO);
        vm.assertEq(value, true);
    }

    function deployRollup() internal returns (SequencerInbox, Bridge) {
        RollupMock rollupMock = new RollupMock(rollupOwner);
        Bridge bridgeImpl = new Bridge();
        Bridge bridge =
            Bridge(address(new TransparentUpgradeableProxy(address(bridgeImpl), proxyAdmin, "")));

        bridge.initialize(IOwnable(address(rollupMock)));
        vm.prank(rollupOwner);
        bridge.setDelayedInbox(dummyInbox, true);
        // we created a mock reader4844 which returns the data hashes related to the attestation we are using
        // for testing
        Reader4844 reader4844 = new Reader4844();
        SequencerInbox seqInboxImpl = new SequencerInbox(maxDataSize, reader4844, false, false);
        SequencerInbox seqInboxProxy = SequencerInbox(TestUtil.deployProxy(address(seqInboxImpl)));
        BufferConfig memory bufferConfigDefault = BufferConfig({
            threshold: type(uint64).max,
            max: type(uint64).max,
            replenishRateInBasis: 714
        });
        seqInboxProxy.initialize(
            IBridge(bridge), maxTimeVariation, bufferConfigDefault, address(espressoTEEVerifier)
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
        uint256 hotshotHeight = 123;
        bytes32[] memory dataHashes = new bytes32[](1);
        dataHashes[0] = hex"014e8e17947683a76729b8efd62f59785227e0011c4ace32d7887589acd46ee7";

        vm.prank(tx.origin);
        vm.expectRevert();
        vm.expectEmit();
        emit ISequencerInbox.LastHotshotHeight(sequenceNumber, hotshotHeight);
        seqInbox.addSequencerL2BatchFromBlobs(
            sequenceNumber,
            afterDelayedMessagesRead,
            gasRefunder,
            prevMessageCount,
            newMessageCount,
            hotshotHeight
        );
        vm.stopPrank();
    }
}

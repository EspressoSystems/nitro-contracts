// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "./util/TestUtil.sol";
import "../../src/bridge/Bridge.sol";
import "../../src/bridge/SequencerInbox.sol";
import {Reader4844} from "../../src/mocks/Reader4844.sol";
import {IGasRefunder} from "../../src/libraries/IGasRefunder.sol";
import {EspressoTEEVerifier} from "espresso-tee-contracts/EspressoTEEVerifier.sol";
import {IEspressoTEEVerifier} from "espresso-tee-contracts/interface/IEspressoTEEVerifier.sol";
import {IEspressoNitroTEEVerifier} from
    "espresso-tee-contracts/interface/IEspressoNitroTEEVerifier.sol";
import {EspressoNitroTEEVerifier} from "espresso-tee-contracts/EspressoNitroTEEVerifier.sol";
import {ITEEHelper} from "espresso-tee-contracts/interface/ITEEHelper.sol";

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
    bytes32 pcr0Hash = bytes32(0xc980e59163ce244bb4bb6211f48c7b46f88a4f40943e84eb99bdc41e129bd293);

    // NitroEnclaveVerifier deployed on Sepolia
    address nitroEnclaveVerifierAddr = address(0x2D7fbBAD6792698Ba92e67b7e180f8010B9Ec788);

    uint256 maxDataSize = 10000;
    ISequencerInbox.MaxTimeVariation maxTimeVariation = ISequencerInbox.MaxTimeVariation({
        delayBlocks: 10,
        futureBlocks: 10,
        delaySeconds: 100,
        futureSeconds: 100
    });
    EspressoTEEVerifier espressoTEEVerifier;
    EspressoNitroTEEVerifier espressoNitroTEEVerifier;

    uint256 awsNitroPrivateKey =
        0x43179a4cba1a7fa58e6faad5cda5036169320c1a0c17b9f9488fb17acecaa23d;

    // EIP-712 type hash used by EspressoTEEVerifier.verify()
    bytes32 constant ESPRESSO_TEE_VERIFIER_TYPE_HASH =
        keccak256("EspressoTEEVerifier(bytes32 commitment)");

    /// @dev Compute the EIP-712 digest that EspressoTEEVerifier.verify() uses
    function _computeEIP712Digest(bytes32 reportDataHash) internal view returns (bytes32) {
        bytes32 structHash =
            keccak256(abi.encode(ESPRESSO_TEE_VERIFIER_TYPE_HASH, reportDataHash));
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("EspressoTEEVerifier"),
                keccak256("1"),
                block.chainid,
                address(espressoTEEVerifier)
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function setUp() public {
        vm.createSelectFork(
            "https://rpc.ankr.com/eth_sepolia/10a56026b3c20655c1dab931446156dea4d63d87d1261934c82a1b8045885923"
        );

        // Ensure NitroEnclaveVerifier has code on the fork
        if (nitroEnclaveVerifierAddr.code.length == 0) {
            vm.etch(nitroEnclaveVerifierAddr, hex"00");
        }

        // Deploy EspressoTEEVerifier behind an upgradeable proxy
        EspressoTEEVerifier teeImpl = new EspressoTEEVerifier();
        espressoTEEVerifier = EspressoTEEVerifier(
            address(
                new TransparentUpgradeableProxy(
                    address(teeImpl),
                    proxyAdmin,
                    abi.encodeCall(
                        EspressoTEEVerifier.initialize,
                        (adminTEE, IEspressoNitroTEEVerifier(address(0xBEEF)))
                    )
                )
            )
        );

        // Deploy EspressoNitroTEEVerifier pointing to the TEE verifier proxy
        espressoNitroTEEVerifier = new EspressoNitroTEEVerifier(
            address(espressoTEEVerifier), nitroEnclaveVerifierAddr
        );

        // Wire the real nitro verifier and register enclave hash
        vm.startPrank(adminTEE);
        espressoTEEVerifier.setEspressoNitroTEEVerifier(
            IEspressoNitroTEEVerifier(address(espressoNitroTEEVerifier))
        );
        espressoTEEVerifier.setEnclaveHash(pcr0Hash, true, IEspressoTEEVerifier.TeeType.NITRO);
        vm.stopPrank();

        // Mock the Nitro signer as valid
        address nitroSignerAddr = vm.addr(awsNitroPrivateKey);
        vm.mockCall(
            address(espressoNitroTEEVerifier),
            abi.encodeWithSelector(ITEEHelper.isSignerValid.selector, nitroSignerAddr),
            abi.encode(true)
        );
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
            IBridge(bridge),
            maxTimeVariation,
            bufferConfigDefault,
            IFeeTokenPricer(address(0)),
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
        uint256 hotshotHeight = 123;
        bytes32[] memory dataHashes = new bytes32[](1);
        dataHashes[0] = hex"014e8e17947683a76729b8efd62f59785227e0011c4ace32d7887589acd46ee7";
        bytes32 reportDataHash = keccak256(
            abi.encode(
                sequenceNumber,
                afterDelayedMessagesRead,
                address(gasRefunder),
                prevMessageCount,
                newMessageCount,
                abi.encode(dataHashes),
                hotshotHeight
            )
        );

        vm.prank(tx.origin);
        vm.expectRevert();

        // Sign with EIP-712 typed data
        bytes32 digest = _computeEIP712Digest(reportDataHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(awsNitroPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes memory espressoMetadata =
            abi.encode(hotshotHeight, signature, IEspressoTEEVerifier.TeeType.NITRO);

        vm.expectEmit();
        emit ISequencerInbox.TEESignatureVerified(sequenceNumber, hotshotHeight);
        seqInbox.addSequencerL2BatchFromBlobs(
            sequenceNumber,
            afterDelayedMessagesRead,
            gasRefunder,
            prevMessageCount,
            newMessageCount,
            espressoMetadata
        );
        vm.stopPrank();
    }
}

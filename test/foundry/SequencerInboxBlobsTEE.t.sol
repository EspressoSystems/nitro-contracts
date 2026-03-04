// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "./util/TestUtil.sol";
import "../../src/bridge/Bridge.sol";
import "../../src/bridge/SequencerInbox.sol";
import {Reader4844} from "../../src/mocks/Reader4844.sol";
import {IGasRefunder} from "../../src/libraries/IGasRefunder.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEspressoTEEVerifier} from "espresso-tee-contracts/interface/IEspressoTEEVerifier.sol";
import {ServiceType} from "espresso-tee-contracts/types/Types.sol";

contract TEEVerifierMockBlobs {
    mapping(uint8 => mapping(address => bool)) private _signers;

    function addSigner(address signer, IEspressoTEEVerifier.TeeType teeType) external {
        _signers[uint8(teeType)][signer] = true;
    }

    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        IEspressoTEEVerifier.TeeType teeType,
        ServiceType
    ) external view returns (bool) {
        address signer = ECDSA.recover(userDataHash, signature);
        if (!_signers[uint8(teeType)][signer]) {
            revert IEspressoTEEVerifier.InvalidSignature();
        }
        return true;
    }
}

contract RollupMock {
    address public immutable owner;

    constructor(
        address _owner
    ) {
        owner = _owner;
    }
}

contract SequencerInboxBlobsTEE is Test {
    address rollupOwner = address(137);
    address proxyAdmin = address(140);
    address dummyInbox = address(139);
    address signerAddr = address(0x5f0B0D79E7F051903b08E30a3d6eA50D80333932);

    uint256 maxDataSize = 10000;
    ISequencerInbox.MaxTimeVariation maxTimeVariation = ISequencerInbox.MaxTimeVariation({
        delayBlocks: 10,
        futureBlocks: 10,
        delaySeconds: 100,
        futureSeconds: 100
    });
    TEEVerifierMockBlobs espressoTEEVerifier;

    function setUp() public {
        espressoTEEVerifier = new TEEVerifierMockBlobs();
        espressoTEEVerifier.addSigner(signerAddr, IEspressoTEEVerifier.TeeType.NITRO);
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

        uint256 awsNitroPrivateKey =
            0x43179a4cba1a7fa58e6faad5cda5036169320c1a0c17b9f9488fb17acecaa23d;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(awsNitroPrivateKey, reportDataHash);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "./util/TestUtil.sol";
import "../../src/bridge/Bridge.sol";
import "../../src/bridge/SequencerInbox.sol";
import "../../src/bridge/ISequencerInbox.sol";
import "../../src/libraries/IReader4844.sol";
import {
    EspressoTEEVerifierMock,
    EspressoTEEVerifierMockFalse,
    EspressoTEEVerifierMockRevert
} from "./EspressoTEEVerifierMock.t.sol";
import {IEspressoTEEVerifier} from "../../src/bridge/EspressoTEE.sol";
import {TEEVerificationFailed} from "../../src/libraries/Error.sol";
import {
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @notice Mock Reader4844 that returns configurable blob data hashes
 */
contract Reader4844Mock is IReader4844 {
    bytes32[] private _dataHashes;
    uint256 private _blobBaseFee;

    constructor() {
        // Set default blob data hash
        _dataHashes.push(bytes32(0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef));
        _blobBaseFee = 1 gwei;
    }

    function setDataHashes(bytes32[] memory dataHashes_) external {
        delete _dataHashes;
        for (uint256 i = 0; i < dataHashes_.length; i++) {
            _dataHashes.push(dataHashes_[i]);
        }
    }

    function setBlobBaseFee(uint256 fee) external {
        _blobBaseFee = fee;
    }

    function getBlobBaseFee() external view override returns (uint256) {
        return _blobBaseFee;
    }

    function getDataHashes() external view override returns (bytes32[] memory) {
        return _dataHashes;
    }
}

contract RollupMock {
    address public immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

contract SequencerInboxBlobsTEETest is Test {
    address rollupOwner = address(137);
    uint256 maxDataSize = 10000;
    ISequencerInbox.MaxTimeVariation maxTimeVariation =
        ISequencerInbox.MaxTimeVariation({
            delayBlocks: 10,
            futureBlocks: 10,
            delaySeconds: 100,
            futureSeconds: 100
        });
    address dummyInbox = address(139);
    address proxyAdmin = address(140);

    Reader4844Mock reader4844Mock;

    function setUp() public {
        reader4844Mock = new Reader4844Mock();
    }

    function deployRollupWithVerifier(address verifier) internal returns (SequencerInbox, Bridge) {
        RollupMock rollupMock = new RollupMock(rollupOwner);
        Bridge bridgeImpl = new Bridge();
        Bridge bridge = Bridge(
            address(new TransparentUpgradeableProxy(address(bridgeImpl), proxyAdmin, ""))
        );

        bridge.initialize(IOwnable(address(rollupMock)));
        vm.prank(rollupOwner);
        bridge.setDelayedInbox(dummyInbox, true);

        SequencerInbox seqInboxImpl = new SequencerInbox(
            maxDataSize,
            IReader4844(address(reader4844Mock)),
            false
        );
        SequencerInbox seqInbox = SequencerInbox(
            address(new TransparentUpgradeableProxy(address(seqInboxImpl), proxyAdmin, ""))
        );
        seqInbox.initialize(bridge, maxTimeVariation, verifier);

        vm.prank(rollupOwner);
        seqInbox.setIsBatchPoster(address(this), true);

        vm.prank(rollupOwner);
        bridge.setSequencerInbox(address(seqInbox));

        return (seqInbox, bridge);
    }

    /**
     * @notice Test that TEESignatureVerified event is emitted when verify returns true for blob batch
     */
    function test_TEESignatureVerified_WhenBlobVerifyReturnsTrue() public {
        EspressoTEEVerifierMock verifier = new EspressoTEEVerifierMock();
        (SequencerInbox seqInbox, ) = deployRollupWithVerifier(address(verifier));

        uint256 sequenceNumber = 0;
        uint256 afterDelayedMessagesRead = 0;
        uint256 prevMessageCount = 0;
        uint256 newMessageCount = 1;
        uint256 hotshotHeight = 123;
        bytes memory signature = hex"";

        bytes memory espressoMetadata = abi.encode(
            hotshotHeight,
            signature,
            IEspressoTEEVerifier.TeeType.SGX
        );

        // Expect the TEESignatureVerified event to be emitted
        vm.expectEmit();
        emit ISequencerInbox.TEESignatureVerified(sequenceNumber, hotshotHeight);

        seqInbox.addSequencerL2BatchFromBlobs(
            sequenceNumber,
            afterDelayedMessagesRead,
            IGasRefunder(address(0)),
            prevMessageCount,
            newMessageCount,
            espressoMetadata
        );
    }

    /**
     * @notice Test that transaction reverts when verify returns false for blob batch
     */
    function test_Revert_WhenBlobVerifyReturnsFalse() public {
        EspressoTEEVerifierMockFalse verifier = new EspressoTEEVerifierMockFalse();
        (SequencerInbox seqInbox, ) = deployRollupWithVerifier(address(verifier));

        uint256 sequenceNumber = 0;
        uint256 afterDelayedMessagesRead = 0;
        uint256 prevMessageCount = 0;
        uint256 newMessageCount = 1;
        uint256 hotshotHeight = 123;
        bytes memory signature = hex"";

        bytes memory espressoMetadata = abi.encode(
            hotshotHeight,
            signature,
            IEspressoTEEVerifier.TeeType.SGX
        );

        // Transaction should revert when verify returns false
        vm.expectRevert(TEEVerificationFailed.selector);
        seqInbox.addSequencerL2BatchFromBlobs(
            sequenceNumber,
            afterDelayedMessagesRead,
            IGasRefunder(address(0)),
            prevMessageCount,
            newMessageCount,
            espressoMetadata
        );
    }

    /**
     * @notice Test that transaction reverts when verify function reverts for blob batch
     */
    function test_Revert_WhenBlobVerifyReverts() public {
        EspressoTEEVerifierMockRevert verifier = new EspressoTEEVerifierMockRevert();
        (SequencerInbox seqInbox, ) = deployRollupWithVerifier(address(verifier));

        uint256 sequenceNumber = 0;
        uint256 afterDelayedMessagesRead = 0;
        uint256 prevMessageCount = 0;
        uint256 newMessageCount = 1;
        uint256 hotshotHeight = 123;
        bytes memory signature = hex"";

        bytes memory espressoMetadata = abi.encode(
            hotshotHeight,
            signature,
            IEspressoTEEVerifier.TeeType.SGX
        );

        // Transaction should revert when verify function reverts
        vm.expectRevert(EspressoTEEVerifierMockRevert.InvalidSignature.selector);
        seqInbox.addSequencerL2BatchFromBlobs(
            sequenceNumber,
            afterDelayedMessagesRead,
            IGasRefunder(address(0)),
            prevMessageCount,
            newMessageCount,
            espressoMetadata
        );
    }
}

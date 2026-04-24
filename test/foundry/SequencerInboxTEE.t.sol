// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "./util/TestUtil.sol";
import "../../src/bridge/Bridge.sol";
import "../../src/bridge/SequencerInbox.sol";
import "../../src/bridge/ISequencerInbox.sol";
import {
    EspressoTEEVerifierMock,
    EspressoTEEVerifierMockFalse,
    EspressoTEEVerifierMockRevert
} from "./EspressoTEEVerifierMock.t.sol";
import {IEspressoTEEVerifier} from "@espresso-tee/interface/IEspressoTEEVerifier.sol";
import {TEEVerificationFailed} from "../../src/libraries/Error.sol";
import {
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract RollupMock {
    address public immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

contract SequencerInboxTEETest is Test {
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
    IReader4844 dummyReader4844 = IReader4844(address(137));

    bytes sampleData = hex"0042";

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
            dummyReader4844,
            false
        );
        SequencerInbox seqInbox = SequencerInbox(
            address(new TransparentUpgradeableProxy(address(seqInboxImpl), proxyAdmin, ""))
        );
        seqInbox.initialize(bridge, maxTimeVariation, verifier);

        vm.prank(rollupOwner);
        seqInbox.setIsBatchPoster(tx.origin, true);

        vm.prank(rollupOwner);
        bridge.setSequencerInbox(address(seqInbox));

        return (seqInbox, bridge);
    }

    /**
     * @notice Test that TEESignatureVerified event is emitted when verify returns true
     */
    function test_TEESignatureVerified_WhenVerifyReturnsTrue() public {
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
            IEspressoTEEVerifier.TeeType.NITRO
        );

        // Expect the TEESignatureVerified event to be emitted
        vm.expectEmit();
        emit ISequencerInbox.TEESignatureVerified(sequenceNumber, hotshotHeight);

        vm.prank(tx.origin);
        seqInbox.addSequencerL2BatchFromOrigin(
            sequenceNumber,
            sampleData,
            afterDelayedMessagesRead,
            IGasRefunder(address(0)),
            prevMessageCount,
            newMessageCount,
            espressoMetadata
        );
    }

    /**
     * @notice Test that transaction reverts when verify returns false
     * @dev When verify returns false, the SequencerInbox should revert
     */
    function test_Revert_WhenVerifyReturnsFalse() public {
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
            IEspressoTEEVerifier.TeeType.NITRO
        );

        // Transaction should revert when verify returns false
        vm.prank(tx.origin);
        vm.expectRevert(TEEVerificationFailed.selector);
        seqInbox.addSequencerL2BatchFromOrigin(
            sequenceNumber,
            sampleData,
            afterDelayedMessagesRead,
            IGasRefunder(address(0)),
            prevMessageCount,
            newMessageCount,
            espressoMetadata
        );
    }

    /**
     * @notice Test that transaction reverts when verify function reverts
     */
    function test_Revert_WhenVerifyReverts() public {
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
            IEspressoTEEVerifier.TeeType.NITRO
        );

        // Transaction should revert when verify function reverts
        vm.prank(tx.origin);
        vm.expectRevert(IEspressoTEEVerifier.InvalidSignature.selector);
        seqInbox.addSequencerL2BatchFromOrigin(
            sequenceNumber,
            sampleData,
            afterDelayedMessagesRead,
            IGasRefunder(address(0)),
            prevMessageCount,
            newMessageCount,
            espressoMetadata
        );
    }
}

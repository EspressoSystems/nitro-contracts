// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "./util/TestUtil.sol";
import "../../src/bridge/Bridge.sol";
import "../../src/bridge/SequencerInbox.sol";
import {NotOwner, InvalidCasCertificate} from "../../src/libraries/Error.sol";
import {IEspressoTEEVerifier} from "../../src/espresso/IEspressoTEEVerifier.sol";
import {IEspressoNitroTEEVerifier} from "../../src/espresso/IEspressoNitroTEEVerifier.sol";
import {EspressoTEEVerifierMock} from "../../src/espresso/mocks/EspressoTEEVerifierMock.sol";
import {EspressoNitroTEEVerifierMock} from
    "../../src/espresso/mocks/EspressoNitroTEEVerifierMock.sol";

contract EspressoRollupMock {
    address public immutable owner;

    constructor(
        address _owner
    ) {
        owner = _owner;
    }
}

contract SequencerInboxEspressoTest is Test {
    event SequencerBatchDelivered(
        uint256 indexed batchSequenceNumber,
        bytes32 indexed beforeAcc,
        bytes32 indexed afterAcc,
        bytes32 delayedAcc,
        uint256 afterDelayedMessagesRead,
        IBridge.TimeBounds timeBounds,
        IBridge.BatchDataLocation dataLocation
    );
    event SequencerBatchData(uint256 indexed batchSequenceNumber, bytes data);
    event EspressoCertificateVerified(uint256 hotshotBlock, uint256 delayedMessageRead, uint256 messageCount);
    event EspressoTEEVerifierSet(address espressoTEEVerifier);

    uint256 constant SIGNER_PK = 0xA11CE;
    uint256 constant OTHER_PK = 0xBEEF;
    uint256 constant MAX_DATA_SIZE = 117964;

    bytes32 constant ESPRESSO_TEE_VERIFIER_TYPE_HASH =
        keccak256("EspressoTEEVerifier(bytes32 commitment)");

    address rollupOwner = address(137);
    address proxyAdmin = address(140);
    address dummyInbox = address(139);
    IReader4844 dummyReader4844 = IReader4844(address(137));

    ISequencerInbox.MaxTimeVariation maxTimeVariation = ISequencerInbox.MaxTimeVariation({
        delayBlocks: 10,
        futureBlocks: 10,
        delaySeconds: 100,
        futureSeconds: 100
    });

    EspressoNitroTEEVerifierMock nitroMock;
    EspressoTEEVerifierMock teeVerifierMock;
    address signer;

    // ── Helpers ────────────────────────────────────────────────────────

    function _registerSigner(
        address _signer
    ) internal {
        nitroMock.setSignerValid(_signer, true);
    }

    /// @dev Compute the EIP-712 digest that the EspressoTEEVerifierMock will
    ///      reconstruct, then sign it with `pk`.
    function _signPayload(
        uint256 pk,
        bytes32 userDataHash
    ) internal view returns (bytes memory signature) {
        bytes32 structHash = keccak256(abi.encode(ESPRESSO_TEE_VERIFIER_TYPE_HASH, userDataHash));

        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("EspressoTEEVerifier"),
                keccak256("1"),
                block.chainid,
                address(teeVerifierMock)
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        signature = abi.encodePacked(r, s, v);
    }

    /// @dev Build the full certificate data that SequencerInbox expects.
    ///      Layout: [0..31] CAS header | [32..39] startMessagePos |
    ///              [40..47] endMessagePos | [48..55] hotshotBlock |
    ///              [56..63] afterDelayedMessagesRead | [64..71] minHotshotBlock |
    ///              [72..136] signature | [137+] downstreamCert
    function _buildCertData(
        uint64 startMessagePos,
        uint64 endMessagePos,
        uint64 startHotshotBlock_,
        uint64 afterDelayedMessagesRead,
        uint64 minHotshotBlock,
        bytes memory signature,
        bytes memory downstreamCert
    ) internal pure returns (bytes memory) {
        // CAS header: 32 bytes, first byte = 0x70
        bytes memory casHeader = new bytes(32);
        casHeader[0] = 0x70;

        return abi.encodePacked(
            casHeader,
            bytes8(startMessagePos),
            bytes8(endMessagePos),
            bytes8(startHotshotBlock_),
            bytes8(afterDelayedMessagesRead),
            bytes8(minHotshotBlock),
            signature,
            downstreamCert
        );
    }

    /// @dev Compute the canonical payload hash that the signer must commit to.
    function _computeUserDataHash(
        uint256 prevMsgCount,
        uint256 newMsgCount,
        uint64 _startHotshotBlock,
        uint256 afterDelayedMessagesRead,
        uint64 minHotshotBlock,
        bytes memory downstreamCert
    ) internal pure returns (bytes32) {
        bytes memory payload = abi.encodePacked(
            uint64(prevMsgCount),
            uint64(newMsgCount),
            _startHotshotBlock,
            uint64(afterDelayedMessagesRead),
            minHotshotBlock,
            downstreamCert
        );
        return keccak256(payload);
    }

    /// @dev Deploy Bridge + SequencerInbox with espresso TEE verifier enabled.
    function _deployEspressoRollup() internal returns (SequencerInbox seqInbox, Bridge bridge) {
        EspressoRollupMock rollupMock = new EspressoRollupMock(rollupOwner);

        Bridge bridgeImpl = new Bridge();
        bridge =
            Bridge(address(new TransparentUpgradeableProxy(address(bridgeImpl), proxyAdmin, "")));
        bridge.initialize(IOwnable(address(rollupMock)));
        vm.prank(rollupOwner);
        bridge.setDelayedInbox(dummyInbox, true);

        SequencerInbox seqInboxImpl =
            new SequencerInbox(MAX_DATA_SIZE, dummyReader4844, false);
        seqInbox = SequencerInbox(
            address(new TransparentUpgradeableProxy(address(seqInboxImpl), proxyAdmin, ""))
        );

        seqInbox.initialize(bridge, maxTimeVariation, address(teeVerifierMock));

        vm.prank(rollupOwner);
        seqInbox.setIsBatchPoster(tx.origin, true);

        vm.prank(rollupOwner);
        bridge.setSequencerInbox(address(seqInbox));
    }

    /// @dev Enqueue a delayed message so that addSequencerL2Batch can reference it.
    function _enqueueDelayed(
        Bridge bridge
    ) internal {
        vm.prank(dummyInbox);
        bridge.enqueueDelayedMessage(3, address(140), keccak256("delayed"));
    }

    /// @dev Build valid espresso cert data, sign it properly, and return everything
    ///      needed to call addSequencerL2Batch.
    function _prepareValidBatch(
        SequencerInbox seqInbox,
        Bridge bridge,
        uint64 hotshotBlock,
        uint64 minHotshotBlock,
        bytes memory downstreamCert
    )
        internal
        view
        returns (
            bytes memory data,
            uint256 sequenceNumber,
            uint256 delayedMessagesRead,
            uint256 prevMsgCount,
            uint256 newMsgCount
        )
    {
        prevMsgCount = bridge.sequencerReportedSubMessageCount();
        newMsgCount = prevMsgCount + 1;
        delayedMessagesRead = bridge.delayedMessageCount();
        sequenceNumber = bridge.sequencerMessageCount();

        bytes32 userDataHash = _computeUserDataHash(
            prevMsgCount,
            newMsgCount,
            hotshotBlock,
            delayedMessagesRead,
            minHotshotBlock,
            downstreamCert
        );

        bytes memory sig = _signPayload(SIGNER_PK, userDataHash);
        data = _buildCertData(
            uint64(prevMsgCount),
            uint64(newMsgCount),
            hotshotBlock,
            uint64(delayedMessagesRead),
            minHotshotBlock,
            sig,
            downstreamCert
        );
    }

    function setUp() public {
        signer = vm.addr(SIGNER_PK);

        nitroMock = new EspressoNitroTEEVerifierMock();
        teeVerifierMock = new EspressoTEEVerifierMock(IEspressoNitroTEEVerifier(address(nitroMock)));

        _registerSigner(signer);
    }

    function testAddBatchWithValidEspressoCert() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"00deadbeef";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, 0, 1, downstream);

        uint256 countBefore = bridge.sequencerMessageCount();

        vm.prank(tx.origin);
        seqInbox.addSequencerL2Batch(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );

        assertEq(bridge.sequencerMessageCount(), countBefore + 1, "batch not accepted");
    }

    function testAddBatchFromOriginWithValidEspressoCert() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"00deadbeef";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, 0, 1, downstream);

        uint256 countBefore = bridge.sequencerMessageCount();

        vm.prank(tx.origin);
        seqInbox.addSequencerL2BatchFromOrigin(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );

        assertEq(bridge.sequencerMessageCount(), countBefore + 1, "batch not accepted");
    }

    function testRevertUnregisteredSigner() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        // Use OTHER_PK whose address is NOT registered in the NitroMock
        uint256 prevMsg = bridge.sequencerReportedSubMessageCount();
        uint256 newMsg = prevMsg + 1;
        uint256 delayedRead = bridge.delayedMessageCount();
        uint256 seqNum = bridge.sequencerMessageCount();
        bytes memory downstream = hex"deadbeef";

        bytes32 userDataHash = _computeUserDataHash(
            prevMsg, newMsg, 0, delayedRead, 1, downstream
        );

        // Sign with unregistered key
        bytes memory sig = _signPayload(OTHER_PK, userDataHash);
        bytes memory data = _buildCertData(
            uint64(prevMsg),
            uint64(newMsg),
            0,
            uint64(delayedRead),
            1,
            sig,
            downstream
        );

        vm.expectRevert(IEspressoTEEVerifier.InvalidSignature.selector);
        vm.prank(tx.origin);
        seqInbox.addSequencerL2Batch(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testRevertCertTooShort() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        uint256 prevMsg = bridge.sequencerReportedSubMessageCount();
        uint256 newMsg = prevMsg + 1;
        uint256 delayedRead = bridge.delayedMessageCount();
        uint256 seqNum = bridge.sequencerMessageCount();

        // Build data shorter than 137 bytes but with valid CAS header flag
        bytes memory shortData = new bytes(136);
        shortData[0] = 0x70;

        vm.expectRevert(InvalidCasCertificate.selector);
        vm.prank(tx.origin);
        seqInbox.addSequencerL2Batch(
            seqNum, shortData, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testEspressoCertificateVerifiedEvent() public {
        uint64 hotshotBlock = 5;

        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"00cafe";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, hotshotBlock, 10, downstream);

        vm.expectEmit(false, false, false, true, address(seqInbox));
        emit EspressoCertificateVerified(hotshotBlock, delayedRead, newMsg);

        vm.prank(tx.origin);
        seqInbox.addSequencerL2Batch(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testCertStrippedFromBatchDataEvent() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"00aabbccdd";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, 0, 1, downstream);

        // Expect SequencerBatchData to contain only the downstream cert (data[137:])
        vm.expectEmit(true, false, false, true, address(seqInbox));
        emit SequencerBatchData(seqNum, downstream);

        vm.prank(tx.origin);
        seqInbox.addSequencerL2Batch(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testFromOriginRevertUnregisteredSigner() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        uint256 prevMsg = bridge.sequencerReportedSubMessageCount();
        uint256 newMsg = prevMsg + 1;
        uint256 delayedRead = bridge.delayedMessageCount();
        uint256 seqNum = bridge.sequencerMessageCount();
        bytes memory downstream = hex"deadbeef";

        bytes32 userDataHash = _computeUserDataHash(
            prevMsg, newMsg, 0, delayedRead, 1, downstream
        );

        bytes memory sig = _signPayload(OTHER_PK, userDataHash);
        bytes memory data = _buildCertData(
            uint64(prevMsg),
            uint64(newMsg),
            0,
            uint64(delayedRead),
            1,
            sig,
            downstream
        );

        vm.expectRevert(IEspressoTEEVerifier.InvalidSignature.selector);
        vm.prank(tx.origin);
        seqInbox.addSequencerL2BatchFromOrigin(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testFromOriginRevertCertTooShort() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        uint256 prevMsg = bridge.sequencerReportedSubMessageCount();
        uint256 newMsg = prevMsg + 1;
        uint256 delayedRead = bridge.delayedMessageCount();
        uint256 seqNum = bridge.sequencerMessageCount();

        bytes memory shortData = new bytes(136);
        shortData[0] = 0x70;

        vm.expectRevert(InvalidCasCertificate.selector);
        vm.prank(tx.origin);
        seqInbox.addSequencerL2BatchFromOrigin(
            seqNum, shortData, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testFromOriginCertVerifiedEvent() public {
        uint64 hotshotBlock = 42;

        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"00cafe";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, hotshotBlock, 10, downstream);

        vm.expectEmit(false, false, false, true, address(seqInbox));
        emit EspressoCertificateVerified(hotshotBlock, delayedRead, newMsg);

        vm.prank(tx.origin);
        seqInbox.addSequencerL2BatchFromOrigin(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testFromOriginCertStrippedFromBatchData() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup();
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"00aabbccdd";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, 0, 1, downstream);

        vm.expectEmit(true, false, false, true, address(seqInbox));
        emit SequencerBatchData(seqNum, downstream);

        vm.prank(tx.origin);
        seqInbox.addSequencerL2BatchFromOrigin(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testSetEspressoTEEVerifier_OnlyOwner() public {
        (SequencerInbox seqInbox,) = _deployEspressoRollup();

        address newVerifier = address(0xBEEF);

        // Owner can set
        vm.prank(rollupOwner);
        seqInbox.setEspressoTEEVerifier(newVerifier);
        assertEq(address(seqInbox.espressoTEEVerifier()), newVerifier);

        // Non-owner reverts
        address nonOwner = address(0xBAD);
        vm.expectRevert(abi.encodeWithSelector(NotOwner.selector, nonOwner, rollupOwner));
        vm.prank(nonOwner);
        seqInbox.setEspressoTEEVerifier(address(0));
    }
}

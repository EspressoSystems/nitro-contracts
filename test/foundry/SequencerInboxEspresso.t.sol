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
    // ── Events (needed for expectEmit before 0.8.21) ──────────────────
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
    event StartHotshotBlockSet(uint32 startHotshotBlock);
    event EspressoCertificateVerified(uint32 startHotshotBlock);
    event EspressoTEEVerifierSet(address espressoTEEVerifier);

    // ── Constants ─────────────────────────────────────────────────────
    uint256 constant SIGNER_PK = 0xA11CE;
    uint256 constant OTHER_PK = 0xBEEF;
    uint256 constant MAX_DATA_SIZE = 117964;

    bytes32 constant ESPRESSO_TEE_VERIFIER_TYPE_HASH =
        keccak256("EspressoTEEVerifier(bytes32 commitment)");

    // ── State ─────────────────────────────────────────────────────────
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
    BufferConfig bufferConfigDefault = BufferConfig({
        threshold: type(uint64).max,
        max: type(uint64).max,
        replenishRateInBasis: 714
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
    ///      Layout: [0..31] CAS header | [32..35] startMessagePos |
    ///              [36..39] endMessagePos | [40..43] startHotshotBlock |
    ///              [44..47] afterDelayedMessagesRead | [48..51] minHotshotBlock |
    ///              [52..116] signature | [117+] downstreamCert
    function _buildCertData(
        uint32 startMessagePos,
        uint32 endMessagePos,
        uint32 startHotshotBlock_,
        uint32 afterDelayedMessagesRead,
        uint32 minHotshotBlock,
        bytes memory signature,
        bytes memory downstreamCert
    ) internal pure returns (bytes memory) {
        // CAS header: 32 bytes, first byte = 0x70
        bytes memory casHeader = new bytes(32);
        casHeader[0] = 0x70;

        return abi.encodePacked(
            casHeader,
            bytes4(startMessagePos),
            bytes4(endMessagePos),
            bytes4(startHotshotBlock_),
            bytes4(afterDelayedMessagesRead),
            bytes4(minHotshotBlock),
            signature,
            downstreamCert
        );
    }

    /// @dev Compute the canonical payload hash that the signer must commit to.
    function _computeUserDataHash(
        uint256 prevMsgCount,
        uint256 newMsgCount,
        uint32 _startHotshotBlock,
        uint256 afterDelayedMessagesRead,
        uint32 minHotshotBlock,
        bytes memory downstreamCert
    ) internal pure returns (bytes32) {
        bytes memory payload = abi.encodePacked(
            uint32(prevMsgCount),
            uint32(newMsgCount),
            _startHotshotBlock,
            uint32(afterDelayedMessagesRead),
            minHotshotBlock,
            downstreamCert
        );
        return keccak256(payload);
    }

    /// @dev Deploy Bridge + SequencerInbox with espresso TEE verifier enabled.
    function _deployEspressoRollup(
        uint32 startBlock
    ) internal returns (SequencerInbox seqInbox, Bridge bridge) {
        EspressoRollupMock rollupMock = new EspressoRollupMock(rollupOwner);

        Bridge bridgeImpl = new Bridge();
        bridge =
            Bridge(address(new TransparentUpgradeableProxy(address(bridgeImpl), proxyAdmin, "")));
        bridge.initialize(IOwnable(address(rollupMock)));
        vm.prank(rollupOwner);
        bridge.setDelayedInbox(dummyInbox, true);

        SequencerInbox seqInboxImpl =
            new SequencerInbox(MAX_DATA_SIZE, dummyReader4844, false, false);
        seqInbox = SequencerInbox(
            address(new TransparentUpgradeableProxy(address(seqInboxImpl), proxyAdmin, ""))
        );

        seqInbox.initialize(
            bridge,
            maxTimeVariation,
            bufferConfigDefault,
            IFeeTokenPricer(address(0)),
            IEspressoTEEVerifier(address(teeVerifierMock)),
            startBlock
        );

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
        uint32 minHotshotBlock,
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
            seqInbox.startHotshotBlock(),
            delayedMessagesRead,
            minHotshotBlock,
            downstreamCert
        );

        bytes memory sig = _signPayload(SIGNER_PK, userDataHash);
        data = _buildCertData(
            uint32(prevMsgCount),
            uint32(newMsgCount),
            seqInbox.startHotshotBlock(),
            uint32(delayedMessagesRead),
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
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup(1);
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"deadbeef";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, 1, downstream);

        uint256 countBefore = bridge.sequencerMessageCount();

        vm.prank(tx.origin);
        seqInbox.addSequencerL2Batch(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );

        assertEq(bridge.sequencerMessageCount(), countBefore + 1, "batch not accepted");
    }

    function testAddBatchFromOriginWithValidEspressoCert() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup(0);
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"deadbeef";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, 1, downstream);

        uint256 countBefore = bridge.sequencerMessageCount();

        vm.prank(tx.origin);
        seqInbox.addSequencerL2BatchFromOrigin(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );

        assertEq(bridge.sequencerMessageCount(), countBefore + 1, "batch not accepted");
    }

    function testRevertUnregisteredSigner() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup(0);
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        // Use OTHER_PK whose address is NOT registered in the NitroMock
        uint256 prevMsg = bridge.sequencerReportedSubMessageCount();
        uint256 newMsg = prevMsg + 1;
        uint256 delayedRead = bridge.delayedMessageCount();
        uint256 seqNum = bridge.sequencerMessageCount();
        bytes memory downstream = hex"deadbeef";

        bytes32 userDataHash = _computeUserDataHash(
            prevMsg, newMsg, seqInbox.startHotshotBlock(), delayedRead, 1, downstream
        );

        // Sign with unregistered key
        bytes memory sig = _signPayload(OTHER_PK, userDataHash);
        bytes memory data = _buildCertData(
            uint32(prevMsg),
            uint32(newMsg),
            seqInbox.startHotshotBlock(),
            uint32(delayedRead),
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
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup(0);
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        uint256 prevMsg = bridge.sequencerReportedSubMessageCount();
        uint256 newMsg = prevMsg + 1;
        uint256 delayedRead = bridge.delayedMessageCount();
        uint256 seqNum = bridge.sequencerMessageCount();

        // Build data shorter than 117 bytes but with valid CAS header flag
        bytes memory shortData = new bytes(116);
        shortData[0] = 0x70;

        vm.expectRevert(InvalidCasCertificate.selector);
        vm.prank(tx.origin);
        seqInbox.addSequencerL2Batch(
            seqNum, shortData, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testStartHotshotBlockUpdated() public {
        uint32 initialBlock = 5;
        uint32 newMinBlock = 10;

        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup(initialBlock);
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"cafe";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, newMinBlock, downstream);

        vm.expectEmit(false, false, false, true, address(seqInbox));
        emit StartHotshotBlockSet(newMinBlock);

        vm.prank(tx.origin);
        seqInbox.addSequencerL2Batch(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );

        assertEq(seqInbox.startHotshotBlock(), newMinBlock, "startHotshotBlock not updated");
    }

    function testCertStrippedFromBatchDataEvent() public {
        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup(0);
        _enqueueDelayed(bridge);
        vm.fee(60 gwei);

        bytes memory downstream = hex"aabbccdd";
        (bytes memory data, uint256 seqNum, uint256 delayedRead, uint256 prevMsg, uint256 newMsg) =
            _prepareValidBatch(seqInbox, bridge, 1, downstream);

        // Expect SequencerBatchData to contain only the downstream cert (data[117:])
        vm.expectEmit(true, false, false, true, address(seqInbox));
        emit SequencerBatchData(seqNum, downstream);

        vm.prank(tx.origin);
        seqInbox.addSequencerL2Batch(
            seqNum, data, delayedRead, IGasRefunder(address(0)), prevMsg, newMsg
        );
    }

    function testSetEspressoTEEVerifier_OnlyOwner() public {
        (SequencerInbox seqInbox,) = _deployEspressoRollup(0);

        address newVerifier = address(0xBEEF);

        // Owner can set
        vm.prank(rollupOwner);
        seqInbox.setEspressoTEEVerifier(IEspressoTEEVerifier(newVerifier));
        assertEq(address(seqInbox.espressoTEEVerifier()), newVerifier);

        // Non-owner reverts
        address nonOwner = address(0xBAD);
        vm.expectRevert(abi.encodeWithSelector(NotOwner.selector, nonOwner, rollupOwner));
        vm.prank(nonOwner);
        seqInbox.setEspressoTEEVerifier(IEspressoTEEVerifier(address(0)));
    }

    function testSecondBatchUsesUpdatedStartHotshotBlock() public {
        uint32 initialBlock = 5;
        uint32 firstMinBlock = 10;
        uint32 secondMinBlock = 15;

        (SequencerInbox seqInbox, Bridge bridge) = _deployEspressoRollup(initialBlock);
        _enqueueDelayed(bridge);
        _enqueueDelayed(bridge); // enqueue a second delayed msg for the second batch
        vm.fee(60 gwei);

        // ── First batch: updates startHotshotBlock from 5 → 10 ──
        {
            bytes memory downstream1 = hex"cafe";
            (
                bytes memory data1,
                uint256 seqNum1,
                uint256 delayedRead1,
                uint256 prevMsg1,
                uint256 newMsg1
            ) = _prepareValidBatch(seqInbox, bridge, firstMinBlock, downstream1);

            assertEq(seqInbox.startHotshotBlock(), initialBlock, "initial block mismatch");

            vm.prank(tx.origin);
            seqInbox.addSequencerL2Batch(
                seqNum1, data1, delayedRead1, IGasRefunder(address(0)), prevMsg1, newMsg1
            );
        }

        assertEq(seqInbox.startHotshotBlock(), firstMinBlock, "block not updated after first batch");

        // ── Second batch: must be signed with startHotshotBlock=10 (the updated value) ──
        {
            bytes memory downstream2 = hex"beef";
            (
                bytes memory data2,
                uint256 seqNum2,
                uint256 delayedRead2,
                uint256 prevMsg2,
                uint256 newMsg2
            ) = _prepareValidBatch(seqInbox, bridge, secondMinBlock, downstream2);

            vm.expectEmit(false, false, false, true, address(seqInbox));
            emit StartHotshotBlockSet(secondMinBlock);

            vm.prank(tx.origin);
            seqInbox.addSequencerL2Batch(
                seqNum2, data2, delayedRead2, IGasRefunder(address(0)), prevMsg2, newMsg2
            );
        }

        assertEq(
            seqInbox.startHotshotBlock(), secondMinBlock, "block not updated after second batch"
        );
    }
}

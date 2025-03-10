// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EspressoTEEVerifier} from "../../src/bridge/EspressoTEEVerifier.sol";
import {IEspressoTEEVerifier} from "../../src/bridge/IEspressoTEEVerifier.sol";
import {EspressoSGXTEEVerifier} from "../../src/bridge/EspressoSGXTEEVerifier.sol";
import {IEspressoSGXTEEVerifier} from "../../src/bridge/IEspressoSGXTEEVerifier.sol";

// TODO: Add tests for registerSigner with a valid address in data field
// TODO: Add tests for register signer where the report data length is less than 20 bytes
// TODO: Add tests for deleteRegisteredSigner

contract EspressoTEEVerifierTest is Test {
    address adminTEE = address(141);
    address fakeAddress = address(145);

    EspressoTEEVerifier espressoTEEVerifier;
    EspressoSGXTEEVerifier espressoSGXTEEVerifier;
    bytes32 enclaveHash =
        bytes32(0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff0);
    //  Address of the automata V3QuoteVerifier deployed on sepolia
    address v3QuoteVerifier = address(0x6E64769A13617f528a2135692484B681Ee1a7169);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia");
        // Get the instance of the DCAP Attestation QuoteVerifier on the Arbitrum Sepolia Rollup
        vm.startPrank(adminTEE);

        espressoSGXTEEVerifier = new EspressoSGXTEEVerifier(enclaveHash, v3QuoteVerifier);
        espressoTEEVerifier = new EspressoTEEVerifier(espressoSGXTEEVerifier);
        vm.stopPrank();
    }

    function testSetEspressoSGXTEEVerifier() public {
        vm.startPrank(adminTEE);
        IEspressoSGXTEEVerifier newEspressoSGXTEEVerifier = new EspressoSGXTEEVerifier(
            enclaveHash,
            v3QuoteVerifier
        );
        espressoTEEVerifier.setEspressoSGXTEEVerifier(newEspressoSGXTEEVerifier);
        assertEq(
            address(espressoTEEVerifier.espressoSGXTEEVerifier()),
            address(newEspressoSGXTEEVerifier)
        );

        vm.stopPrank();
    }

    function testVerifyFailsIfNotRegisteredSigner() public {
        vm.startPrank(adminTEE);
        bytes32 newEnclaveHash = bytes32(hex"01");
        // Create signature using admine address which is not registered signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminTEE, newEnclaveHash);
        // convert r, s, v to signature
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(IEspressoTEEVerifier.InvalidSignature.selector);
        espressoTEEVerifier.verify(signature, newEnclaveHash);
    }

    function testSetEnclaveHash() public {
        vm.startPrank(adminTEE);
        bytes32 newEnclaveHash = bytes32(hex"01");
        espressoTEEVerifier.setEnclaveHash(newEnclaveHash, true, IEspressoTEEVerifier.TeeType.SGX);
        assertEq(
            espressoTEEVerifier.registeredEnclaveHash(
                newEnclaveHash,
                IEspressoTEEVerifier.TeeType.SGX
            ),
            true
        );

        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidEnclaveHash.selector);
        espressoTEEVerifier.setEnclaveHash(newEnclaveHash, false, IEspressoTEEVerifier.TeeType.SGX);
        assertEq(
            espressoTEEVerifier.registeredEnclaveHash(
                newEnclaveHash,
                IEspressoTEEVerifier.TeeType.SGX
            ),
            false
        );
        vm.stopPrank();
    }

    // Test Ownership transfer using Ownable2Step contract
    function testOwnershipTransfer() public {
        vm.startPrank(adminTEE);
        assertEq(address(espressoTEEVerifier.owner()), adminTEE);
        espressoTEEVerifier.transferOwnership(fakeAddress);
        vm.stopPrank();
        vm.startPrank(fakeAddress);
        espressoTEEVerifier.acceptOwnership();
        assertEq(address(espressoTEEVerifier.owner()), fakeAddress);
        vm.stopPrank();
    }
}

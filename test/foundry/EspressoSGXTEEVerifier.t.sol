// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {
    EspressoSGXTEEVerifier,
    IEspressoSGXTEEVerifier
} from "../../src/bridge/EspressoSGXTEEVerifier.sol";

// TODO: Add tests for registerSigner with a valid address
// TODO: Add test for registerSigner with an invalid address
// TODO: Add tests for register signer where the report data length is less than 20 bytes
// TODO: Add tests for deleteRegisteredSigner

contract EspressoSGXTEEVerifierTest is Test {
    address proxyAdmin = address(140);
    address adminTEE = address(141);
    address fakeAddress = address(145);

    EspressoSGXTEEVerifier espressoSGXTEEVerifier;
    bytes32 reportDataHash =
        bytes32(0x739f5f48d929cc121c080ec6527a22be3c69bad5c40606cd098a9fa7ed971f1b);
    bytes32 enclaveHash =
        bytes32(0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff0);
    //  Address of the automata V3QuoteVerifier deployed on sepolia
    address v3QuoteVerifier = address(0x6E64769A13617f528a2135692484B681Ee1a7169);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia");
        // Get the instance of the DCAP Attestation QuoteVerifier on the Arbitrum Sepolia Rollup
        vm.startPrank(adminTEE);
        espressoSGXTEEVerifier = new EspressoSGXTEEVerifier(enclaveHash, v3QuoteVerifier);
        vm.stopPrank();
    }

    /**
        Test verify quote verifies that if correct quote and report data hash is passed
        then the function does not revert
    */
    function testVerifyQuoteValid() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        espressoSGXTEEVerifier.verify(sampleQuote, reportDataHash);
        vm.stopPrank();
    }

    /**
        Test verify quote reverts if incorrect header is passed
    */
    function testVerifyInvalidHeaderInQuote() public {
        string memory quotePath = "/test/foundry/configs/incorrect_header_in_quote.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory invalidQuote = vm.readFileBinary(inputFile);
        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidHeaderVersion.selector);
        espressoSGXTEEVerifier.verify(invalidQuote, reportDataHash);
    }

    /**
        Test verify quote reverts if incorrect quote is passed
    */
    function testVerifyInvalidQuote() public {
        string memory quotePath = "/test/foundry/configs/invalid_quote.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory invalidQuote = vm.readFileBinary(inputFile);
        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidQuote.selector);
        espressoSGXTEEVerifier.verify(invalidQuote, reportDataHash);
    }

    /**
        Test incorrect report data hash
    */
    function testIncorrectReportDataHash() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidReportDataHash.selector);
        espressoSGXTEEVerifier.verify(sampleQuote, bytes32(0));
    }

    /**
        Test verify quote reverts if incorrect enclaveHash is passed
    */
    function testIncorrectMrEnclave() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        bytes32 incorrectMrEnclave = bytes32(
            0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff1
        );
        espressoSGXTEEVerifier = new EspressoSGXTEEVerifier(incorrectMrEnclave, v3QuoteVerifier);
        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidEnclaveHash.selector);
        espressoSGXTEEVerifier.verify(sampleQuote, reportDataHash);
    }

    function testSetEnclaveHash() public {
        vm.startPrank(adminTEE);
        bytes32 newMrEnclave = bytes32(hex"01");
        espressoSGXTEEVerifier.setEnclaveHash(newMrEnclave, true);
        assertEq(espressoSGXTEEVerifier.registeredEnclaveHash(newMrEnclave), true);
        vm.stopPrank();
    }

    // Test Ownership transfer using Ownable2Step contract
    function testOwnershipTransfer() public {
        vm.startPrank(adminTEE);
        assertEq(address(espressoSGXTEEVerifier.owner()), adminTEE);
        espressoSGXTEEVerifier.transferOwnership(fakeAddress);
        vm.stopPrank();
        vm.startPrank(fakeAddress);
        espressoSGXTEEVerifier.acceptOwnership();
        assertEq(address(espressoSGXTEEVerifier.owner()), fakeAddress);
        vm.stopPrank();
    }
}

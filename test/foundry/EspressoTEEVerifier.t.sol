// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EspressoTEEVerifier} from "../../src/bridge/EspressoTEEVerifier.sol";

contract EspressoTEEVerifierTest is Test {
    address proxyAdmin = address(140);
    address adminTEE = address(141);
    address fakeAddress = address(145);

    EspressoTEEVerifier espressoTEEVerifier;
    bytes32 reportDataHash =
        bytes32(0x739f5f48d929cc121c080ec6527a22be3c69bad5c40606cd098a9fa7ed971f1b);
    bytes32 mrEnclave = bytes32(0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff0);
    bytes32 mrSigner = bytes32(0x0c8242bba090f54b10de0c2d1ca4b633b9c08b7178451c71d737c214b72fc836);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia");
        // Get the instance of the DCAP Attestation QuoteVerifier on the Arbitrum Sepolia Rollup
        vm.startPrank(adminTEE);
        espressoTEEVerifier = new EspressoTEEVerifier(
            mrEnclave,
            mrSigner,
            // Address of the deployed V3Verifier contract
            address(0x6E64769A13617f528a2135692484B681Ee1a7169)
        );
        vm.stopPrank();
    }

    /*
      Test that the verify function returns sucess for a valid quote
    */
    function testVerifyQuoteValid() public {
        vm.startPrank(adminTEE);

        string memory quotePath = "/test/foundry/configs/valid_quote.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        bool success = espressoTEEVerifier.verify(sampleQuote, reportDataHash);
        assertEq(success, true);
        vm.stopPrank();
    }

    /*
      Test that the verify function returns false for an invalid quote
    */
    function testVerifyQuoteInValid() public {
        string memory quotePath = "/test/foundry/configs/incorrect_attestation_quote.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory invalidQuote = vm.readFileBinary(inputFile);
        bool success = espressoTEEVerifier.verify(invalidQuote, reportDataHash);
        assertEq(success, false);
    }

    /**
        Test incorrect report data hash
    */

    function testIncorrectReportDataHash() public {
        vm.startPrank(adminTEE);

        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        bool success = espressoTEEVerifier.verify(sampleQuote, bytes32(0));
        assertEq(success, false);
    }

    /**
        Test incorrect mrEnclave
    */
    function testIncorrectMrEnclave() public {
        vm.startPrank(adminTEE);

        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        espressoTEEVerifier = new EspressoTEEVerifier(
            bytes32(0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff1),
            mrSigner,
            address(0x6E64769A13617f528a2135692484B681Ee1a7169)
        );
        bool success = espressoTEEVerifier.verify(sampleQuote, reportDataHash);
        assertEq(success, false);
    }

    /**
        Test incorrect mrSigner
    */
    function testIncorrectMrSigner() public {
        vm.startPrank(adminTEE);

        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        espressoTEEVerifier = new EspressoTEEVerifier(
            mrEnclave,
            bytes32(0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff5),
            address(0x6E64769A13617f528a2135692484B681Ee1a7169)
        );
        bool success = espressoTEEVerifier.verify(sampleQuote, reportDataHash);
        assertEq(success, false);
    }

    /**
        Test set owner
    */
    function testSetOwner() public {
        vm.startPrank(adminTEE);

        address newOwner = address(142);
        espressoTEEVerifier.setOwner(newOwner);
        assertEq(espressoTEEVerifier.owner(), newOwner);
        vm.stopPrank();
    }

    /**
        Test set mrEnclave
    */
    function testSetMrEnclave() public {
        vm.startPrank(adminTEE);

        bytes32 newMrEnclave = bytes32(
            0x1234567890123456789012345678901234567890123456789012345678901234
        );
        espressoTEEVerifier.setMrEnclave(newMrEnclave);
        assertEq(espressoTEEVerifier.mrEnclave(), newMrEnclave);
        vm.stopPrank();
    }

    /**
        Test set mrSigner
    */
    function testSetMrSigner() public {
        vm.startPrank(adminTEE);

        bytes32 newMrSigner = bytes32(
            0x1234567890123456789012345678901234567890123456789012345678901234
        );
        espressoTEEVerifier.setMrSigner(newMrSigner);
        assertEq(espressoTEEVerifier.mrSigner(), newMrSigner);
        vm.stopPrank();
    }
}

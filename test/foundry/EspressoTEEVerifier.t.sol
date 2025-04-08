// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EspressoTEEVerifier, IEspressoTEEVerifier} from "../../src/bridge/EspressoTEEVerifier.sol";

contract EspressoTEEVerifierTest is Test {
    address proxyAdmin = address(140);
    address adminTEE = address(141);
    address fakeAddress = address(145);

    EspressoTEEVerifier espressoTEEVerifier;
    bytes32 reportDataHash =
        bytes32(0x739f5f48d929cc121c080ec6527a22be3c69bad5c40606cd098a9fa7ed971f1b);
    bytes32 mrEnclave = bytes32(0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff0);
    bytes32 mrSigner = bytes32(0x0c8242bba090f54b10de0c2d1ca4b633b9c08b7178451c71d737c214b72fc836);
    //  Address of the automata V3QuoteVerifier deployed on sepolia
    address v3QuoteVerifier = address(0x6E64769A13617f528a2135692484B681Ee1a7169);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia");
        // Get the instance of the DCAP Attestation QuoteVerifier on the Arbitrum Sepolia Rollup
        vm.startPrank(adminTEE);
        espressoTEEVerifier = new EspressoTEEVerifier(mrEnclave, mrSigner, v3QuoteVerifier);
        vm.stopPrank();
    }

    function testVerifyQuoteValid() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        espressoTEEVerifier.verify(sampleQuote, reportDataHash);
        vm.stopPrank();
    }

    function testVerifyInvalidHeaderInQuote() public {
        string memory quotePath = "/test/foundry/configs/incorrect_header_in_quote.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory invalidQuote = vm.readFileBinary(inputFile);
        vm.expectRevert(IEspressoTEEVerifier.InvalidHeaderVersion.selector);
        espressoTEEVerifier.verify(invalidQuote, reportDataHash);
    }

    function testVerifyInvalidQuote() public {
        string memory quotePath = "/test/foundry/configs/invalid_quote.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory invalidQuote = vm.readFileBinary(inputFile);
        vm.expectRevert(IEspressoTEEVerifier.InvalidQuote.selector);
        espressoTEEVerifier.verify(invalidQuote, reportDataHash);
    }

    /**
        Test incorrect report data hash
    */
    function testIncorrectReportDataHash() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        vm.expectRevert(IEspressoTEEVerifier.InvalidReportDataHash.selector);
        espressoTEEVerifier.verify(sampleQuote, bytes32(0));
    }

    function testIncorrectMrEnclave() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        bytes32 incorrectMrEnclave = bytes32(
            0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff1
        );
        espressoTEEVerifier = new EspressoTEEVerifier(
            incorrectMrEnclave,
            mrSigner,
            v3QuoteVerifier
        );
        vm.expectRevert(IEspressoTEEVerifier.InvalidMREnclaveOrSigner.selector);
        espressoTEEVerifier.verify(sampleQuote, reportDataHash);
    }

    function testIncorrectMrSigner() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        bytes32 incorrectMrSigner = bytes32(
            0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff5
        );
        espressoTEEVerifier = new EspressoTEEVerifier(
            mrEnclave,
            incorrectMrSigner,
            v3QuoteVerifier
        );
        vm.expectRevert(IEspressoTEEVerifier.InvalidMREnclaveOrSigner.selector);
        espressoTEEVerifier.verify(sampleQuote, reportDataHash);
    }

    function testSetMrEnclave() public {
        vm.startPrank(adminTEE);
        bytes32 newMrEnclave = bytes32(hex"01");
        espressoTEEVerifier.setMrEnclave(newMrEnclave);
        assertEq(espressoTEEVerifier.mrEnclave(), newMrEnclave);
        vm.stopPrank();
    }

    function testSetMrSigner() public {
        vm.startPrank(adminTEE);
        bytes32 newMrSigner = bytes32(hex"01");
        espressoTEEVerifier.setMrSigner(newMrSigner);
        assertEq(espressoTEEVerifier.mrSigner(), newMrSigner);
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

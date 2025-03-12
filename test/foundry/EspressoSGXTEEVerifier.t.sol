// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {
    EspressoSGXTEEVerifier,
    IEspressoSGXTEEVerifier
} from "../../src/bridge/EspressoSGXTEEVerifier.sol";

contract EspressoSGXTEEVerifierTest is Test {
    address proxyAdmin = address(140);
    address adminTEE = address(141);
    address fakeAddress = address(145);

    EspressoSGXTEEVerifier espressoSGXTEEVerifier;
    bytes32 reportDataHash =
        bytes32(0x38f8abca50cdede6a00d405856857bc3d81135624ee0e287640956d11cc22d5e);
    bytes32 enclaveHash =
        bytes32(0x01f7290cb6bbaa427eca3daeb25eecccb87c4b61259b1ae2125182c4d77169c0);
    bytes32 enclaveSigner =
        bytes32(0x5fc862cb2e7e1f449f36a18b18aca08c20feaed0d411247816c281d596420cbb);
    //  Address of the automata V3QuoteVerifier deployed on sepolia
    address v3QuoteVerifier = address(0x6E64769A13617f528a2135692484B681Ee1a7169);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia");
        // Get the instance of the DCAP Attestation QuoteVerifier on the Arbitrum Sepolia Rollup
        vm.startPrank(adminTEE);
        espressoSGXTEEVerifier = new EspressoSGXTEEVerifier(
            enclaveHash,
            enclaveSigner,
            v3QuoteVerifier
        );
        vm.stopPrank();
    }

    function testRegisterSigner() public {
        vm.startPrank(adminTEE);
        // bytes memory attestation = vm.readFileBinary("/test/foundry/configs/attestation.bin");
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);

        // take keccak256 hash of the address of proxyAdmin

        address batchPosterAddress = address(0xe2148eE53c0755215Df69b2616E552154EdC584f);

        bytes memory data = abi.encodePacked(batchPosterAddress);

        // Convert the data to bytes32 and pass it to the verify function
        espressoSGXTEEVerifier.registerSigner(sampleQuote, data);
        vm.stopPrank();
    }

    function testRegisterSignerInvalidQuote() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/invalid_quote.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);

        address batchPosterAddress = address(0xe2148eE53c0755215Df69b2616E552154EdC584f);

        bytes memory data = abi.encodePacked(batchPosterAddress);

        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidQuote.selector);
        espressoSGXTEEVerifier.registerSigner(sampleQuote, data);
    }

    function testRegisterSignerInvalidAddress() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);

        address batchPosterAddress = address(0x4C91660a37d613E1Bd278F9Db882Cc5ED2549072);

        bytes memory data = abi.encodePacked(batchPosterAddress);

        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidReportDataHash.selector);
        espressoSGXTEEVerifier.registerSigner(sampleQuote, data);
    }

    function testRegisterSignerInvalidDataLength() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);

        address batchPosterAddress = address(0xe2148eE53c0755215Df69b2616E552154EdC584f);

        // encode adds padding and the length should become incorrect
        bytes memory data = abi.encode(batchPosterAddress);

        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidDataLength.selector);
        espressoSGXTEEVerifier.registerSigner(sampleQuote, data);
    }

    function testDeleteRegisteredSigner() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);

        address batchPosterAddress = address(0xe2148eE53c0755215Df69b2616E552154EdC584f);

        // Convert to bytes (dynamically sized)
        bytes memory data = abi.encodePacked(batchPosterAddress);

        espressoSGXTEEVerifier.registerSigner(sampleQuote, data);
        vm.stopPrank();

        vm.startPrank(adminTEE);
        espressoSGXTEEVerifier.deleteRegisteredSigner(batchPosterAddress);
        assertEq(espressoSGXTEEVerifier.registeredSigners(batchPosterAddress), false);
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
        espressoSGXTEEVerifier = new EspressoSGXTEEVerifier(
            incorrectMrEnclave,
            enclaveSigner,
            v3QuoteVerifier
        );
        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidEnclaveHash.selector);
        espressoSGXTEEVerifier.verify(sampleQuote, reportDataHash);
    }

    function testIncorrectEnclaveSigner() public {
        vm.startPrank(adminTEE);
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        bytes32 incorrectMrSigner = bytes32(
            0x51dfe95acffa8a4075b716257c836895af9202a5fd56c8c2208dacb79c659ff1
        );
        espressoSGXTEEVerifier = new EspressoSGXTEEVerifier(
            enclaveHash,
            incorrectMrSigner,
            v3QuoteVerifier
        );
        vm.expectRevert(IEspressoSGXTEEVerifier.InvalidEnclaveSigner.selector);
        espressoSGXTEEVerifier.verify(sampleQuote, reportDataHash);
    }

    function testSetEnclaveHash() public {
        vm.startPrank(adminTEE);
        bytes32 newMrEnclave = bytes32(hex"01");
        espressoSGXTEEVerifier.setEnclaveHash(newMrEnclave, true);
        assertEq(espressoSGXTEEVerifier.registeredEnclaveHash(newMrEnclave), true);
        espressoSGXTEEVerifier.setEnclaveHash(newMrEnclave, false);
        assertEq(espressoSGXTEEVerifier.registeredEnclaveHash(newMrEnclave), false);
        vm.stopPrank();
    }

    function testSetEnclaveSigner() public {
        vm.startPrank(adminTEE);
        bytes32 newMrSigner = bytes32(hex"01");
        espressoSGXTEEVerifier.setEnclaveSigner(newMrSigner, true);
        assertEq(espressoSGXTEEVerifier.registeredEnclaveSigner(newMrSigner), true);
        espressoSGXTEEVerifier.setEnclaveSigner(newMrSigner, false);
        assertEq(espressoSGXTEEVerifier.registeredEnclaveSigner(newMrSigner), false);
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

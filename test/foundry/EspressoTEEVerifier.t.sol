// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EspressoTEEVerifier} from "../../src/bridge/EspressoTEEVerifier.sol";
import {IEspressoTEEVerifier} from "../../src/bridge/IEspressoTEEVerifier.sol";
import {EspressoSGXTEEVerifier} from "../../src/bridge/EspressoSGXTEEVerifier.sol";
import {IEspressoSGXTEEVerifier} from "../../src/bridge/IEspressoSGXTEEVerifier.sol";

contract EspressoTEEVerifierTest is Test {
    address adminTEE = address(141);
    address fakeAddress = address(145);

    EspressoTEEVerifier espressoTEEVerifier;
    EspressoSGXTEEVerifier espressoSGXTEEVerifier;
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
        espressoTEEVerifier = new EspressoTEEVerifier(espressoSGXTEEVerifier);
        vm.stopPrank();
    }

    function testRegisterSigner() public {
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        address batchPosterAddress = address(0xe2148eE53c0755215Df69b2616E552154EdC584f);
        bytes memory data = abi.encodePacked(batchPosterAddress);
        espressoTEEVerifier.registerSigner(sampleQuote, data, IEspressoTEEVerifier.TeeType.SGX);
    }

    function testRegisteredSigners() public {
        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        address batchPosterAddress = address(0xe2148eE53c0755215Df69b2616E552154EdC584f);
        bytes memory data = abi.encodePacked(batchPosterAddress);
        espressoTEEVerifier.registerSigner(sampleQuote, data, IEspressoTEEVerifier.TeeType.SGX);

        assertEq(
            espressoTEEVerifier.registeredSigners(
                batchPosterAddress,
                IEspressoTEEVerifier.TeeType.SGX
            ),
            true
        );
    }

    function testRegisteredEnclaveHash() public {
        assertEq(
            espressoTEEVerifier.registeredEnclaveHashes(
                bytes32(0x01f7290cb6bbaa427eca3daeb25eecccb87c4b61259b1ae2125182c4d77169c0),
                IEspressoTEEVerifier.TeeType.SGX
            ),
            true
        );
    }

    function testRegisteredEnclaveSigner() public {
        assertEq(
            espressoTEEVerifier.registeredEnclaveSigners(
                bytes32(0x5fc862cb2e7e1f449f36a18b18aca08c20feaed0d411247816c281d596420cbb),
                IEspressoTEEVerifier.TeeType.SGX
            ),
            true
        );
    }

    function testSetEspressoSGXTEEVerifier() public {
        vm.startPrank(adminTEE);
        IEspressoSGXTEEVerifier newEspressoSGXTEEVerifier = new EspressoSGXTEEVerifier(
            enclaveHash,
            enclaveSigner,
            v3QuoteVerifier
        );
        espressoTEEVerifier.setEspressoSGXTEEVerifier(newEspressoSGXTEEVerifier);
        assertEq(
            address(espressoTEEVerifier.espressoSGXTEEVerifier()),
            address(newEspressoSGXTEEVerifier)
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

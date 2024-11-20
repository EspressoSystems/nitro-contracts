// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EspressoTEEVerifier} from "../../src/bridge/EspressoTEEVerifier.sol";
import {
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {
    AutomataDcapAttestation
} from "@automata-network/dcap-attestation/contracts/AutomataDcapAttestation.sol";
import {PCCSRouter} from "@automata-network/dcap-attestation/contracts/PCCSRouter.sol";

import {PCCSSetupBase} from "@automata-network/dcap-attestation/test/utils/PCCSSetupBase.sol";
import {RiscZeroSetup} from "@automata-network/dcap-attestation/test/utils/RiscZeroSetup.sol";

contract EspressoTEEVerifierTest is Test, PCCSSetupBase, RiscZeroSetup {
    address proxyAdmin = address(140);
    address adminTEE = address(141);
    address fakeAddress = address(145);

    EspressoTEEVerifier espressoTEEVerifier;
    PCCSRouter pccsRouter;
    bytes32 imageId = vm.envBytes32("DCAP_IMAGE_ID");

    function setUp() public override {
        super.setUp();

        // PCCS Setup
        pccsRouter = setupPccsRouter();
        pcsDaoUpserts();
        espressoTEEVerifier = new EspressoTEEVerifier(address(pccsRouter));

        string memory tcbInfoPath = "/test/foundry/configs/tcbinfo.json";
        string memory qeIdPath = "/test/foundry/configs/tee_identity.json";
        qeIdDaoUpsert(3, qeIdPath);
        fmspcTcbDaoUpsert(tcbInfoPath);
    }

    /*
      Test that the verify function returns sucess for a valid quote
    */
    function testVerifyQuoteValid() public {
        vm.startPrank(adminTEE);

        string memory quotePath = "/test/foundry/configs/attestation.bin";
        string memory inputFile = string.concat(vm.projectRoot(), quotePath);
        bytes memory sampleQuote = vm.readFileBinary(inputFile);
        bool success = espressoTEEVerifier.verify(sampleQuote);
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
        bool success = espressoTEEVerifier.verify(invalidQuote);
        assertEq(success, false);
    }
}

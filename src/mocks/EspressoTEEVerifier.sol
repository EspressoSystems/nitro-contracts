// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    AutomataDcapAttestation
} from "@automata-network/dcap-attestation/AutomataDcapAttestation.sol";
import "../libraries/DelegateCallAware.sol";
import {GasRefundEnabled} from "../libraries/GasRefundEnabled.sol";

/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the AutomataDcapAttestation contract
 *         to verify the quote and attest on-chain. Along with some additional verification logic.
 */

contract EspressoTEEVerifierTest {
    // TEE attestation contract
    AutomataDcapAttestation attest;

    constructor(address _attest) {
        attest = AutomataDcapAttestation(_attest);
    }

    /**
        @notice Verify a quote from the TEE and attest on-chain
        @param quote The quote from the TEE
        @return success True if the quote was verified and attested on-chain
        @return output output contains an error message if verification failed
     */
    function verify(bytes memory quote) external view returns (bool success, bytes memory output) {
        // TODO: add more verification logic
        return (true, "");
    }
}

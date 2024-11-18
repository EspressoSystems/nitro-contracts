// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the AutomataDcapAttestation contract
 *         to verify the quote and attest on-chain. Along with some additional verification logic.
 */

contract EspressoTEEVerifierTest is Initializable, OwnableUpgradeable {
    // TEE attestation contract

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _attestationContract) public initializer {
        __Ownable_init();
    }

    /**
        @notice Verify a quote from the TEE and attest on-chain
        @param quote The quote from the TEE
        @return success True if the quote was verified and attested on-chain
        @return output output contains an error message if verification failed
     */
    function verify(bytes memory quote) external view returns (bool success, bytes memory output) {
        return (true, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ServiceType, IEspressoTEEVerifier} from "../bridge/EspressoTEE.sol";

/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the V3QuoteVerifier contract
 *         to verify the quote. Along with some additional verification logic.
 */
contract EspressoTEEVerifierMock is IEspressoTEEVerifier {

    function verify(
        bytes memory,
        bytes32,
        TeeType,
        ServiceType
    ) external pure returns (bool) {
        return true;
    }

    function registerService(bytes calldata, bytes calldata, TeeType, ServiceType) external {}

    function registeredEnclaveHashes(bytes32, TeeType, ServiceType) external pure returns (bool) {
        return false;
    }

    function isSignerValid(address, TeeType, ServiceType) external pure returns (bool) {
        return true;
    }

    function setEnclaveHash(bytes32, bool, TeeType, ServiceType) external {}

    function deleteEnclaveHashes(bytes32[] memory, TeeType, ServiceType) external {}

    function setQuoteVerifier(address) external {}

    function setNitroEnclaveVerifier(address) external {}
}

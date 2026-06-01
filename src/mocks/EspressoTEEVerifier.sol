// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEspressoTEEVerifier} from "../bridge/EspressoTEE.sol";
import {IEspressoNitroTEEVerifier} from "../bridge/EspressoNitroTEEVerifier.sol";

/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the V3QuoteVerifier contract
 *         to verify the quote. Along with some additional verification logic.
 */
contract EspressoTEEVerifierMock is IEspressoTEEVerifier {
    mapping(address => bool) public registeredSigner;

    constructor() {}

    function verify(
        bytes calldata signature,
        bytes32 userDataHash,
        IEspressoTEEVerifier.TeeType teeType
    ) external view returns (bool) {
        return true;
    }

    function espressoNitroTEEVerifier() external view returns (IEspressoNitroTEEVerifier) {
        return IEspressoNitroTEEVerifier(address(0));
    }

    function registerService(bytes calldata, bytes calldata, TeeType) external {}

    function registeredEnclaveHashes(bytes32, TeeType) external view returns (bool) {
        return false;
    }

    function isSignerValid(address, TeeType) external view returns (bool) {
        return true;
    }

    function setEspressoNitroTEEVerifier(IEspressoNitroTEEVerifier) external {}

    function setEnclaveHash(bytes32, bool, TeeType) external {}

    function deleteEnclaveHashes(bytes32[] memory, TeeType) external {}

    function setNitroEnclaveVerifier(address) external {}
}

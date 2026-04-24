// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEspressoTEEVerifier} from "espresso-tee-contracts/interface/IEspressoTEEVerifier.sol";
import {IEspressoNitroTEEVerifier} from "espresso-tee-contracts/interface/IEspressoNitroTEEVerifier.sol";

/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Mock contract that always returns true for verification.
 */
contract EspressoTEEVerifierMock is IEspressoTEEVerifier {

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
        return false;
    }

    function setEspressoNitroTEEVerifier(IEspressoNitroTEEVerifier) external {}

    function setEnclaveHash(bytes32, bool, TeeType) external {}

    function deleteEnclaveHashes(bytes32[] memory, TeeType) external {}

    function setNitroEnclaveVerifier(address) external {}
}

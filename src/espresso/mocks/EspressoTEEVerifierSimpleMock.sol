// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEspressoTEEVerifier} from "../IEspressoTEEVerifier.sol";
import {IEspressoNitroTEEVerifier} from "../IEspressoNitroTEEVerifier.sol";

/// @title EspressoTEEVerifierSimpleMock - Always returns true for verify()
/// @notice Used in Hardhat tests where computing a valid TEE signature is impractical
///         (e.g. blob batch tests where the digest depends on runtime blob hashes).
contract EspressoTEEVerifierSimpleMock is IEspressoTEEVerifier {
    function verify(
        bytes memory,
        bytes32,
        TeeType
    ) external pure override returns (bool) {
        return true;
    }

    function espressoNitroTEEVerifier() external pure returns (IEspressoNitroTEEVerifier) {
        return IEspressoNitroTEEVerifier(address(0));
    }

    function registerService(bytes calldata, bytes calldata, TeeType) external {}

    function registeredEnclaveHashes(bytes32, TeeType) external pure returns (bool) {
        return false;
    }

    function isSignerValid(address, TeeType) external pure returns (bool) {
        return false;
    }

    function setEspressoNitroTEEVerifier(IEspressoNitroTEEVerifier) external {}

    function setEnclaveHash(bytes32, bool, TeeType) external {}

    function deleteEnclaveHashes(bytes32[] memory, TeeType) external {}

    function setNitroEnclaveVerifier(address) external {}
}

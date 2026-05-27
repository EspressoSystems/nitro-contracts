// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEspressoTEEVerifier} from "../../src/espresso/IEspressoTEEVerifier.sol";
import {IEspressoNitroTEEVerifier} from "../../src/espresso/IEspressoNitroTEEVerifier.sol";

/**
 * @title EspressoTEEVerifierMock - Always returns true
 */
contract EspressoTEEVerifierMock is IEspressoTEEVerifier {
    function verify(bytes memory signature, bytes32 userDataHash, TeeType teeType)
        external
        view
        override
        returns (bool)
    {
        (signature, userDataHash, teeType);
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

/**
 * @title EspressoTEEVerifierMockFalse - Always returns false
 */
contract EspressoTEEVerifierMockFalse is IEspressoTEEVerifier {
    function verify(bytes memory signature, bytes32 userDataHash, TeeType teeType)
        external
        view
        override
        returns (bool)
    {
        (signature, userDataHash, teeType);
        return false;
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

/**
 * @title EspressoTEEVerifierMockRevert - Always reverts
 */
contract EspressoTEEVerifierMockRevert is IEspressoTEEVerifier {
    function verify(bytes memory signature, bytes32 userDataHash, TeeType teeType)
        external
        view
        override
        returns (bool)
    {
        (signature, userDataHash, teeType);
        revert InvalidSignature();
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
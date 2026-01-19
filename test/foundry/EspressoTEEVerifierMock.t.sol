// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/bridge/EspressoTEE.sol";

/**
 * @title EspressoTEEVerifierMock - Always returns true
 */
contract EspressoTEEVerifierMock is IEspressoTEEVerifier {
    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        TeeType teeType,
        ServiceType service
    ) external view override returns (bool) {
        (signature, userDataHash, teeType, service);
        return true;
    }
}

/**
 * @title EspressoTEEVerifierMockFalse - Always returns false
 */
contract EspressoTEEVerifierMockFalse is IEspressoTEEVerifier {
    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        TeeType teeType,
        ServiceType service
    ) external view override returns (bool) {
        (signature, userDataHash, teeType, service);
        return false;
    }
}

/**
 * @title EspressoTEEVerifierMockRevert - Always reverts
 */
contract EspressoTEEVerifierMockRevert is IEspressoTEEVerifier {
    error InvalidSignature();

    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        TeeType teeType,
        ServiceType service
    ) external view override returns (bool) {
        (signature, userDataHash, teeType, service);
        revert InvalidSignature();
    }
}

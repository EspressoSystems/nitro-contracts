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
        TeeType teeType
    ) external view override returns (bool) {
        (signature, userDataHash, teeType);
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
        TeeType teeType
    ) external view override returns (bool) {
        (signature, userDataHash, teeType);
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
        TeeType teeType
    ) external view override returns (bool) {
        (signature, userDataHash, teeType);
        revert InvalidSignature();
    }
}

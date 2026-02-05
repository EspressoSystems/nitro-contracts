// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/bridge/EspressoTEE.sol";

contract EspressoTEEVerifierMock is IEspressoTEEVerifier {
    /**
     * @notice Verify signature from a registered signer. This mock always returns true.
     * @param signature The signature of the user data
     * @param userDataHash The hash of the user data
     * @param teeType The type of TEE
     * @param service The type of service
     */
    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        TeeType teeType,
        ServiceType service
    ) external view override returns (bool) {
        // Unused parameters to avoid compiler warnings.
        (signature, userDataHash, teeType, service);
        return true;
    }
}

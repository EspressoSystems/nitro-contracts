// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum ServiceType {
    BatchPoster,
    CaffNode
}

contract EspressoTEEVerifierMock {
    enum TeeType {
        SGX,
        NITRO
    }

    /**
     * @notice Verify signature from a registered signer
     * @param signature The signature of the user data
     * @param userDataHash The hash of the user data
     * @param teeType The type of TEE
     */
    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        TeeType teeType,
        ServiceType service
    ) external view returns (bool) {
        return true;
    }

}
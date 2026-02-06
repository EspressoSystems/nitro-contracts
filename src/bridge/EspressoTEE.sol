// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// @dev Copied from https://github.com/EspressoSystems/espresso-tee-contracts@v1.1.0

enum ServiceType {
    BatchPoster,
    CaffNode
}

interface IEspressoTEEVerifier {

    enum TeeType {
        SGX,
        NITRO
    }

    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        TeeType teeType,
        ServiceType service
    ) external view returns (bool);
}

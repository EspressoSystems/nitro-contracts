// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// @dev Copied from https://github.com/EspressoSystems/espresso-tee-contracts

interface IEspressoTEEVerifier {

    enum TeeType {
        NITRO
    }

    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        TeeType teeType
    ) external view returns (bool);
}

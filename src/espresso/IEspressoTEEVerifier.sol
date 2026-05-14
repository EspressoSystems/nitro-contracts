// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEspressoNitroTEEVerifier} from "./IEspressoNitroTEEVerifier.sol";

interface IEspressoTEEVerifier {
    error InvalidVerifierAddress();
    error UnsupportedTeeType(TeeType teeType);
    error InvalidSignature();

    event EspressoNitroTEEVerifierSet(address indexed oldVerifier, address indexed newVerifier);

    enum TeeType {
        NITRO
    }

    function espressoNitroTEEVerifier() external view returns (IEspressoNitroTEEVerifier);

    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        TeeType teeType
    ) external view returns (bool);

    function registerService(
        bytes calldata verificationData,
        bytes calldata data,
        TeeType teeType
    ) external;

    function registeredEnclaveHashes(
        bytes32 enclaveHash,
        TeeType teeType
    ) external view returns (bool);

    function isSignerValid(
        address signer,
        TeeType teeType
    ) external view returns (bool);

    function setEspressoNitroTEEVerifier(
        IEspressoNitroTEEVerifier _espressoNitroTEEVerifier
    ) external;

    function setEnclaveHash(
        bytes32 enclaveHash,
        bool valid,
        TeeType teeType
    ) external;

    function deleteEnclaveHashes(
        bytes32[] memory enclaveHashes,
        TeeType teeType
    ) external;

    function setNitroEnclaveVerifier(
        address nitroVerifier
    ) external;
}

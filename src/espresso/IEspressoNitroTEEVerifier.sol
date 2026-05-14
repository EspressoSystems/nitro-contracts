// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEspressoNitroTEEVerifier {
    function registerService(bytes calldata output, bytes calldata proofBytes) external;

    function registeredEnclaveHash(bytes32 enclaveHash) external view returns (bool);

    function isSignerValid(address signer) external view returns (bool);

    function setEnclaveHash(bytes32 enclaveHash, bool valid) external;
}

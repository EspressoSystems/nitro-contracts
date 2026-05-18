// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EspressoNitroTEEVerifierMock {
    mapping(bytes32 => bool) public registeredEnclaveHashes;
    mapping(address => bool) public registeredServices;

    function registerService(bytes calldata, bytes calldata) external {}

    function registeredEnclaveHash(
        bytes32 enclaveHash
    ) external view returns (bool) {
        return registeredEnclaveHashes[enclaveHash];
    }

    function isSignerValid(
        address signer
    ) external view returns (bool) {
        return registeredServices[signer];
    }

    function setSignerValid(address signer, bool valid) external {
        registeredServices[signer] = valid;
    }

    function setEnclaveHash(bytes32 enclaveHash, bool valid) external {
        registeredEnclaveHashes[enclaveHash] = valid;
    }
}

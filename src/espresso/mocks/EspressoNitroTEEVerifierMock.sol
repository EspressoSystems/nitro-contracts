// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EspressoNitroTEEVerifierMock {
    mapping(bytes32 => bool) public registeredEnclaveHashes;
    mapping(address => bool) public registeredServices;

    struct Bytes48 {
        bytes32 first;
        bytes16 second;
    }

    struct Pcr {
        uint64 index;
        Bytes48 value;
    }

    struct VerifierJournal {
        uint8 result;
        uint8 trustedCertsPrefixLen;
        uint64 timestamp;
        bytes32[] certs;
        bytes userData;
        bytes nonce;
        bytes publicKey;
        Pcr[] pcrs;
        string moduleId;
    }

    /// @notice Decodes the signer's public key from the journal and marks it
    ///         as registered. The real verifier validates the attestation +
    ///         proof; the mock only needs to extract the key so that
    ///         `isSignerValid` returns true after registration.
    function registerService(bytes calldata output, bytes calldata) external {
        VerifierJournal memory journal = abi.decode(output, (VerifierJournal));
        bytes memory pubKey = journal.publicKey;
        require(pubKey.length == 65, "invalid public key length");

        // Derive the Ethereum address from the uncompressed ECDSA public key.
        // Memory layout of `bytes`: 32-byte length prefix, then data.
        // Skip both the length prefix (32 bytes) and the 0x04 EC prefix (1 byte)
        // to hash the raw 64-byte (X || Y) coordinates.
        bytes32 hash;
        assembly {
            hash := keccak256(add(pubKey, 33), 64)
        }
        address signer = address(uint160(uint256(hash)));
        registeredServices[signer] = true;
    }

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

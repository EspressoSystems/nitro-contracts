// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITEEHelper {
    // Thrown when a caller is not the tee verifier
    error UnauthorizedTEEVerifier(address caller);
    // Thrown when a zero tee verifier address is provided
    error InvalidTEEVerifierAddress();
    // Thrown when an invalid enclave hash is provided
    // function signature: 0x94f1e6f9
    error InvalidEnclaveHash(bytes32 enclaveHash);
    // Thrown when an invalid signer address is provided
    // function signature: 0x4501a919
    error InvalidSignerAddress();

    // Emitted when an enclave hash is deleted
    event DeletedEnclaveHash(bytes32 indexed enclaveHash);

    // Emitted when a registered service is deleted
    event DeletedRegisteredService(address indexed signer);

    // Emitted when a service is registered
    event ServiceRegistered(address indexed signer, bytes32 indexed enclaveHash);

    // Emitted when the tee verifier is set
    event TeeVerifierSet(address indexed teeVerifier);

    // Emitted when an enclave hash is set
    event EnclaveHashSet(bytes32 indexed enclaveHash, bool indexed valid);

    /**
     * @notice Allows the tee verifier to set the enclave hash, setting valid to true will allow any enclave
     * with a valid pcr0 hash to register a signer (address which was generated inside the TEE). Setting valid to false
     * will further remove the enclave hash from the registered enclave hash list thus preventing any enclave with the given
     * hash from registering a signer.
     * @param enclaveHash The hash of the enclave
     * @param valid Whether the enclave hash is valid or not
     */
    function setEnclaveHash(bytes32 enclaveHash, bool valid) external;

    /*
     * @notice Returns the tee verifier allowed to administer helpers
     */
    function teeVerifier() external view returns (address);

    /*
     * @notice This function retrieves whether an enclave hash is registered or not
     * @param enclaveHash The hash of the enclave
     * @return bool True if the enclave hash is registered, false otherwise
     */
    function registeredEnclaveHash(bytes32 enclaveHash) external view returns (bool);

    /*
     * @notice Validates if a signer is registered AND its enclave hash is still valid
     * @param signer The address of the signer
     * @return bool True if signer is registered AND its enclave hash is still approved
     */
    function isSignerValid(address signer) external view returns (bool);

    /*
     * @notice Allows the tee verifier to delete registered enclave hashes from the list of valid enclave hashes
     * @param enclaveHashes The array of enclave hashes to delete
     */
    function deleteEnclaveHashes(bytes32[] memory enclaveHashes) external;
}

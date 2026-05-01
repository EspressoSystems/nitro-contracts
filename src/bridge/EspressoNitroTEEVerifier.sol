// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITEEHelper.sol";

interface IEspressoNitroTEEVerifier is ITEEHelper {
    // This error is thrown when the NitroEnclaveVerifier address is invalid
    error InvalidNitroEnclaveVerifierAddress();

    event NitroEnclaveVerifierSet(address nitroEnclaveVerifierAddress);

    /*
     * @notice This function registers a new Service by verifying an attestation from the AWS Nitro Enclave (TEE)
     * The signer is not the caller of the function but the address which was generated inside the TEE.
     * @param output The public output of the ZK proof
     * @param proofBytes The cryptographic proof bytes over attestation
     */
    function registerService(bytes calldata output, bytes calldata proofBytes) external;

    /*
     * @notice This function sets the NitroEnclaveVerifier contract address
     */
    function setNitroEnclaveVerifier(address nitroEnclaveVerifierAddress) external;
}

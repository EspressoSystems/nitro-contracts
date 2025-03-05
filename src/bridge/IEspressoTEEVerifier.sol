// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EspressoSGXTEEVerifier} from "./EspressoSGXTEEVerifier.sol";
import {EspressoNitroTEEVerifier} from "./EspressoNitroTEEVerifier.sol";

/**
 * @title  Interface for the EspressoTEEVerifier contract
 * @notice This interface allows interaction with the EspressoTEEVerifier contract functions
 */
interface IEspressoTEEVerifier {
    enum TeeType {
        SGX,
        NITRO
    }

    /**
     * @notice Verifies that a given signature corresponds to a valid signer
     * @param signature The signature to verify
     * @param userDataHash The user data hash to verify against
     */
    function verify(bytes memory signature, bytes32 userDataHash) external view;

    /**
     * @notice Registers a new signer for the given attestation and signature
     * @param attestation The attestation to register
     * @param signature The signature to validate and register
     * @param teeType The type of TEE (SGX or NITRO) for the registration
     */
    function registerSigner(
        bytes calldata attestation,
        bytes calldata signature,
        TeeType teeType
    ) external;

    /**
     * @notice Sets the enclave hash validity for a given TEE type
     * @param enclaveHash The hash of the enclave to validate
     * @param valid A boolean indicating if the enclave hash is valid
     * @param teeType The type of TEE (SGX or NITRO) for the enclave hash setting
     */
    function setEnclaveHash(bytes calldata enclaveHash, bool valid, TeeType teeType) external;

    /**
     * @notice Sets a new EspressoNitroTEEVerifier contract address
     * @param _espressoNitroTEEVerifier The new EspressoNitroTEEVerifier contract address
     */
    function setEspressoNitroTEEVerifier(
        EspressoNitroTEEVerifier _espressoNitroTEEVerifier
    ) external;

    /**
     * @notice Sets a new EspressoSGXTEEVerifier contract address
     * @param _espressoSGXTEEVerifier The new EspressoSGXTEEVerifier contract address
     */
    function setEspressoSGXTEEVerifier(EspressoSGXTEEVerifier _espressoSGXTEEVerifier) external;
}

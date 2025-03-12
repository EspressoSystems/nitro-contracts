// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IEspressoSGXTEEVerifier} from "./IEspressoSGXTEEVerifier.sol";
import {IEspressoTEEVerifier} from "./IEspressoTEEVerifier.sol";

/**
    @title EspressoTEEVerifier
    @author Espresso Systems (https://espresso.systems)
    @notice This contract is used to resgister a signer which has been attested by the TEE
*/
contract EspressoTEEVerifier is Ownable2Step, IEspressoTEEVerifier {
    IEspressoSGXTEEVerifier public espressoSGXTEEVerifier;

    constructor(IEspressoSGXTEEVerifier _espressoSGXTEEVerifier) {
        espressoSGXTEEVerifier = _espressoSGXTEEVerifier;
    }

    /**
        @notice This function is used to verify the signature of the user data
        @param signature The signature of the user data
        @param userDataHash The hash of the user data
     */
    function verify(bytes memory signature, bytes32 userDataHash) external view {
        address signer = ECDSA.recover(userDataHash, signature);

        if (!espressoSGXTEEVerifier.registeredSigners(signer)) {
            revert InvalidSignature();
        }
    }

    /* @notice Register a new signer by verifying a quote from the TEE
        @param attestation The attestation from the TEE
        @param data when registering a signer, data can be passed for each TEE type
        which can be any additiona data that is required for registering a signer
        @param teeType The type of TEE
     */
    function registerSigner(
        bytes calldata attestation,
        bytes calldata data,
        TeeType teeType
    ) external {
        if (teeType == TeeType.SGX) {
            espressoSGXTEEVerifier.registerSigner(attestation, data);
            return;
        }
        revert UnsupportedTeeType();
    }

    /**
        @notice This function retrieves whether a signer is registered or not
        @param signer The address of the signer
        @param teeType The type of TEE
     */
    function registeredSigners(address signer, TeeType teeType) external view returns (bool) {
        if (teeType == TeeType.SGX) {
            return espressoSGXTEEVerifier.registeredSigners(signer);
        }
        revert UnsupportedTeeType();
    }

    /**
        @notice This function retrieves whether an enclave hash is registered or not
        @param enclaveHash The hash of the enclave
        @param teeType The type of TEE
     */
    function registeredEnclaveHashes(
        bytes32 enclaveHash,
        TeeType teeType
    ) external view returns (bool) {
        if (teeType == TeeType.SGX) {
            return espressoSGXTEEVerifier.registeredEnclaveHash(enclaveHash);
        }
        revert UnsupportedTeeType();
    }

    /**
        @notice This function retrieves whether an enclave signer is registered or not
        @param enclaveSigner The enclave signer
        @param teeType The type of TEE
     */

    function registeredEnclaveSigners(
        bytes32 enclaveSigner,
        TeeType teeType
    ) external view returns (bool) {
        if (teeType == TeeType.SGX) {
            return espressoSGXTEEVerifier.registeredEnclaveSigner(enclaveSigner);
        }
        revert UnsupportedTeeType();
    }

    /*
        @notice Set the EspressoSGXTEEVerifier
        @param _espressoSGXTEEVerifier The address of the EspressoSGXTEEVerifier
     */
    function setEspressoSGXTEEVerifier(
        IEspressoSGXTEEVerifier _espressoSGXTEEVerifier
    ) public onlyOwner {
        espressoSGXTEEVerifier = _espressoSGXTEEVerifier;
    }
}

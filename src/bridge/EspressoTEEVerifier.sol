// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import {EspressoSGXTEEVerifier} from "./EspressoSGXTEEVerifier.sol";
import {EspressoNitroTEEVerifier} from "./EspressoNitroTEEVerifier.sol";

/**
 *
 * @title  Verifies userDataHash is from a valid signer
 * @notice These signers are registered in the EspressoNitroTEEVerifier and EspressoSGXTEEVerifier contracts
 */
contract EspressoTEEVerifier is Ownable2Step {
    EspressoSGXTEEVerifier public espressoSGXTEEVerifier;
    EspressoNitroTEEVerifier public espressoNitroTEEVerifier;

    enum TeeType {
        SGX,
        NITRO
    }

    constructor(
        EspressoSGXTEEVerifier espressoSGXTEEVerifier,
        EspressoNitroTEEVerifier espressoNitroTEEVerifier
    ) {
        espressoSGXTEEVerifier = espressoSGXTEEVerifier;
        espressoNitroTEEVerifier = espressoNitroTEEVerifier;
    }

    function verify(bytes memory signature, bytes32 userDataHash) external view {
        address signer = ECDSA.recover(userDataHash, signature);

        bool validNitroSigner = espressoNitroTEEVerifier.registeredSigners(signer);
        bool validSGXSigner = espressoSGXTEEVerifier.registeredSigners(signer);
        // we check if the signer is registerd in either of the Verifier contracts and if not we revert
        if (!validNitroSigner && !validSGXSigner) {
            revert InvalidSignature();
        }
    }

    function registerSigner(
        bytes calldata attestation,
        bytes calldata signature,
        TeeType teeType
    ) external {
        if (teeType == TeeType.SGX) {
            espressoSGXTEEVerifier.registerSigner(attestation, signature);
        } else if (teeType == TeeType.NITRO) {
            espressoNitroTEEVerifier.registerSigner(attestation, signature);
        }
    }

    function setEnclaveHash(
        bytes calldata enclaveHash,
        bool valid,
        TeeType teeType
    ) external onlyOwner {
        if (teeType == TeeType.SGX) {
            espressoSGXTEEVerifier.setEnclaveHash(enclaveHash, valid);
        } else if (teeType == TeeType.NITRO) {
            espressoNitroTEEVerifier.setEnclaveHash(enclaveHash, valid);
        }
    }

    function deleteResgiteredSigner(address signer, TeeType teeType) external onlyOwner {
        if (teeType == TeeType.SGX) {
            espressoSGXTEEVerifier.deleteResgiteredSigner(signer);
        } else if (teeType == TeeType.NITRO) {
            espressoNitroTEEVerifier.deleteResgiteredSigner(signer);
        }
    }

    function setEspressoNitroTEEVerifier(
        EspressoNitroTEEVerifier _espressoNitroTEEVerifier
    ) public onlyOwner {
        espressoNitroTEEVerifier = _espressoNitroTEEVerifier;
    }

    function setEspressoSGXTEEVerifier(
        EspressoSGXTEEVerifier _espressoSGXTEEVerifier
    ) public onlyOwner {
        espressoSGXTEEVerifier = _espressoSGXTEEVerifier;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {IEspressoTEEVerifier} from "../IEspressoTEEVerifier.sol";
import {IEspressoNitroTEEVerifier} from "../IEspressoNitroTEEVerifier.sol";

contract EspressoTEEVerifierMock is EIP712 {
    IEspressoNitroTEEVerifier public espressoNitroTEEVerifier;

    bytes32 private constant ESPRESSO_TEE_VERIFIER_TYPE_HASH =
        keccak256("EspressoTEEVerifier(bytes32 commitment)");

    constructor(
        IEspressoNitroTEEVerifier _espressoNitroTEEVerifier
    ) EIP712("EspressoTEEVerifier", "1") {
        espressoNitroTEEVerifier = _espressoNitroTEEVerifier;
    }

    function _requireNitroTeeType(
        IEspressoTEEVerifier.TeeType teeType
    ) private pure {
        if (teeType != IEspressoTEEVerifier.TeeType.NITRO) {
            revert IEspressoTEEVerifier.UnsupportedTeeType(teeType);
        }
    }

    function verify(
        bytes memory signature,
        bytes32 userDataHash,
        IEspressoTEEVerifier.TeeType teeType
    ) external view returns (bool) {
        _requireNitroTeeType(teeType);

        bytes32 structHash = keccak256(abi.encode(ESPRESSO_TEE_VERIFIER_TYPE_HASH, userDataHash));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, signature);

        if (!espressoNitroTEEVerifier.isSignerValid(signer)) {
            revert IEspressoTEEVerifier.InvalidSignature();
        }

        return true;
    }

    function registerService(
        bytes calldata attestation,
        bytes calldata data,
        IEspressoTEEVerifier.TeeType teeType
    ) external {
        _requireNitroTeeType(teeType);
        espressoNitroTEEVerifier.registerService(attestation, data);
    }

    function isSignerValid(
        address signer,
        IEspressoTEEVerifier.TeeType teeType
    ) external view returns (bool) {
        _requireNitroTeeType(teeType);
        return espressoNitroTEEVerifier.isSignerValid(signer);
    }

    function registeredEnclaveHashes(
        bytes32 enclaveHash,
        IEspressoTEEVerifier.TeeType teeType
    ) external view returns (bool) {
        _requireNitroTeeType(teeType);
        return espressoNitroTEEVerifier.registeredEnclaveHash(enclaveHash);
    }

    function setEspressoNitroTEEVerifier(
        IEspressoNitroTEEVerifier _espressoNitroTEEVerifier
    ) external {
        espressoNitroTEEVerifier = _espressoNitroTEEVerifier;
    }

    function setEnclaveHash(
        bytes32,
        bool,
        IEspressoTEEVerifier.TeeType
    ) external pure {
        revert("not implemented");
    }

    function deleteEnclaveHashes(
        bytes32[] memory,
        IEspressoTEEVerifier.TeeType
    ) external pure {
        revert("not implemented");
    }

    function setNitroEnclaveVerifier(
        address
    ) external pure {
        revert("not implemented");
    }
}

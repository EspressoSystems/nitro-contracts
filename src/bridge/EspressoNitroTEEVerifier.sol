// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {NitroValidator} from "@nitro-validator/NitroValidator.sol";
import {CborDecode} from "@nitro-validator/CborDecode.sol";
import {CertManager} from "@nitro-validator/CertManager.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/*
    The code of this contract is inspired from SystemConfigGlobal.sol
    (https://github.com/base/op-enclave/blob/main/contracts/src/SystemConfigGlobal.sol)
*/

contract EspressoNitroTEEVerifier is NitroValidator, Ownable2Step {
    using LibBytes for bytes;
    using CborDecode for bytes;
    using LibCborElement for CborElement;

    uint256 public constant MAX_AGE = 60 minutes;
    error InvalidEnclaveHash();
    error AttestationTooOld();

    mapping(bytes32 => bool) public registeredEnclaveHash;

    mapping(address => bool) public registeredSigners;

    constructor(ICertManager certManager) NitroValidator(certManager) {}

    function registerSigner(bytes calldata attestationTbs, bytes calldata signature) external {
        Ptrs memory ptrs = validateAttestation(attestationTbs, signature);
        bytes32 pcr0 = attestationTbs.keccak(ptrs.pcrs[0]);
        if (!validPCR0s[pcr0]) {
            revert InvalidEnclaveHash();
        }
        if (ptrs.timestamp + MAX_AGE > block.timestamp) {
            revert AttestationTooOld();
        }
        // The publicKey's first byte 0x04 byte followed which only determine if the public key is compressed or not.
        // so we ignore the first byte.
        bytes32 publicKeyHash = attestationTbs.keccak(
            ptrs.publicKey.start() + 1,
            ptrs.publicKey.length() - 1
        );
        address enclaveAddress = address(uint160(uint256(publicKeyHash)));
        registeredSigners[enclaveAddress] = true;
    }

    function setEnclaveHash(bytes calldata enclaveHash, bool valid) external onlyOwner {
        if (valid) {
            registredEnclaveHash[keccak256(enclaveHash)] = true;
        } else {
            delete registredEnclaveHash[keccak256(enclaveHash)];
        }
    }

    function deleteRegisteredSigner(address signer) external onlyOwner {
        delete registeredSigners[signer];
    }
}

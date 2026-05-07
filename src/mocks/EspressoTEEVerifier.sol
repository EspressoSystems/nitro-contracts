// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEspressoTEEVerifier} from "../bridge/EspressoTEE.sol";
import {IEspressoNitroTEEVerifier} from "../bridge/EspressoNitroTEEVerifier.sol";

/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the V3QuoteVerifier contract
 *         to verify the quote. Along with some additional verification logic.
 */
contract EspressoTEEVerifierMock is IEspressoTEEVerifier {
    struct PCRValue {
        bytes32 first;
        bytes16 second;
    }

    struct PCR {
        uint64 index;
        PCRValue value;
    }

    struct VerifierJournal {
        uint8 result;
        uint8 trustedCertsPrefixLen;
        uint64 timestamp;
        bytes32[] certs;
        bytes userData;
        bytes nonce;
        bytes publicKey;
        PCR[] pcrs;
        string moduleId;
    }

    mapping(address => bool) public registeredSigner;

    constructor() {}

    function verify(
        bytes calldata signature,
        bytes32 userDataHash,
        IEspressoTEEVerifier.TeeType teeType
    ) external view returns (bool) {
        return true;
    }

    function espressoNitroTEEVerifier() external view returns (IEspressoNitroTEEVerifier) {
        return IEspressoNitroTEEVerifier(address(0));
    }

    function registerService(bytes calldata output, bytes calldata, TeeType) external {
        VerifierJournal memory journal = abi.decode(output, (VerifierJournal));
        bytes memory pubKey = journal.publicKey;
        if (pubKey.length == 65 && pubKey[0] == 0x04) {
            assembly { pubKey := add(pubKey, 1) mstore(pubKey, 64) }
        }
        address signer = address(uint160(uint256(keccak256(pubKey))));
        registeredSigner[signer] = true;
    }

    function registeredEnclaveHashes(bytes32, TeeType) external view returns (bool) {
        return false;
    }

    function isSignerValid(address signer, TeeType) external view returns (bool) {
        return registeredSigner[signer];
    }

    function setEspressoNitroTEEVerifier(IEspressoNitroTEEVerifier) external {}

    function setEnclaveHash(bytes32, bool, TeeType) external {}

    function deleteEnclaveHashes(bytes32[] memory, TeeType) external {}

    function setNitroEnclaveVerifier(address) external {}
}

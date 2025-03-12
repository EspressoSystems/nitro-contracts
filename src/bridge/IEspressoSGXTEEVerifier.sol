// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Header} from "@automata-network/dcap-attestation/contracts/types/CommonStruct.sol";
import {EnclaveReport} from "@automata-network/dcap-attestation/contracts/types/V3Structs.sol";

interface IEspressoSGXTEEVerifier {
    // We only support version 3 for now
    error InvalidHeaderVersion();
    // This error is thrown when the automata verification fails
    error InvalidQuote();
    // This error is thrown when the enclave report fails to parse
    error FailedToParseEnclaveReport();
    // This error is thrown when the mrEnclave don't match
    error InvalidEnclaveHash();
    // This error is thrown when the mrSigner don't match
    error InvalidEnclaveSigner();
    // This error is thrown when the reportDataHash doesn't match the hash signed by the TEE
    error InvalidReportDataHash();
    // This error is thrown when the reportData is too short
    error ReportDataTooShort();
    // This error is thrown when the data length is invalid
    error InvalidDataLength();
    // This error is thrown when the signer address is invalid
    error InvalidSignerAddress();

    event EnclaveHashSet(bytes32 enclaveHash, bool valid);
    event EnclaveSignerSet(bytes32 enclaveSigner, bool valid);

    function registeredSigners(address signer) external view returns (bool);
    function registeredEnclaveHash(bytes32 enclaveHash) external view returns (bool);
    function registeredEnclaveSigner(bytes32 enclaveSigner) external view returns (bool);

    function registerSigner(bytes calldata attestation, bytes calldata data) external;

    function verify(
        bytes calldata rawQuote,
        bytes32 reportDataHash
    ) external view returns (EnclaveReport memory);

    function parseQuoteHeader(bytes calldata rawQuote) external pure returns (Header memory header);

    function parseEnclaveReport(
        bytes memory rawEnclaveReport
    ) external pure returns (bool success, EnclaveReport memory enclaveReport);

    function setEnclaveHash(bytes32 enclaveHash, bool valid) external;
    function setEnclaveSigner(bytes32 enclaveSigner, bool valid) external;
    function deleteRegisteredSigner(address signer) external;
}

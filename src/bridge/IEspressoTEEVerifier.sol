// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Header} from "@automata-network/dcap-attestation/contracts/types/CommonStruct.sol";
import {EnclaveReport} from "@automata-network/dcap-attestation/contracts/types/V3Structs.sol";

interface IEspressoTEEVerifier {
    // We only support version 3 for now
    error InvalidHeaderVersion();
    // This error is thrown when the automata verification fails
    error InvalidQuote();
    // This error is thrown when the enclave report fails to parse
    error FailedToParseEnclaveReport();
    // This error is thrown when the mrEnclave and mrSigner don't match
    error InvalidMREnclaveOrSigner();
    // This error is thrown when the reportDataHash doesn't match the hash signed by the TEE
    error InvalidReportDataHash();

    event MREnclaveSet(bytes32 indexed mrEnclave);
    event MRSignerSet(bytes32 indexed mrSigner);

    function verify(bytes calldata rawQuote, bytes32 reportDataHash) external view;

    function parseQuoteHeader(bytes calldata rawQuote) external pure returns (Header memory header);

    function parseEnclaveReport(
        bytes memory rawEnclaveReport
    ) external pure returns (bool success, EnclaveReport memory enclaveReport);

    function mrEnclaves(bytes32 _mrEnclave) external view returns (bool);
    function mrSigners(bytes32 _mrSigner) external view returns (bool);

    function setMrEnclave(bytes32 _mrEnclave, bool _isValid) external;

    function setMrSigner(bytes32 _mrSigner, bool _isValid) external;
}

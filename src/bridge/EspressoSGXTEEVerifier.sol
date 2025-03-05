// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    V3QuoteVerifier
} from "@automata-network/dcap-attestation/contracts/verifiers/V3QuoteVerifier.sol";
import {BELE} from "@automata-network/dcap-attestation/contracts/utils/BELE.sol";
import {Header} from "@automata-network/dcap-attestation/contracts/types/CommonStruct.sol";
import {
    IQuoteVerifier
} from "@automata-network/dcap-attestation/contracts/interfaces/IQuoteVerifier.sol";
import {
    HEADER_LENGTH,
    ENCLAVE_REPORT_LENGTH
} from "@automata-network/dcap-attestation/contracts/types/Constants.sol";
import {EnclaveReport} from "@automata-network/dcap-attestation/contracts/types/V3Structs.sol";
import {BytesUtils} from "@automata-network/dcap-attestation/contracts/utils/BytesUtils.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IEspressoSGXTEEVerifier} from "./IEspressoSGXTEEVerifier.sol";

/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the V3QuoteVerifier contract
 *         from automata to verify the quote. Along with some additional verification logic.
 */
contract EspressoSGXTEEVerifier is IEspressoSGXTEEVerifier, Ownable2Step {
    using BytesUtils for bytes;
    error InvalidEnclaveHash();
    // V3QuoteVerififer contract from automata to verify the quote
    V3QuoteVerifier public quoteVerifier;

    mapping(bytes32 => bool) public registeredEnclaveHash;
    mapping(address => bool) public registeredSigners;

    constructor(address _quoteVerifier) {
        quoteVerifier = V3QuoteVerifier(_quoteVerifier);
    }

    /*
        @notice Verify a quote from the TEE and attest on-chain
        The verification is considered successful if the function does not revert.
        @param attestation The attestation from the TEE
        @param The second argument is not used but added so that we can get the same ABI 
        as the EspressoNitroTEEVerifier
    */
    function registerSigner(bytes calldata attestation, bytes calldata) external {
        // Parse the header
        Header memory header = parseQuoteHeader(attestation);

        // Currently only version 3 is supported
        if (header.version != 3) {
            revert InvalidHeaderVersion();
        }

        // Verify the quote
        (bool success, ) = quoteVerifier.verifyQuote(header, attestation);
        if (!success) {
            revert InvalidQuote();
        }

        // Parse enclave quote
        uint256 lastIndex = HEADER_LENGTH + ENCLAVE_REPORT_LENGTH;
        EnclaveReport memory localReport;
        (success, localReport) = parseEnclaveReport(rawQuote[HEADER_LENGTH:lastIndex]);
        if (!success) {
            revert FailedToParseEnclaveReport();
        }

        if (localReport.mrEnclave != mrEnclave) {
            revert InvalidEnclaveHash();
        }

        // Check that reportData is indeed a valid address
        if (localReport.reportData.length != 20) {
            revert InvalidReportData();
        }
        // Register this new signer
        address signer = address(uint160(uint256(keccak256(localReport.reportData))));
        registeredSigners[signer] = true;
    }

    /*
        @notice Parses the header from the quote
        @param rawQuote The raw quote in bytes
        @return header The parsed header
    */
    function parseQuoteHeader(bytes calldata rawQuote) public pure returns (Header memory header) {
        header = Header({
            version: uint16(BELE.leBytesToBeUint(rawQuote[0:2])),
            attestationKeyType: bytes2(rawQuote[2:4]),
            teeType: bytes4(uint32(BELE.leBytesToBeUint(rawQuote[4:8]))),
            qeSvn: bytes2(rawQuote[8:10]),
            pceSvn: bytes2(rawQuote[10:12]),
            qeVendorId: bytes16(rawQuote[12:28]),
            userData: bytes20(rawQuote[28:48])
        });
    }

    /*
        @notice Parses the enclave report from the quote
        @param rawEnclaveReport The raw enclave report from the quote in bytes
        @return success True if the enclave report was parsed successfully
        @return enclaveReport The parsed enclave report
    */
    function parseEnclaveReport(
        bytes memory rawEnclaveReport
    ) public pure returns (bool success, EnclaveReport memory enclaveReport) {
        if (rawEnclaveReport.length != ENCLAVE_REPORT_LENGTH) {
            return (false, enclaveReport);
        }
        enclaveReport.cpuSvn = bytes16(rawEnclaveReport.substring(0, 16));
        enclaveReport.miscSelect = bytes4(rawEnclaveReport.substring(16, 4));
        enclaveReport.reserved1 = bytes28(rawEnclaveReport.substring(20, 28));
        enclaveReport.attributes = bytes16(rawEnclaveReport.substring(48, 16));
        enclaveReport.mrEnclave = bytes32(rawEnclaveReport.substring(64, 32));
        enclaveReport.reserved2 = bytes32(rawEnclaveReport.substring(96, 32));
        enclaveReport.mrSigner = bytes32(rawEnclaveReport.substring(128, 32));
        enclaveReport.reserved3 = rawEnclaveReport.substring(160, 96);
        enclaveReport.isvProdId = uint16(BELE.leBytesToBeUint(rawEnclaveReport.substring(256, 2)));
        enclaveReport.isvSvn = uint16(BELE.leBytesToBeUint(rawEnclaveReport.substring(258, 2)));
        enclaveReport.reserved4 = rawEnclaveReport.substring(260, 60);
        enclaveReport.reportData = rawEnclaveReport.substring(320, 64);
        success = true;
    }

    function setEnclaveHash(bytes calldata enclaveHash, bool valid) external onlyOwner {
        if (valid) {
            registredEnclaveHash[keccak256(enclaveHash)] = true;
        } else {
            delete registredEnclaveHash[keccak256(enclaveHash)];
        }
    }

    function deleteResgiteredSigner(address signer) external onlyOwner {
        delete registeredSigners[signer];
    }
}

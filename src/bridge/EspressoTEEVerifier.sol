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
/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the V3QuoteVerifier contract
 *         to verify the quote. Along with some additional verification logic.
 */

contract EspressoTEEVerifier is V3QuoteVerifier {
    constructor(address _router) V3QuoteVerifier(_router) {}

    /**
        @notice Verify a quote from the TEE and attest on-chain
        @param rawQuote The quote from the TEE
        @return success True if the quote was verified and attested on-chain
     */
    function verify(bytes calldata rawQuote) external view returns (bool success) {
        // Parse the header
        Header memory header = _parseQuoteHeader(rawQuote);

        if (header.version != 3) {
            return false;
        }

        (success, ) = this.verifyQuote(header, rawQuote);
        if (!success) {
            return false;
        }

        //  Parse enclave quote
        uint256 offset = HEADER_LENGTH + ENCLAVE_REPORT_LENGTH;
        EnclaveReport memory localReport;
        (success, localReport) = parseEnclaveReport(rawQuote[HEADER_LENGTH:offset]);
        if (!success) {
            return false;
        }

        return true;

        // TODO: Use the parsed enclave report (localReport) to do other verifications
    }

    function _parseQuoteHeader(
        bytes calldata rawQuote
    ) private pure returns (Header memory header) {
        bytes2 attestationKeyType = bytes2(rawQuote[2:4]);
        bytes2 qeSvn = bytes2(rawQuote[8:10]);
        bytes2 pceSvn = bytes2(rawQuote[10:12]);
        bytes16 qeVendorId = bytes16(rawQuote[12:28]);

        header = Header({
            version: uint16(BELE.leBytesToBeUint(rawQuote[0:2])),
            attestationKeyType: attestationKeyType,
            teeType: bytes4(uint32(BELE.leBytesToBeUint(rawQuote[4:8]))),
            qeSvn: qeSvn,
            pceSvn: pceSvn,
            qeVendorId: qeVendorId,
            userData: bytes20(rawQuote[28:48])
        });
    }
}

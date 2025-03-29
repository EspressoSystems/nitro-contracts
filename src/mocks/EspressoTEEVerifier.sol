// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the V3QuoteVerifier contract
 *         to verify the quote. Along with some additional verification logic.
 */

contract EspressoTEEVerifierMock {
    constructor() {}

    function verify(
        bytes calldata rawQuote,
        bytes32 reportDataHash
    ) external view returns (bool success) {
        return (true);
    }
}

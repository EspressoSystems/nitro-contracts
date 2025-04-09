// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the V3QuoteVerifier contract
 *         to verify the quote. Along with some additional verification logic.
 */
contract EspressoTEEVerifierMock {
    enum TeeType {
        SGX,
        NITRO
    }

    mapping(address => bool) public registeredSigner;

    constructor() {}

    function verify(bytes calldata signature, bytes32 userDataHash, TeeType teeType)
        external
        view
        returns (bool)
    {
        return true;
    }

    function registerSigner(bytes calldata attestation, bytes calldata data, TeeType teeType)
        external
    {
        // data length should be 20 bytes
        require(data.length == 20, "Invalid data length");

        address signer = address(uint160(bytes20(data[:20])));
        registeredSigner[signer] = true;
    }

    function registeredSigners(address signer, TeeType teeType) external view returns (bool) {
        return registeredSigner[signer];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ServiceType, IEspressoTEEVerifier} from "../bridge/EspressoTEE.sol";

/**
 *
 * @title  Verifies quotes from the TEE and attests on-chain
 * @notice Contains the logic to verify a quote from the TEE and attest on-chain. It uses the V3QuoteVerifier contract
 *         to verify the quote. Along with some additional verification logic.
 */
contract EspressoTEEVerifierMock is IEspressoTEEVerifier {
    mapping(address => bool) public registeredSigner;

    constructor() {}

    function verify(
        bytes calldata signature,
        bytes32 userDataHash,
        IEspressoTEEVerifier.TeeType teeType,
        ServiceType service
    ) external view returns (bool) {
        return true;
    }
}

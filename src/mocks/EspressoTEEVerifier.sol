// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEspressoTEEVerifier} from "espresso-tee-contracts/interface/IEspressoTEEVerifier.sol";
import {IEspressoSGXTEEVerifier} from "espresso-tee-contracts/interface/IEspressoSGXTEEVerifier.sol";
import {IEspressoNitroTEEVerifier} from "espresso-tee-contracts/interface/IEspressoNitroTEEVerifier.sol";
import {ServiceType} from "espresso-tee-contracts/types/Types.sol";

contract EspressoTEEVerifierMock is IEspressoTEEVerifier {
    function espressoSGXTEEVerifier() external pure returns (IEspressoSGXTEEVerifier) {
        return IEspressoSGXTEEVerifier(address(0));
    }

    function espressoNitroTEEVerifier() external pure returns (IEspressoNitroTEEVerifier) {
        return IEspressoNitroTEEVerifier(address(0));
    }

    function verify(
        bytes memory,
        bytes32,
        TeeType,
        ServiceType
    ) external pure returns (bool) {
        return true;
    }

    function registerService(bytes calldata, bytes calldata, TeeType, ServiceType) external {}

    function registeredEnclaveHashes(bytes32, TeeType, ServiceType) external pure returns (bool) {
        return false;
    }

    function isSignerValid(address, TeeType, ServiceType) external pure returns (bool) {
        return true;
    }

    function setEspressoSGXTEEVerifier(IEspressoSGXTEEVerifier) external {}

    function setEspressoNitroTEEVerifier(IEspressoNitroTEEVerifier) external {}

    function setEnclaveHash(bytes32, bool, TeeType, ServiceType) external {}

    function deleteEnclaveHashes(bytes32[] memory, TeeType, ServiceType) external {}

    function setQuoteVerifier(address) external {}

    function setNitroEnclaveVerifier(address) external {}
}

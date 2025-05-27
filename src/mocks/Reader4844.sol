// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {IReader4844} from "../libraries/IReader4844.sol";

contract Reader4844 is IReader4844 {
    uint256 public constant BLOB_BASE_FEE = 100;

    function getBlobBaseFee() external view returns (uint256) {
        return BLOB_BASE_FEE;
    }

    function getDataHashes() external view returns (bytes32[] memory) {
        bytes32[] memory dataHashes = new bytes32[](1); // Fixed size (e.g., 1 element)
        dataHashes[0] = 0x014e8e17947683a76729b8efd62f59785227e0011c4ace32d7887589acd46ee7; // Assign hash
        return dataHashes;
    }
}

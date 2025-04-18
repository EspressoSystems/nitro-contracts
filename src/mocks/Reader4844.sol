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
        dataHashes[0] = 0x0136aa65f599c11c29a2346a9134f6260f447b266f47023d51e35d24981bdc4f; // Assign hash
        return dataHashes;
    }
}

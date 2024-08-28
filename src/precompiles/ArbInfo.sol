// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Lookup for basic info about accounts and contracts.
/// @notice Precompiled contract that exists in every Arbitrum chain at 0x0000000000000000000000000000000000000065.
interface ArbInfo {
    /// @notice Retrieves an account's balance
    function getBalance(address account) external view returns (uint256);

    /// @notice Retrieves a contract's deployed code
    function getCode(address account) external view returns (bytes memory);

    // @notice Retrieves an account's balance values (fixed, shares, debt)
    function getBalanceValues(address account) external view returns (uint256, uint256, uint256);

    // @notice Retrieves an account's yield mode
    function getYieldConfiguration(address account) external view returns (uint8);

    // @notice Retrieves an account's delegate if in delegate yield mode and returns the zero address otherwise.
    function getDelegate(address account) external view returns (address);

    // @notice Set the yield mode for msg.sender to automatic.
    function configureAutomaticYield() external;

    // @notice Set the yield mode for msg.sender to void.
    function configureVoidYield() external;

    // @notice Set the yield mode for msg.sender to delegate to an account. This function silently fails instead of reverting if attempting to delegate to self.
    function configureDelegateYield(address account) external;
}

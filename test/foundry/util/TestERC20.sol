// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Simple ERC20 token for testing purposes.
 * Replaces ERC20PresetFixedSupply which was removed in OZ v5.
 */
contract TestERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}

/**
 * @dev ERC20 token with minting capability for testing purposes.
 * Replaces ERC20PresetMinterPauser which was removed in OZ v5.
 */
contract TestERC20Minter is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

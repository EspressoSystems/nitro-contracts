pragma solidity ^0.8.0;
// Example action contract to upgrade chain config to turn on espresso mode

import "../precompiles/ArbOwner.sol";

contract SetEspressoChainConfig {
    function perform(string calldata serialiazedEspressoConfig) public {
        //The ArbOwner precomiple always lives at this addr.
        ArbOwner arbOwner = ArbOwner(0x0000000000000000000000000000000000000070);
        //This call must come from an account designated as an Owner by the ArbOwner contract.
        //In practice the Owner should be the UpgradeExecutor via the execute method. 
        arbOwner.setChainConfig(serialiazedEspressoConfig);
    }
}
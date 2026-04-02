pragma solidity ^0.8.0;
// Example action contract to upgrade chain config to turn on espresso mode

import "../precompiles/ArbOwner.sol";

contract ScheduleEspressoUpgrade {
    function perform(uint64 timestamp) public {
        //The ArbOwner precompile always lives at this address.
        ArbOwner arbOwner = ArbOwner(0x0000000000000000000000000000000000000070);
        //This call must come from an address designated as an Owner by the ArbOwner contract. 
        arbOwner.scheduleArbOSUpgrade(35, timestamp);
    }
}
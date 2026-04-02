pragma solidity ^0.8.9;

import "../challenge/IChallengeManager.sol";
import "../rollup/IRollupAdmin.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract EspressoMigration{ 
    function perform(
        address rollup,
        address proxyAdmin,
        bytes32 newWasmModuleRoot,
        bytes32 currentWasmModuleRoot,
        address newOspEntry,
        address currentOspEntry
    ) public{
        //Handle assertions in the perform functoin as we shouldn't be storing local state for delegated calls.
        require(newWasmModuleRoot != bytes32(0), "_newWasmModuleRoot cannot be empty");

        require(currentWasmModuleRoot != bytes32(0), "_currentWasmModuleRoot cannot be empty");

        require(Address.isContract(newOspEntry), "_newOsp must be a contract");

        require(Address.isContract(currentOspEntry), "_currentOsp must be a contract");

        // set the new challenge manager impl
        TransparentUpgradeableProxy challengeManager =
            TransparentUpgradeableProxy(payable(address(IRollupCore(rollup).challengeManager())));
        address chalManImpl = ProxyAdmin(proxyAdmin).getProxyImplementation(challengeManager);
        ProxyAdmin(proxyAdmin).upgradeAndCall(
            challengeManager,
            chalManImpl, // Use the rollups current challenge manager as we only need to upgrade the OSP
            abi.encodeWithSelector(IChallengeManager.postUpgradeInit.selector, IOneStepProofEntry(newOspEntry), currentWasmModuleRoot, IOneStepProofEntry(currentOspEntry))
        );

        require(IChallengeManager(address(challengeManager)).osp() == IOneStepProofEntry(newOspEntry), "new OSP not set");
        
        IRollupAdmin(rollup).setWasmModuleRoot(newWasmModuleRoot);

        require(IRollupCore(rollup).wasmModuleRoot() == newWasmModuleRoot, "newWasmModuleRoot not set");
    }
}
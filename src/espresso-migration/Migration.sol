pragma solidity 0.8.16;

import "../challenge/IChallengeManager.sol";
import "../rollup/IRollupAdmin.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Migration{
    address public immutable newOspEntry;
    bytes32 public immutable newWasmModuleRoot;
    address public immutable currentOspEntry;
    bytes32 public immutable currentWasmModuleRoot;

    constructor(
        bytes32 _newWasmModuleRoot,
        bytes32 _currentWasmModuleRoot,
        address _newOspEntry,
        address _currentOspEntry    
        ){
        require(_newWasmModuleRoot != bytes32(0), "_newWasmModuleRoot cannot be empty")
        newWasmModuleRoot = _newWasmModuleRoot;

        require(currentWasmModuleRoot != bytes32(0), "_currentWasmModuleRoot cannot be empty")
        currentWasmModuleRoot = _currentWasmModuleRoot;

        require(Address.isContract(_newOsp), "_newOsp must be a contract")
        newOspEntry = _newOspEntry;

        require(Address.isContract(_currentOsp), "_currentOsp must be a contract")
        currentOspEntry = _currentOspEntry;

    }

    function perform(IRollupCore rollup, address proxyAdmin) public{
    
        // set the new challenge manager impl
        TransparentUpgradeableProxy challengeManager =
            TransparentUpgradeableProxy(payable(address(rollup.challengeManager())));
        proxyAdmin.upgradeAndCall(
            challengeManager,
            address(rollup.challengeManager()), // Use the rollups current challenge manager as we only need to upgrade the OSP
            abi.encodeCall(IChallengeManagerUpgradeInit.postUpgradeInit, (newOsp))
        );
        require(
            proxyAdmin.getProxyImplementation(challengeManager) == newChallengeManagerImpl,
            "new challenge manager implementation not set"
        );
        require(IChallengeManagerUpgradeInit(address(challengeManager)).osp() == newOsp, "new OSP not set");
    }
}
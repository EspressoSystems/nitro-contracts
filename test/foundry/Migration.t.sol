pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./util/TestUtil.sol";
import "../../src/challenge/IChallengeManager.sol";
import "../../src/osp/OneStepProver0.sol";
import "../../src/osp/OneStepProverMemory.sol";
import "../../src/osp/OneStepProverMath.sol";
import "../../src/osp/OneStepProverHostIo.sol";
import "../../src/osp/OneStepProofEntry.sol";
import "../../src/mocks/UpgradeExecutorMock.sol";
import "../../src/rollup/RollupCore.sol";
import "../../src/rollup/RollupCreator.sol";
import "../../test/foundry/RollupCreator.t.sol";
import "../../src/espresso-migration/Migration.sol";

contract MigrationTest is Test{

    IOneStepProofEntry originalOspEntry;
    IOneStepProofEntry newOspEntry = IOneStepProofEntry(
        new OneStepProofEntry(
            new OneStepProver0(),
            new OneStepProverMemory(),
            new OneStepProverMath(),
            new OneStepProverHostIo(address(hotshot))
        )
    );  

    RollupCreator public rollupCreator;
    address public rollupAddress;
    address public rollupOwner = makeAddr("rollupOwner");
    address public deployer = makeAddr("deployer");
    IRollupAdmin public rollupAdmin;
    IRollupUser public rollupUser;
    DeployHelper public deployHelper;   
    IReader4844 dummyReader4844 = IReader4844(address(137));
    MockHotShot public hotshot = new MockHotShot();
    IUpgradeExecutor upgradeExecutor;

    // 1 gwei
    uint256 public constant MAX_FEE_PER_GAS = 1_000_000_000;
    uint256 public constant MAX_DATA_SIZE = 117_964;

    BridgeCreator.BridgeContracts public ethBasedTemplates =
        BridgeCreator.BridgeContracts({
            bridge: new Bridge(),
            sequencerInbox: new SequencerInbox(MAX_DATA_SIZE, dummyReader4844, false),
            inbox: new Inbox(MAX_DATA_SIZE),
            rollupEventInbox: new RollupEventInbox(),
            outbox: new Outbox()
        });
    BridgeCreator.BridgeContracts public erc20BasedTemplates =
        BridgeCreator.BridgeContracts({
            bridge: new ERC20Bridge(),
            sequencerInbox: new SequencerInbox(MAX_DATA_SIZE, dummyReader4844, true),
            inbox: new ERC20Inbox(MAX_DATA_SIZE),
            rollupEventInbox: new ERC20RollupEventInbox(),
            outbox: new ERC20Outbox()
        });


    /* solhint-disable func-name-mixedcase */
    //create items needed for a rollup and deploy it. This code is lovingly borrowed from the rollupcreator.t.sol foundry test.
    function setUp() public {
        //// deploy rollup creator and set templates
        vm.startPrank(deployer);
        rollupCreator = new RollupCreator();
        deployHelper = new DeployHelper();

        for (uint256 i = 1; i < 10; i++) {
            hotshot.setCommitment(uint256(i), uint256(i));
        }

        // deploy BridgeCreators
        BridgeCreator bridgeCreator = new BridgeCreator(ethBasedTemplates, erc20BasedTemplates);

        IUpgradeExecutor upgradeExecutorLogic = new UpgradeExecutorMock();
        upgradeExecutor = upgradeExecutorLogic;

        (
            IOneStepProofEntry ospEntry,
            IChallengeManager challengeManager,
            IRollupAdmin _rollupAdmin,
            IRollupUser _rollupUser
        ) = _prepareRollupDeployment();

        originalOspEntry = ospEntry;

        rollupAdmin = _rollupAdmin;
        rollupUser = _rollupUser;

        //// deploy creator and set logic
        rollupCreator.setTemplates(
            bridgeCreator,
            ospEntry,
            challengeManager,
            _rollupAdmin,
            _rollupUser,
            upgradeExecutorLogic,
            address(new ValidatorUtils()),
            address(new ValidatorWalletCreator()),
            deployHelper
        );

                // deployment params
        ISequencerInbox.MaxTimeVariation memory timeVars = ISequencerInbox.MaxTimeVariation(
            ((60 * 60 * 24) / 15),
            12,
            60 * 60 * 24,
            60 * 60
        );
        Config memory config = Config({
            confirmPeriodBlocks: 20,
            extraChallengeTimeBlocks: 200,
            stakeToken: address(0),
            baseStake: 1000,
            wasmModuleRoot: keccak256("wasm"),
            owner: rollupOwner,
            loserStakeEscrow: address(200),
            chainId: 1337,
            chainConfig: "abc",
            genesisBlockNum: 15_000_000,
            sequencerInboxMaxTimeVariation: timeVars
        });

        // prepare funds
        uint256 factoryDeploymentFunds = 1 ether;
        vm.deal(deployer, factoryDeploymentFunds);
        uint256 balanceBefore = deployer.balance;

        /// deploy rollup
        address[] memory batchPosters = new address[](1);
        batchPosters[0] = makeAddr("batch poster 1");
        address batchPosterManager = makeAddr("batch poster manager");
        address[] memory validators = new address[](2);
        validators[0] = makeAddr("validator1");
        validators[1] = makeAddr("validator2");

        RollupCreator.RollupDeploymentParams memory deployParams = RollupCreator
            .RollupDeploymentParams({
                config: config,
                batchPosters: batchPosters,
                validators: validators,
                maxDataSize: MAX_DATA_SIZE,
                nativeToken: address(0),
                deployFactoriesToL2: true,
                maxFeePerGasForRetryables: MAX_FEE_PER_GAS,
                batchPosterManager: batchPosterManager
            });
        rollupAddress = rollupCreator.createRollup{value: factoryDeploymentFunds}(
            deployParams
        );

        vm.stopPrank();
    }

    function _prepareRollupDeployment()
        internal
        returns (
            IOneStepProofEntry ospEntry,
            IChallengeManager challengeManager,
            IRollupAdmin rollupAdminLogic,
            IRollupUser rollupUserLogic
        )
    {
        //// deploy challenge stuff
        ospEntry = new OneStepProofEntry(
            new OneStepProver0(),
            new OneStepProverMemory(),
            new OneStepProverMath(),
            new OneStepProverHostIo(address(hotshot))
        );
        challengeManager = new ChallengeManager();

        //// deploy rollup logic
        rollupAdminLogic = IRollupAdmin(new RollupAdminLogic());
        rollupUserLogic = IRollupUser(new RollupUserLogic());

        return (ospEntry, challengeManager, rollupAdminLogic, rollupUserLogic);
    }

    function _getProxyAdmin(address proxy) internal view returns (address) {
        bytes32 adminSlot = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
        return address(uint160(uint256(vm.load(proxy, adminSlot))));
    }

    function test_migrateToEspresso() public{
        IRollupCore rollup = IRollupCore(rollupAddress);
        address migration = address(new Migration());
        address upgradeExecutorExpectedAddress = computeCreateAddress(address(rollupCreator), 4);
        assertEq(
            ProxyAdmin(_getProxyAdmin(address(rollup.sequencerInbox()))).owner(),
            upgradeExecutorExpectedAddress,
            "Invalid proxyAdmin's owner"
        );
        IUpgradeExecutor _upgradeExecutor = IUpgradeExecutor(
            upgradeExecutorExpectedAddress
        );

    
        bytes memory data = abi.encodeWithSelector(
            Migration.perform.selector,
            rollup,
            computeCreateAddress(address(rollupCreator), 1), // the address that the rollup creator would deploy based on the nonce. For the arbitrum rollup creator this will be the first deployment.
            bytes32(uint256(keccak256("newRoot"))), // create a new dummy root.
            bytes32(uint256(keccak256("wasm"))), // current wasm module root as defined in the config
            newOspEntry,
            originalOspEntry
        );

        vm.prank(rollupOwner);
        _upgradeExecutor.execute(migration, data);
        vm.stopPrank();
        assertEq(address(rollup.challengeManager().getOsp(bytes32(uint256(keccak256("wasm"))))), address(originalOspEntry), "CondOsp at original root is not what was expected.");
        assertEq(address(rollup.challengeManager().getOsp(bytes32(uint256(keccak256("newRoot"))))), address(newOspEntry), "CondOsp at new root is not what was expected.");
    }

}
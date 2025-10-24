import '@nomicfoundation/hardhat-chai-matchers'
import 'hardhat-deploy'
import '@nomiclabs/hardhat-ethers'
import '@nomicfoundation/hardhat-verify'
import '@typechain/hardhat'
import 'solidity-coverage'
import 'hardhat-gas-reporter'
import 'hardhat-contract-sizer'
import 'hardhat-ignore-warnings'
import dotenv from 'dotenv'
import '@nomicfoundation/hardhat-foundry'
dotenv.config()

const solidity = {
  compilers: [
    {
      version: '0.8.17',
      settings: {
        optimizer: {
          enabled: true,
          runs: 2000,
        },
        viaIR: false,
      },
    },
  ],
  overrides: {
    'src/rollup/RollupUserLogic.sol': {
      version: '0.8.20',
      settings: {
        optimizer: {
          enabled: true,
          runs: 20,
        },
      },
    },
    'src/challengeV2/EdgeChallengeManager.sol': {
      version: '0.8.17',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
    'src/mocks/HostioTest.sol': {
      version: '0.8.24',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
        evmVersion: 'cancun',
      },
    },
    'src/mocks/ArbOS11To32UpgradeTest.sol': {
      version: '0.8.24',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
        evmVersion: 'cancun',
      },
    },
  },
}

if (process.env['INTERFACE_TESTER_SOLC_VERSION']) {
  solidity.compilers.push({
    version: process.env['INTERFACE_TESTER_SOLC_VERSION'],
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
      viaIR: true,
    },
  })
  solidity.overrides = {
    ...(solidity.overrides || {}),
    ...{
      'src/test-helpers/InterfaceCompatibilityTester.sol': {
        version: process.env['INTERFACE_TESTER_SOLC_VERSION'],
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
    },
    'src/mocks/HostioTest.sol': {
      version: '0.8.24',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
        evmVersion: 'cancun',
      },
    },
    'src/mocks/ArbOS11To32UpgradeTest.sol': {
      version: '0.8.24',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
        evmVersion: 'cancun',
      },
    },
  }
}

const getAccounts = (envKey) => process.env[envKey] ? [process.env[envKey]] : [];

const infuraUrl = (network) => `https://${network}.infura.io/v3/${process.env['INFURA_KEY']}`;

const devNetworks = {
  sepolia: infuraUrl('sepolia'),
  holesky: infuraUrl('holesky'),
  arbRinkeby: 'https://rinkeby.arbitrum.io/rpc',
  arbGoerliRollup: 'https://goerli-rollup.arbitrum.io/rpc',
  arbSepolia: 'https://sepolia-rollup.arbitrum.io/rpc',
  baseSepolia: 'https://sepolia.base.org',
};

const mainNetworks = {
  mainnet: infuraUrl('mainnet'),
  arb1: 'https://arb1.arbitrum.io/rpc',
  nova: 'https://nova.arbitrum.io/rpc',
  base: 'https://mainnet.base.org',
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity,
  paths: {
    sources: './src',
    artifacts: 'build/contracts',
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  networks: {
    hardhat: {
      chainId: 1338,
      throwOnTransactionFailures: true,
      allowUnlimitedContractSize: true,
      accounts: {
        accountsBalance: '1000000000000000000000000000',
      },
      blockGasLimit: 200000000,
      // mining: {
      // auto: false,
      // interval: 1000,
      // },
      forking: {
        url: 'https://mainnet.infura.io/v3/' + process.env['INFURA_KEY'],
        enabled: process.env['SHOULD_FORK'] === '1',
      },
    },
    ...Object.fromEntries(Object.entries(devNetworks).map(([name, url]) => [name, { url, accounts: getAccounts('DEVNET_PRIVKEY') }])),
    ...Object.fromEntries(Object.entries(mainNetworks).map(([name, url]) => [name, { url, accounts: getAccounts('MAINNET_PRIVKEY') }])),
    custom: {
      url: process.env['CUSTOM_RPC_URL'] || 'N/A',
    },
    geth: {
      url: 'http://localhost:8545',
    },
  },
  etherscan: {
    apiKey: process.env['ETHERSCAN_API_KEY'],
    customChains: [
      {
        network: 'nova',
        chainId: 42170,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=42170',
          browserURL: 'https://nova.arbiscan.io/',
        },
      },
      {
        network: 'arbSepolia',
        chainId: 421614,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=421614',
          browserURL: 'https://sepolia.arbiscan.io/',
        },
      },
      {
        network: 'custom',
        chainId: process.env['CUSTOM_CHAINID'],
        urls: {
          apiURL: process.env['CUSTOM_CHAINID'] ? `https://api.etherscan.io/v2/api?chainid=${process.env['CUSTOM_CHAINID']}` : 'https://api.etherscan.io/v2/api',
          browserURL: process.env['CUSTOM_ETHERSCAN_BROWSER_URL'],
        },
      },
    ],
  },
  mocha: {
    timeout: 0,
  },
  gasReporter: {
    enabled: process.env.DISABLE_GAS_REPORTER ? false : true,
  },
  typechain: {
    outDir: 'build/types',
    target: 'ethers-v5',
  },
  contractSizer: {
    strict: true,
  },
  sourcify: {
    enabled: true,
  },
}

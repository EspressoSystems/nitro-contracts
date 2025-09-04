import '@nomiclabs/hardhat-waffle'
import 'hardhat-deploy'
import '@nomiclabs/hardhat-ethers'
import '@nomicfoundation/hardhat-verify'
import '@typechain/hardhat'
import 'solidity-coverage'
import 'hardhat-gas-reporter'
import 'hardhat-contract-sizer'
import 'hardhat-ignore-warnings'
import '@nomicfoundation/hardhat-foundry'
// import '@tovarishfin/hardhat-yul';
import dotenv from 'dotenv'

dotenv.config()

const solidity = {
  compilers: [
    {
      version: '0.8.25',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
        viaIR: true,
      },
    },
  ],
  overrides: {
    'src/rollup/RollupUserLogic.sol': {
      version: '0.8.20',
      settings: {
        optimizer: {
          enabled: true,
          runs: 0,
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
    },
  })
  solidity.overrides = {
    'src/test-helpers/InterfaceCompatibilityTester.sol': {
      version: process.env['INTERFACE_TESTER_SOLC_VERSION'],
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
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
  }
}

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
      //   auto: false,
      //   interval: 1000,
      // },
      forking: {
        url: 'https://mainnet.infura.io/v3/' + process.env['INFURA_KEY'],
        enabled: process.env['SHOULD_FORK'] === '1',
      },
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/' + process.env['INFURA_KEY'],
      accounts: process.env['MAINNET_PRIVKEY']
        ? [process.env['MAINNET_PRIVKEY']]
        : [],
    },
    goerli: {
      url: 'https://goerli.infura.io/v3/' + process.env['INFURA_KEY'],
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    sepolia: {
      url: 'https://sepolia.infura.io/v3/' + process.env['INFURA_KEY'],
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    holesky: {
      url: 'https://holesky.infura.io/v3/' + process.env['INFURA_KEY'],
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    arbRinkeby: {
      url: 'https://rinkeby.arbitrum.io/rpc',
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    arbGoerliRollup: {
      url: 'https://goerli-rollup.arbitrum.io/rpc',
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    arbSepolia: {
      url: 'https://sepolia-rollup.arbitrum.io/rpc',
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    arb1: {
      url: 'https://arb1.arbitrum.io/rpc',
      accounts: process.env['MAINNET_PRIVKEY']
        ? [process.env['MAINNET_PRIVKEY']]
        : [],
    },
    nova: {
      url: 'https://nova.arbitrum.io/rpc',
      accounts: process.env['MAINNET_PRIVKEY']
        ? [process.env['MAINNET_PRIVKEY']]
        : [],
    },
    base: {
      url: 'https://mainnet.base.org',
      accounts: process.env['MAINNET_PRIVKEY']
        ? [process.env['MAINNET_PRIVKEY']]
        : [],
    },
    baseSepolia: {
      url: 'https://sepolia.base.org',
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    geth: {
      url: 'http://localhost:8545',
    },
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY,
      goerli: process.env.ETHERSCAN_API_KEY,
      sepolia: process.env.ETHERSCAN_API_KEY,
      holesky: process.env.ETHERSCAN_API_KEY,
      arbitrumOne: process.env.ETHERSCAN_API_KEY,
      arbitrumTestnet: process.env.ETHERSCAN_API_KEY,
      nova: process.env.ETHERSCAN_API_KEY,
      arbGoerliRollup: process.env.ETHERSCAN_API_KEY,
      arbSepolia: process.env.ETHERSCAN_API_KEY,
      base: process.env.ETHERSCAN_API_KEY,
      baseSepolia: process.env.ETHERSCAN_API_KEY,
    },
    customChains: [
      {
        network: 'mainnet',
        chainId: 1,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=1',
          browserURL: 'https://etherscan.io',
        },
      },
      {
        network: 'goerli',
        chainId: 5,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=5',
          browserURL: 'https://goerli.etherscan.io',
        },
      },
      {
        network: 'sepolia',
        chainId: 11155111,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=11155111',
          browserURL: 'https://sepolia.etherscan.io',
        },
      },
      {
        network: 'holesky',
        chainId: 17000,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=17000',
          browserURL: 'https://holesky.etherscan.io',
        },
      },
      {
        network: 'arbitrumOne',
        chainId: 42161,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=42161',
          browserURL: 'https://arbiscan.io',
        },
      },
      {
        network: 'arbitrumTestnet',
        chainId: 421613,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=421613',
          browserURL: 'https://goerli.arbiscan.io',
        },
      },
      {
        network: 'nova',
        chainId: 42170,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=42170',
          browserURL: 'https://nova.arbiscan.io/',
        },
      },
      {
        network: 'arbGoerliRollup',
        chainId: 421613,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=421613',
          browserURL: 'https://goerli.arbiscan.io/',
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
        network: 'base',
        chainId: 8453,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=8453',
          browserURL: 'https://basescan.org',
        },
      },
      {
        network: 'baseSepolia',
        chainId: 84532,
        urls: {
          apiURL: 'https://api.etherscan.io/v2/api?chainid=84532',
          browserURL: 'https://sepolia.basescan.org/',
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
}

# Arbitrum Nitro Rollup Contracts

This is the package with the smart contract code that powers Arbitrum Nitro and Espresso integration.
It includes the rollup and fraud proof smart contracts, as well as interfaces for interacting with precompiles.

## Deploy contracts to Sepolia

### 1. Compile contracts

Compile these contracts locally by running

```bash
git clone https://github.com/offchainlabs/nitro-contracts
cd nitro-contracts
yarn install
yarn build
yarn build:forge
```

### 2. Setup environment variables and config files

Copy `.env.sample.goerli` to `.env` and fill in the values. Add an [Etherscan api key](https://docs.etherscan.io/getting-started/viewing-api-usage-statistics), [Infura api key](https://docs.infura.io/dashboard/create-api) and a private key which has some funds on sepolia. This private key will be used to deploy the rollup. We have already deployed a `ROLLUP_CREATOR_ADDRESS` which has all the associated espresso contracts initialized on `0x93c735d1D36b4fDfcD1aebe7B54c7fd0DE553898`. If you want to deploy your own rollup creator, you can leave the `ROLLUP_CREATOR_ADDRESS` empty and follow the steps on step 3. If you want to use the already deployed `RollupCreator`, you can update the `ROLLUP_CREATOR_ADDRESS` with the address of the already deployed rollup creator (0x93c735d1D36b4fDfcD1aebe7B54c7fd0DE553898) and follow the steps on step 4 to create the rollup.

### 3. Deploy Rollup Creator and initialize the espresso contracts

Change the `config.ts.example` to `config.ts` and run the following command to deploy the rollup creator and initialize the espresso contracts.

`npx hardhat run scripts/deployment.ts --network sepolia`

This will deploy the rollup creator and initialize the espresso contracts.

### 4. Create the rollup

Change the `config.ts.example` to `config.ts` and run the following command to create the rollup if you haven't already done so.

`npx hardhat run scripts/createEthRollup.ts --network sepolia`

This will create the rollup.

## Contract addresses on Sepolia with Espresso integration

| Contract                                   | Address                                    |
| ------------------------------------------ | ------------------------------------------ |
| Bridge                                     | 0xDf8D8f6be21Eda8c64c91aB5025b84B31B080110 |
| SequencerInbox ( with ETH As Fee Token )   | 0xBf79789F11972d928013dCD0882C1C62bbb0aED0 |
| SequencerInbox ( with ERC20 As Fee Token ) | 0x173500d112890FC7154742f9B4A1FC6E7f7C6f7b |
| Inbox                                      | 0x6B676781375f9e857F1ee8729CfEE80B4775C62b |
| RollupEventInbox                           | 0xA1A00d2E9C2297c085A30294b59f751906764C0e |
| Outbox                                     | 0x7069c6D1df347b66c4f6814E20A8bcD9A527e90C |
| ERC20Bridge                                | 0x7aD4cF0bce329B7486640f299eaB8128c73Bf32b |
| ERC20Inbox                                 | 0xecdB9fFCFD69E1dB46F4Ba967a91b4aC9b6c90e7 |
| ERC20RollupEventInbox                      | 0xA99FD38FC1C303FC239Aae14fC11d6425396dD96 |
| ERC20Outbox                                | 0x3bb2c779AeDF0AC7C96449205cdaD97D89981B1d |
| BridgeCreator                              | 0x977523CDBd21CA804bAE1BA6FAC62d7dd9f8ee41 |
| OneStepProver0                             | 0x2925Cc6811A73E7887126a17caaEcE17f6392a31 |
| OneStepProverMemory                        | 0xD133aFE9a327e9945FA92Fec31A42A20A27c5Aac |
| OneStepProverMath                          | 0xd8a98a887906C29404D06Bedf15C9e4Ec2083aA9 |
| OneStepProverHostIo                        | 0xa00b23d0E31CFf1Baeb7aB262c232c99AD6a34Af |
| OneStepProofEntry                          | 0xB7289B5F2E4a72020C0d69A065f9c14373eb6932 |
| ChallengeManager                           | 0x1d8a4A99eac0392176395a602CEA6BA1111773Ff |
| RollupAdminLogic                           | 0x768DFd911967D8377aa1D5EBeD44D773e4157D56 |
| RollupUserLogic                            | 0x019c46d437810Df680E8042093fae503FEA13983 |
| ValidatorUtils                             | 0x6A71F50fb675115e2311283145F0d0304646D346 |
| ValidatorWalletCreator                     | 0xf06a0bb1ce389980D3Cf43a94de9c7c60a9beC93 |
| RollupCreator                              | 0x93c735d1D36b4fDfcD1aebe7B54c7fd0DE553898 |
| DeployHelper                               | 0x64Ff95c6F17FdFF32C7E634D45F5143Ee372f887 |

## License

Nitro is currently licensed under a [Business Source License](./LICENSE.md), similar to our friends at Uniswap and Aave, with an "Additional Use Grant" to ensure that everyone can have full comfort using and running nodes on all public Arbitrum chains.

The Additional Use Grant also permits the deployment of the Nitro software, in a permissionless fashion and without cost, as a new blockchain provided that the chain settles to either Arbitrum One or Arbitrum Nova.

For those that prefer to deploy the Nitro software either directly on Ethereum (i.e. an L2) or have it settle to another Layer-2 on top of Ethereum, the [Arbitrum Expansion Program (the "AEP")](https://docs.arbitrum.foundation/assets/files/Arbitrum%20Expansion%20Program%20Jan182024-4f08b0c2cb476a55dc153380fa3e64b0.pdf) was recently established. The AEP allows for the permissionless deployment in the aforementioned fashion provided that 10% of net revenue is contributed back to the Arbitrum community in accordance with the requirements of the AEP.

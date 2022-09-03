import * as dotenv from "dotenv"

import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import "solidity-coverage";

// TASKS
// import "./tasks/00_sendCrossChainMessage"

// Files import

import networkJson from "./constants/networks.json"

dotenv.config();

// keys 
const PKEY_1 : string = process.env.PKEY_1!;
const PKEY_2 : string = process.env.PKEY_2!;
const ALCHEMY_API_KEY : string = process.env.ALCHEMY_API_KEY!

const accounts: Array<string> = [PKEY_1, PKEY_2]

const ETH_RINKEBY_URL : string = networkJson["4"].arpc_url
const ARB_RINKEBY_URL : string = networkJson["421611"].arpc_url
const FTM_TESTNET_URL : string = networkJson["4002"].rpc_url
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
      },
      {
        version: "0.8.4",
      },
      {
        version: "0.8.1",
      },
      {
        version: "0.7.6",
      },
    ],
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    localhost: {
      chainId: 31337,
      accounts: !accounts.length ? [] : accounts
    },
    ethRinkeby: {
      chainId: 4,
      accounts: !accounts.length ? [] : accounts,
      url: !ETH_RINKEBY_URL ? networkJson["4"].rpc_url : ETH_RINKEBY_URL + ALCHEMY_API_KEY,
      gas: 10000000,
      // gasPrice: 1900000000
    },
    arbRinkeby: {
      chainId: 421611,
      accounts: !accounts.length ? [] : accounts,
      url: !ARB_RINKEBY_URL ? networkJson["421611"].rpc_url : ARB_RINKEBY_URL + ALCHEMY_API_KEY,
      gas: 6000000,
      gasPrice: 100000000,
    }, 
    ftmTestnet: {
      chainId: 4002,
      accounts: !accounts.length ? [] : accounts,
      url: FTM_TESTNET_URL
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY ,
  },
  mocha: {
    timeout: 200000, // 200 seconds max for running tests
  },
  namedAccounts: {
    deployer: {
      default: 0,
      1: 0,
    },
    secondary: {
      default: 2,
    },
  },
};

export default config;

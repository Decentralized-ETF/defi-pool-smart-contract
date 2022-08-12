import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999,
          },
          evmVersion: "istanbul",
        },
      },
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999,
          },
          evmVersion: "istanbul",
        },
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999,
          },
          evmVersion: "istanbul",
        },
      },
    ],
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true
    },
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com/",
      // network_id: 80001,
      // confirmations: 2,
      // timeoutBlocks: 200,
      // networkCheckTimeout: 50000000,
      accounts: [
        "0x39f58ea07aee685a18106d58fd2883b590573866fdef027b07ef9014cb3ef520",
      ],
      // skipDryRun: true,
      gas: 6000000,
      gasPrice: 18000000000,
    },
    polygon: {
      url: "https://polygon-rpc.com/",
      // network_id: 80001,
      // confirmations: 2,
      // timeoutBlocks: 200,
      // networkCheckTimeout: 50000000,
      accounts: [
        "320ab691eb1cd32e832d1d56702e7ed69bf6f8ffc398bcf71daebad39c9280a9",
      ],
      // skipDryRun: true,
      gas: 6000000,
      gasPrice: 60000000000,
    },
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;

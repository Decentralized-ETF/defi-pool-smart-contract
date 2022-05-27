import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
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
    mainnet: {
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

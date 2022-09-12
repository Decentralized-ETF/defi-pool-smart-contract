import * as dotenv from 'dotenv'

import { HardhatUserConfig, task } from 'hardhat/config'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import "@nomiclabs/hardhat-etherscan";
import 'hardhat-contract-sizer'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'
import 'solidity-coverage'
import '@nomiclabs/hardhat-ethers'
import '@openzeppelin/hardhat-upgrades'

dotenv.config()

const { pk } = require('./secrets.json')

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners()

    for (const account of accounts) {
        console.log(account.address)
    }
})

const ETHERSCAN_KEY = process.env.ETHERSCAN_KEY
const BSCSCAN_KEY = process.env.BSCSCAN_KEY
const OPTIMISTICSCAN_KEY = process.env.OPTIMISTICSCAN_KEY
const HECOSCAN_KEY = process.env.HECOSCAN_KEY
const FTMSCAN_KEY = process.env.FTMSCAN_KEY
const ARBISCAN_KEY = process.env.ARBISCAN_KEY
const POLYGONSCAN_KEY = process.env.POLYGONSCAN_KEY
const AVALANCHE_KEY = process.env.AVALANCHE_KEY

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: '0.8.15',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: '0.5.16',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: '0.6.6',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            }
        ],
    },
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
        },
        mumbai: {
            url: 'https://rpc-mumbai.maticvigil.com/',
            // network_id: 80001,
            // confirmations: 2,
            // timeoutBlocks: 200,
            // networkCheckTimeout: 50000000,
            accounts: [pk],
            // skipDryRun: true,
            gas: 6000000,
            gasPrice: 18000000000,
        },
        polygon: {
            url: 'https://polygon-rpc.com/',
            // network_id: 80001,
            // confirmations: 2,
            // timeoutBlocks: 200,
            // networkCheckTimeout: 50000000,
            accounts: [pk],
            // skipDryRun: true,
            gas: 6000000,
            gasPrice: 60000000000,
        },
        ropsten: {
            url: process.env.ROPSTEN_URL || '',
            accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
        },
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: 'USD',
    },
    etherscan: {
        apiKey: POLYGONSCAN_KEY
    },
}

export default config

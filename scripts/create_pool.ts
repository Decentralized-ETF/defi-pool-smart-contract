import {Deployer} from "./classes/Deployer";
import { loadCore } from "./utils";
import {TOKENS } from './config'
import hre, { ethers } from 'hardhat'
import { Factory } from '../typechain'


async function main() {
    const core = await loadCore();
    const deployer = new Deployer();
    const Factory = await ethers.getContractAt("Factory", core.factory) as Factory
    // await deployer.createPoolWithStorage(Factory, core.swapper, TOKENS)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

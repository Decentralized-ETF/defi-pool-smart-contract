import { loadPools, loadCore } from './utils'
import { Factory } from '../typechain'
import hre from 'hardhat'
import {Deployer} from "./classes/Deployer";

async function debug() {
    const core = await loadCore();
    const [savedPool] = await loadPools()
    const deployer = new Deployer();
    const factory = (await hre.ethers.getContractAt('Factory', core.factory)) as Factory
    await factory.transferOwnership("0x087a8B8377622CCf1D8Ca145d399C9360FF35baF")
}

if (require.main === module) {
    debug()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error)
            process.exit(1)
        })
}

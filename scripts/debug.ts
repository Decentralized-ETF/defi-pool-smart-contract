import { loadPools, loadCore } from './utils'
import { Factory } from '../typechain'
import hre from 'hardhat'
import {Deployer} from "./classes/Deployer";

async function debug() {
    const core = await loadCore()
    const deployer = new Deployer();
    await deployer.verify(core.factory, )
    // const factory = (await hre.ethers.getContractAt('Factory', core.factory)) as Factory
    // const pool = await factory.pools(0)
    // const poolStorage = await factory.poolStorages(0)
    // console.log(pool, 'pool')
    // console.log(poolStorage, 'poolStorage')
}

if (require.main === module) {
    debug()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error)
            process.exit(1)
        })
}
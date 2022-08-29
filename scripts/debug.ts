import { loadPools, loadCore } from './utils'
import { Factory } from '../typechain'
import hre from 'hardhat'
import {Deployer} from "./classes/Deployer";

async function debug() {
    const core = await loadCore();
    const [savedPool] = await loadPools()
    const deployer = new Deployer();
    const factory = (await hre.ethers.getContractAt('Factory', core.factory)) as Factory
    const pool = await factory.pools(0)
    const poolStorage = await factory.poolStorages(0)
    await deployer.verify(pool, 1, core.swapper)
    await deployer.verify(poolStorage, 1, savedPool.entryToken, "0x91A001A46D61E447E2E2b9E38C47d2B2DAD97252", "KEDR_DAI", "kDAI")
}

if (require.main === module) {
    debug()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error)
            process.exit(1)
        })
}

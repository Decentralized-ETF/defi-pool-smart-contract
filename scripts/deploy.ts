import hre, { ethers, upgrades } from 'hardhat'
import {ROUTERS} from "./config";
import {createPool} from "./createPool";


async function main() {
    const [governance] = await ethers.getSigners()
    const network = hre.network.name

    const FactoryFactory = await ethers.getContractFactory('Factory')
    const SwapperFactory = await ethers.getContractFactory('Swapper')

    const routers = ROUTERS.filter(router => router.network === network)

    const routerAddresses = routers.map(val => val.address);
    const routerTypes = routers.map(val => val.type);
    const defaultRouter = routers.find(val => val.isDefault)?.address || routers[0].address
    const Swapper = await SwapperFactory.deploy(routerAddresses, routerTypes, defaultRouter);
    console.log(`Swapper is deployed at: ${Swapper.address}`);

    const Factory = await FactoryFactory.deploy(governance.address, Swapper.address);
    console.log(`Factory is deployed at: ${Factory.address}`);

    await createPool(Factory, Swapper.address); // create default pool
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

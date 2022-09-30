import {cmiPolygonMATIC, cmiPolygonUSDC, cmiPolygonUSDT, etherEssentialsBTC, etherEssentialsETH, etherEssentialsUSDT, initialPools, poolsETH, poolsUSD, topTVLDeFiUSDT, topTVLDeFiWETH} from './config';
import {Deployer} from "./classes/Deployer";
import { ethers } from 'hardhat'
import { Pool } from '../typechain';
import { PoolConfig } from './interfaces';


async function main() {
    const deployer = new Deployer()
    const {Factory, Swapper} = await deployer.deployFactory(true);
    // const {Factory, Swapper} = await fromExistingFactory();
    // const pools = [topTVLDeFiUSDT, topTVLDeFiWETH, cmiPolygonUSDT];
    const pools: PoolConfig[] = poolsUSD;
    for (const pool of pools) {
      console.log('Deploying pool: ', pool.entryAsset.name);
      const deployed = await deployer.createPoolWithStorage(
        Factory, Swapper.address, pool
      );
      // const deployed = await deployer.createPool(
      //   Factory, pool.assets, pool.weights, pool.entryAsset.address
      // );
      console.log('Deployed successfuly!', deployed);
    }
}

async function switchStorageToPools(newPools: Pool[], oldStorages: Storage[]) {
  
}

async function switchPoolsToStorage() {

}

async function fromExistingFactory() {
  const [governance] = await ethers.getSigners()
  const factoryAddr = '0x701257a0c20c75c08ba5a76649f14af63bbdcb58';
  const Factory = await ethers.getContractAt('Factory', factoryAddr, governance);
  const swapper = await Factory.swapper();
  return {Factory, Swapper: {address: swapper}};
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

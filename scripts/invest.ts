import hre, { ethers } from 'hardhat'
import { loadCore, loadPools } from './utils'
import { Pool, Factory, PoolStorage, Swapper, ERC20 } from '../typechain'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber } from 'ethers'
import {Deployer} from "./classes/Deployer"

async function invest() {
    const [user] = await ethers.getSigners()
    const userAddress = user.address
    const pools = await loadPools()
    const core = await loadCore()

    const pool = pools[0]
    console.log(`Investing in first pool ${pool.poolId}`)

    const EntryToken = await ethers.getContractAt('ERC20', pool.entryToken)
    const Swapper = (await ethers.getContractAt('Swapper', core.swapper)) as Swapper
    const Pool = (await ethers.getContractAt('Pool', pool.pool)) as Pool
    const PoolStorage = (await ethers.getContractAt('PoolStorage', pool.poolStorage)) as PoolStorage

    const poolInStorage = await PoolStorage.pool()
    const storageInPool = await Pool.poolStorage()

    if (poolInStorage != Pool.address || storageInPool != PoolStorage.address) {
        throw Error('Pool in not linked')
    }

    const initialTotalValue = await Pool.callStatic.totalValue()
    let entryBalance = await EntryToken.balanceOf(userAddress)
    const entryDecimals = +(await EntryToken.decimals())
    const entrySymbol = await EntryToken.symbol()

    console.log(`Initial value of pool: ${ethers.utils.formatUnits(initialTotalValue, entryDecimals)} ${entrySymbol}`)

    if (entryBalance.eq(BigNumber.from("0"))) {
        console.log("need to buy entryAsset")
        const val = (await ethers.provider.getBalance(userAddress)).div(10);
        await Swapper.swap(ethers.constants.AddressZero, pool.entryToken, val, userAddress, {gasLimit: 2000000, value: val})
        entryBalance = await EntryToken.balanceOf(userAddress);
    }

    console.log(`Investing ${ethers.utils.formatUnits(entryBalance, entryDecimals)} of entryAsset`)

    const defaultRouter = await Swapper.defaultRouter();
    const routerType = await Swapper.routerTypes(defaultRouter);
    console.log(EntryToken.address, "EntryToken");

    console.log(defaultRouter, "defaultRouter");
    console.log(routerType, "routerType")

    const tx = await EntryToken.connect(user).approve(Pool.address, entryBalance, {gasLimit: 2000000})
    await tx.wait(2);
    await sleep(30000)
    await Pool.connect(user).invest(userAddress, entryBalance)

    const lpBalance = await PoolStorage.balanceOf(userAddress)
    console.log("LP Balance: ", ethers.utils.formatUnits(lpBalance, entryDecimals));

    const totalValue = await Pool.callStatic.totalValue();
    console.log(`Total value of pool: ${ethers.utils.formatUnits(totalValue, entryDecimals)} ${entrySymbol}`)
}

function sleep(ms: number) {
    console.log(`Waiting ${ms / 1000} seconds`)
    return new Promise(resolve => setTimeout(resolve, ms));
}

if (require.main === module) {
    invest()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error)
            process.exit(1)
        })
}

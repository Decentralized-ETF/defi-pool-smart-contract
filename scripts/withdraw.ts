import hre, { ethers } from 'hardhat'
import { loadCore, loadPools } from './utils'
import { Pool, Factory, PoolStorage, Swapper, ERC20 } from '../typechain'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber } from 'ethers'
import { Deployer } from './classes/Deployer'
import { sleep } from '../tests/helpers'

async function invest() {
    const [user] = await ethers.getSigners()
    const userAddress = user.address
    const pools = await loadPools()
    const core = await loadCore()

    const pool = pools[0]
    console.log(`Withdrawing from first pool ${pool.poolId}`)

    const EntryToken = await ethers.getContractAt('ERC20', pool.entryAsset)
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
    const kTokensBalance = await PoolStorage.balanceOf(userAddress)

    console.log(`Initial value of pool: ${ethers.utils.formatUnits(initialTotalValue, entryDecimals)} ${entrySymbol}`)
    console.log(`Balance before: ${ethers.utils.formatUnits(entryBalance, entryDecimals)}`)
    console.log("kTokensBalance", +kTokensBalance)

    await EntryToken.connect(user).approve(Pool.address, kTokensBalance, { gasLimit: 2000000 })
    console.log('approve')
    await sleep(30)
    await Pool.connect(user).withdraw(kTokensBalance.div(2))
    await sleep(30)
    console.log('withdraw')

    const kTokensAfter = await PoolStorage.balanceOf(userAddress)
    console.log('kTokens Balance After: ', ethers.utils.formatUnits(kTokensAfter, entryDecimals))

    const totalValue = await Pool.callStatic.totalValue()
    console.log(`Total value of pool: ${ethers.utils.formatUnits(totalValue, entryDecimals)} ${entrySymbol}`)
}

if (require.main === module) {
    invest()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error)
            process.exit(1)
        })
}

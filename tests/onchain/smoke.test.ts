import hre from "hardhat";
import chai from 'chai'
import { solidity } from 'ethereum-waffle'
chai.use(solidity)
const { expect } = chai
const { ethers } = require("hardhat");
import { loadPools, loadCore } from '../../scripts/utils'
import { Pool, Factory, PoolStorage, Swapper, ERC20 } from "../../typechain";
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe('Check Pools On Chain', async () => {

    const pools = await loadPools();
    const core = await loadCore();
    for (const pool of pools) {
        describe(`Checking pool: ${pool.poolId}`, function () {
            let initialTotalValue;
            let Pool: Pool;
            let Swapper: Swapper;
            let PoolStorage: PoolStorage;
            let EntryToken: ERC20;
            let user: SignerWithAddress;
            it("Pool & PoolStorage are deployed and linked", async function () {
                EntryToken = await ethers.getContractAt("ERC20", pool.entryToken);
                Swapper = await ethers.getContractAt("Swapper", core.swapper) as Swapper;
                Pool = await ethers.getContractAt("Pool", pool.pool) as Pool;
                PoolStorage = await ethers.getContractAt("PoolStorage", pool.poolStorage) as PoolStorage;
                const signers = await ethers.getSigners()
                user = signers[0];

                const poolInStorage = await PoolStorage.pool();
                const storageInPool = await Pool.poolStorage();

                expect(poolInStorage).eq(Pool.address)
                expect(storageInPool).eq(PoolStorage.address)
                initialTotalValue = await Pool.callStatic.totalValue();
                console.log(+initialTotalValue, "initialTotalValue");
            })

            // it("Should successfully deposit", async function () {
            //     const entryBalance = await EntryToken.balanceOf(user.address)
            //     if (entryBalance.eq(BigNumber.from("0"))) {
            //         console.log("need to swap")
            //     }
            // })
        })
    }
})

import chai from 'chai'
import { solidity } from 'ethereum-waffle'

chai.use(solidity)
const { ethers } = require("hardhat");
import hre from 'hardhat'
import { Deployer } from '../../scripts/classes/Deployer'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

import {Token} from "../../scripts/interfaces";
import {poolParams} from "../../scripts/config";
import {sign} from "crypto";
import {BigNumber} from "ethers";
import {MockToken, Pool, PoolStorage} from "../../typechain";
const { expect } = chai;


describe('Pool Contract', () => {
    let deployer: Deployer
    let governanceAcc: SignerWithAddress, governance: string, dmitryAcc: SignerWithAddress, dmitry: string
    let contracts: any;
    let poolAddress: string;
    let poolStorageAddress: string;
    let tokens: Token[];
    let poolInfo: string[];
    let pool: Pool;
    let poolStorage: PoolStorage;
    let entryTokenBalanceBeforeInvest: BigNumber;
    let entryAmountToInvest: BigNumber = ethers.utils.parseEther(poolParams.minInvestment)
    let entryAmountToMint: BigNumber = ethers.utils.parseEther((parseInt(poolParams.minInvestment) * 100).toString())
    let tokenA: MockToken, tokenB: MockToken, tokenC: MockToken
    let amountToAddLiquidityUSD: BigNumber = ethers.utils.parseEther(poolParams.minInvestment).mul(10)
    let amountToAddLiquidityBTC: BigNumber = ethers.utils.parseEther(poolParams.minInvestment).mul(10)

    before(async function () {
        this.signers = await ethers.getSigners()
        governanceAcc = this.signers[0]
        dmitryAcc = this.signers[0]
        governance = governanceAcc.address
        dmitry = dmitryAcc.address

        deployer = new Deployer()

        tokenA = (await deployer.deploy('MockToken', ['USDT', 'USDT', 18])) as MockToken
        tokenB = (await deployer.deploy('MockToken', ['USDC', 'USDC', 18])) as MockToken
        tokenC = (await deployer.deploy('MockToken', ['Bitcoin', 'BTC', 18])) as MockToken
        tokens = [
            {name: "USDT", network: hre.network.name, address: tokenA.address},
            {name: "USDC", network: hre.network.name, address: tokenB.address},
            {name: "Bitcoin", network: hre.network.name, address: tokenC.address},
        ]
        contracts = await deployer.deployTestContracts(2)
        // @ts-ignore
        poolInfo = await deployer.createPool(contracts.factory, contracts.swapper.address, tokens, true);
        poolAddress = poolInfo[0]
        poolStorageAddress = poolInfo[1]
        pool = await ethers.getContractAt("Pool", poolAddress);
        poolStorage = await ethers.getContractAt("PoolStorage", poolStorageAddress);
        expect(await contracts.factory.poolsCount()).to.equal(1)

        await tokenA.mint(governance, entryAmountToMint)
        await tokenB.mint(governance, entryAmountToMint)
        await tokenC.mint(governance, entryAmountToMint)

        await tokenA.mint(pool.address, entryAmountToMint)
        await tokenB.mint(pool.address, entryAmountToMint)
        await tokenC.mint(pool.address, entryAmountToMint)
        // mint and approve entry asset to invest
        await tokenA.mint(dmitry, entryAmountToMint)
        entryTokenBalanceBeforeInvest = await tokenA.balanceOf(dmitry)
        await tokenA.connect(dmitryAcc).approve(pool.address, entryAmountToMint)

        // Create pairs and add liquidity on UniswapRouter
        const deadline = (await ethers.provider.getBlock("latest")).timestamp + 1000000
        await tokenA.approve(contracts.router.address, entryAmountToMint)
        await tokenB.approve(contracts.router.address, entryAmountToMint)
        await tokenC.approve(contracts.router.address, entryAmountToMint)

        await contracts.router.addLiquidity(tokenA.address, tokenB.address, amountToAddLiquidityUSD, amountToAddLiquidityBTC, 0, 0, governance, deadline)
        await contracts.router.addLiquidity(tokenA.address, tokenC.address, amountToAddLiquidityUSD, amountToAddLiquidityBTC, 0, 0, governance, deadline)

    })

    describe('Pool', async function () {
        it('Check additional pool creation via factory', async function () {
            await deployer.createPool(contracts.factory, contracts.swapper.address, tokens, true);
            expect(await contracts.factory.poolsCount()).to.equal(2)
        })

        it('Check pool details', async function () {
            const poolDetails = await pool.poolDetails()
            expect(poolDetails[0].toLowerCase()).to.equal(contracts.swapper.address.toLowerCase())
            expect(poolDetails[1].toString()).to.equal(poolParams.minInvestment)
            expect(poolDetails[2]).to.equal(parseInt(poolParams.entryFee))
            expect(poolDetails[3]).to.equal(parseInt(poolParams.successFee))
            expect(await pool.poolStorage()).to.equal(poolStorageAddress)
            //Todo add check weiths sum
        })

        it('Invest', async function () {

            await pool.connect(dmitryAcc).invest(governance, entryAmountToInvest.mul(2))
            expect(await tokenA.balanceOf(dmitry)).to.equal(entryTokenBalanceBeforeInvest.sub(entryAmountToInvest))
            //ToDo check balances of kToken, shares
        })

        it('Second Invest from other account', async function () {

        })
    })
})

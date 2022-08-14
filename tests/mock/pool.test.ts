import chai from 'chai'
import { solidity } from 'ethereum-waffle'

chai.use(solidity)
const { ethers } = require("hardhat");
import hre from 'hardhat'
import { Deployer } from '../../scripts/classes/Deployer'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

import {Token} from "../../scripts/interfaces";
import {poolParams} from "../../scripts/config";
import {BigNumber} from "ethers";
import {MockToken, Pool, PoolStorage} from "../../typechain";
const { expect } = chai;


describe('Pool Contract', () => {
    let deployer: Deployer
    let governanceAcc: SignerWithAddress, governance: string,
        investorAcc: SignerWithAddress, investor: string,
        investor2Acc: SignerWithAddress, investor2: string
    let contracts: any;
    let poolAddress: string;
    let poolStorageAddress: string;
    let tokens: Token[];
    let poolInfo: string[];
    let pool: Pool;
    let poolStorage: PoolStorage;
    let entryAmountToInvest: BigNumber = ethers.utils.parseEther(poolParams.minInvestment)
    let entryAmountToMint: BigNumber = ethers.utils.parseEther((parseInt(poolParams.minInvestment) * 100).toString())
    let tokenA: MockToken, tokenB: MockToken, tokenC: MockToken
    let amountToAddLiquidityUSD: BigNumber = ethers.utils.parseEther(poolParams.minInvestment).mul(10)
    let amountToAddLiquidityBTC: BigNumber = ethers.utils.parseEther(poolParams.minInvestment).mul(10)
    const denominator = 10000 // as in KedrConstants contract
    const fee = entryAmountToInvest.mul(poolParams.entryFee).div(denominator)
    const investedAmount = entryAmountToInvest.sub(entryAmountToInvest.mul(poolParams.entryFee).div(denominator))



    before(async function () {
        this.signers = await ethers.getSigners()
        governanceAcc = this.signers[0]
        investorAcc = this.signers[1]
        investor2Acc = this.signers[2]
        governance = governanceAcc.address
        investor = investorAcc.address
        investor2 = investor2Acc.address

        deployer = new Deployer()

        tokenA = (await deployer.deploy('MockToken', ['USDT', 'USDT', 18])) as MockToken
        tokenB = (await deployer.deploy('MockToken', ['USDC', 'USDC', 18])) as MockToken
        tokenC = (await deployer.deploy('MockToken', ['Bitcoin', 'BTC', 18])) as MockToken
        tokens = [
            {name: "USDC", network: hre.network.name, address: tokenB.address},
            {name: "Bitcoin", network: hre.network.name, address: tokenC.address},
        ]

        await tokenA.mint(governance, entryAmountToMint)
        await tokenA.mint(investor, entryAmountToMint)
        await tokenA.mint(investor2, entryAmountToMint)
    })

    describe('Pool using UniswapV2Router', async function () {

        before(async function () {
            contracts = await deployer.deployTestContracts(2)
            // @ts-ignore
            poolInfo = await deployer.createPool(contracts.factory, contracts.swapper.address, tokens, tokenA.address, true);
            poolAddress = poolInfo[0]
            poolStorageAddress = poolInfo[1]
            pool = await ethers.getContractAt("Pool", poolAddress);
            poolStorage = await ethers.getContractAt("PoolStorage", poolStorageAddress);
            expect(await contracts.factory.poolsCount()).to.equal(1)

            // mint and approve entry asset to invest
            await tokenA.approve(contracts.router.address, ethers.constants.MaxUint256)
            await tokenA.connect(investorAcc).approve(pool.address, ethers.constants.MaxUint256)
            await tokenA.connect(investor2Acc).approve(pool.address, ethers.constants.MaxUint256)

            // Create pairs and add liquidity on UniswapRouter
            await tokenA.mint(governance, entryAmountToMint)
            await tokenB.mint(governance, entryAmountToMint)
            await tokenC.mint(governance, entryAmountToMint)

            await tokenA.approve(contracts.router.address, ethers.constants.MaxUint256)
            await tokenB.approve(contracts.router.address, ethers.constants.MaxUint256)
            await tokenC.approve(contracts.router.address, ethers.constants.MaxUint256)
            const deadline = (await ethers.provider.getBlock("latest")).timestamp + 1000000
            await contracts.router.addLiquidity(tokenA.address, tokenB.address, amountToAddLiquidityUSD, amountToAddLiquidityBTC, 0, 0, governance, deadline)
            await contracts.router.addLiquidity(tokenA.address, tokenC.address, amountToAddLiquidityUSD, amountToAddLiquidityBTC, 0, 0, governance, deadline)

        })

        // it('Check additional pool creation via factory', async function () {
        //     await deployer.createPool(contracts.factory, contracts.swapper.address, tokens, tokenA.address, true);
        //     expect(await contracts.factory.poolsCount()).to.equal(2)
        // })
        //
        // it('Check pool details', async function () {
        //     const poolDetails = await pool.poolDetails()
        //     expect(poolDetails[0].toLowerCase()).to.equal(contracts.swapper.address.toLowerCase())
        //     expect(poolDetails[1].toString()).to.equal(poolParams.minInvestment)
        //     expect(poolDetails[2]).to.equal(parseInt(poolParams.entryFee))
        //     expect(poolDetails[3]).to.equal(parseInt(poolParams.successFee))
        //     expect(await pool.poolStorage()).to.equal(poolStorageAddress)
        // })
        //
        // it('Check default assets weights', async function () {
        //     const defaultWeights = parseInt((100/tokens.length).toFixed(0)) * tokens.length
        //     expect(defaultWeights).to.equal(await pool.weightsSum())
        // })

        describe('Invest & Withdraw', async function () {
            let balanceABefore: BigNumber, balanceABeforeGov: BigNumber, balanceKBefore: BigNumber;
            let balanceAAfter: BigNumber, balanceAAfterGov: BigNumber, balanceKAfter: BigNumber;

            before(async function () {
                balanceABefore = await tokenA.balanceOf(investor)
                balanceABeforeGov = await tokenA.balanceOf(governance)
                balanceKBefore = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).invest(investor, entryAmountToInvest)

                balanceAAfter = await tokenA.balanceOf(investor)
                balanceAAfterGov = await tokenA.balanceOf(governance)
                balanceKAfter = await poolStorage.balanceOf(investor)
            })

            it('First invest.', async function () {
                expect(balanceAAfter).to.equal(balanceABefore.sub(entryAmountToInvest))
                expect(balanceAAfterGov).to.equal(balanceABeforeGov.add(fee))
                expect(balanceKAfter).to.equal(balanceKBefore.add(investedAmount))
                //check poolStorage
                expect(await poolStorage.totalReceivedEntryAsset()).to.equal(investedAmount)
                expect(await poolStorage.totalEntryFeeCollected()).to.equal(fee)
            })

            it('Second Invest from other account', async function () {
                const totalReceivedEntryAssetBefore = await poolStorage.totalReceivedEntryAsset()
                const totalEntryFeeCollectedBefore = await poolStorage.totalEntryFeeCollected()

                balanceABefore = await tokenA.balanceOf(investor2)
                balanceABeforeGov = await tokenA.balanceOf(governance)
                balanceKBefore = await poolStorage.balanceOf(investor2)
                const calculatedKTokens = await poolStorage.callStatic.calculateShares(entryAmountToInvest.sub(fee))

                await pool.connect(investor2Acc).invest(investor2, entryAmountToInvest)
                balanceAAfter = await tokenA.balanceOf(investor2)
                balanceAAfterGov = await tokenA.balanceOf(governance)
                balanceKAfter = await poolStorage.balanceOf(investor2)

                expect(balanceAAfter).to.equal(balanceABefore.sub(entryAmountToInvest))
                expect(balanceAAfterGov).to.equal(balanceABeforeGov.add(fee))
                expect(balanceKAfter).to.equal(calculatedKTokens)

                //check poolStorage
                expect(await poolStorage.totalReceivedEntryAsset()).to.equal(investedAmount.add(totalReceivedEntryAssetBefore))
                expect(await poolStorage.totalEntryFeeCollected()).to.equal(fee.add(totalEntryFeeCollectedBefore))
            })

            it('Withdraw', async function () {
                const poolDetails = await pool.poolDetails()

                const totalWithdrawnEntryAssetBefore = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedBefore = await poolStorage.totalEntryFeeCollected()
                const entryTokenBalanceBefore = await tokenA.balanceOf(investor)
                const kTokenBalance = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).withdraw(kTokenBalance)

                const calculatedWithDrawAmount = await poolStorage.callStatic.calculateEntryAmount(kTokenBalance)
                const calculatedSuccessFee = calculatedWithDrawAmount.mul(poolDetails.successFee).div(denominator)
                const totalWithdrawnEntryAssetAfter = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedAfter = await poolStorage.totalEntryFeeCollected()
                const entryTokenBalanceAfter = await tokenA.balanceOf(investor)

                expect(totalWithdrawnEntryAssetAfter).to.equal(totalWithdrawnEntryAssetBefore.add(calculatedWithDrawAmount))
                expect(totalSuccessFeeCollectedAfter).to.equal(totalSuccessFeeCollectedBefore.add(calculatedSuccessFee))
                expect(await poolStorage.balanceOf(investor)).to.equal(0)
                // expect(entryTokenBalanceAfter).to.equal(entryTokenBalanceBefore.add())
                //toDo complete check balances after withdraw
            })
        })

        describe('Invest & Earn', async function () {
            let entryBalanceBefore: BigNumber, balanceKBefore: BigNumber;
            let entryBalanceAfterInvest: BigNumber, balanceKAfterInvest: BigNumber;
            let entryBalanceAfterWithdraw: BigNumber, balanceKAfterWithdraw: BigNumber;

            before(async function () {
                entryBalanceBefore = await tokenA.balanceOf(investor)
                balanceKBefore = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).invest(investor, entryAmountToInvest)

                entryBalanceAfterInvest = await tokenA.balanceOf(investor)
                balanceKAfterInvest = await poolStorage.balanceOf(investor)
            })

            it('Invest and earn', async function () {
                // Mint assets to imitate earning
                await tokenB.mint(pool.address, ethers.utils.parseEther("100"))
                await tokenC.mint(pool.address, ethers.utils.parseEther("100"))

                const kTokenBalance = await poolStorage.balanceOf(investor)
                await pool.connect(investorAcc).withdraw(kTokenBalance)

                entryBalanceAfterWithdraw = await tokenA.balanceOf(investor)
                balanceKAfterWithdraw = await poolStorage.balanceOf(investor)

                expect(entryBalanceAfterWithdraw).to.gt(entryBalanceBefore)
                expect(balanceKAfterWithdraw).to.equal(0)
            })
        })

        describe('Includes entryAsset as a pool asset', async function () {
            let balanceABefore: BigNumber, balanceABeforeGov: BigNumber, balanceKBefore: BigNumber;
            let balanceAAfter: BigNumber, balanceAAfterGov: BigNumber, balanceKAfter: BigNumber;

            before(async function () {

                tokens = [
                    {name: "USDT", network: hre.network.name, address: tokenA.address},
                    {name: "USDC", network: hre.network.name, address: tokenB.address},
                    {name: "Bitcoin", network: hre.network.name, address: tokenC.address},
                ]

                // @ts-ignore
                poolInfo = await deployer.createPool(contracts.factory, contracts.swapper.address, tokens, tokenA.address, true);
                poolAddress = poolInfo[0]
                poolStorageAddress = poolInfo[1]
                pool = await ethers.getContractAt("Pool", poolAddress);
                poolStorage = await ethers.getContractAt("PoolStorage", poolStorageAddress);
                expect(await contracts.factory.poolsCount()).to.equal(2)

                console.log(await tokenA.balanceOf(investor))

                balanceABefore = await tokenA.balanceOf(investor)
                balanceABeforeGov = await tokenA.balanceOf(governance)
                balanceKBefore = await poolStorage.balanceOf(investor)

                await tokenA.connect(investorAcc).approve(pool.address, ethers.constants.MaxUint256)
                await pool.connect(investorAcc).invest(investor, entryAmountToInvest)

                balanceAAfter = await tokenA.balanceOf(investor)
                balanceAAfterGov = await tokenA.balanceOf(governance)
                balanceKAfter = await poolStorage.balanceOf(investor)
            })

            it('First invest.', async function () {
                expect(balanceAAfter).to.equal(balanceABefore.sub(entryAmountToInvest))
                expect(balanceAAfterGov).to.equal(balanceABeforeGov.add(fee))
                expect(balanceKAfter).to.equal(balanceKBefore.add(investedAmount))
                //check poolStorage
                expect(await poolStorage.totalReceivedEntryAsset()).to.equal(investedAmount)
                expect(await poolStorage.totalEntryFeeCollected()).to.equal(fee)
            })

            it('Second Invest from other account', async function () {
                const totalReceivedEntryAssetBefore = await poolStorage.totalReceivedEntryAsset()
                const totalEntryFeeCollectedBefore = await poolStorage.totalEntryFeeCollected()

                balanceABefore = await tokenA.balanceOf(investor2)
                balanceABeforeGov = await tokenA.balanceOf(governance)
                balanceKBefore = await poolStorage.balanceOf(investor2)
                const calculatedKTokens = await poolStorage.callStatic.calculateShares(entryAmountToInvest.sub(fee))

                await tokenA.connect(investor2Acc).approve(pool.address, ethers.constants.MaxUint256)
                await pool.connect(investor2Acc).invest(investor2, entryAmountToInvest)

                balanceAAfter = await tokenA.balanceOf(investor2)
                balanceAAfterGov = await tokenA.balanceOf(governance)
                balanceKAfter = await poolStorage.balanceOf(investor2)

                expect(balanceAAfter).to.equal(balanceABefore.sub(entryAmountToInvest))
                expect(balanceAAfterGov).to.equal(balanceABeforeGov.add(fee))
                expect(balanceKAfter).to.equal(calculatedKTokens)

                //check poolStorage
                expect(await poolStorage.totalReceivedEntryAsset()).to.equal(investedAmount.add(totalReceivedEntryAssetBefore))
                expect(await poolStorage.totalEntryFeeCollected()).to.equal(fee.add(totalEntryFeeCollectedBefore))
            })

            it('Withdraw', async function () {
                const poolDetails = await pool.poolDetails()

                const totalWithdrawnEntryAssetBefore = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedBefore = await poolStorage.totalEntryFeeCollected()
                const entryTokenBalanceBefore = await tokenA.balanceOf(investor)
                const kTokenBalance = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).withdraw(kTokenBalance)

                const calculatedWithDrawAmount = await poolStorage.callStatic.calculateEntryAmount(kTokenBalance)
                const calculatedSuccessFee = calculatedWithDrawAmount.mul(poolDetails.successFee).div(denominator)
                const totalWithdrawnEntryAssetAfter = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedAfter = await poolStorage.totalEntryFeeCollected()
                const entryTokenBalanceAfter = await tokenA.balanceOf(investor)

                expect(totalWithdrawnEntryAssetAfter).to.equal(totalWithdrawnEntryAssetBefore.add(calculatedWithDrawAmount))
                expect(totalSuccessFeeCollectedAfter).to.equal(totalSuccessFeeCollectedBefore.add(calculatedSuccessFee))
                expect(await poolStorage.balanceOf(investor)).to.equal(0)
                // expect(entryTokenBalanceAfter).to.equal(entryTokenBalanceBefore.add())
                //toDo complete check balances after withdraw
            })
        })
    })
})

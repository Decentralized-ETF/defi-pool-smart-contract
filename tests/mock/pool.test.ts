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


function equalWithInaccuracy(expected: BigNumber, actual: BigNumber) {
    const INACCURACY = BigNumber.from("5");
    if (expected.gte(actual)) {
        expect(expected.sub(actual)).lte(INACCURACY)
    } else {
        expect(actual.sub(expected)).lte(INACCURACY)
    }
}

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
    let entryAmountToInvest: BigNumber = BigNumber.from(poolParams.minInvestment).mul(1000000000000000);
    let entryAmountToMint: BigNumber = ethers.utils.parseEther((parseInt(poolParams.minInvestment) * 100).toString())
    let tokenA: MockToken, tokenB: MockToken, tokenC: MockToken
    let amountToAddLiquidityUSD: BigNumber = entryAmountToInvest.mul(10)
    let amountToAddLiquidityBTC: BigNumber = entryAmountToInvest.mul(10)
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
            await contracts.router.addLiquidityETH(tokenA.address, amountToAddLiquidityBTC, 0, 0, governance, deadline, {value: amountToAddLiquidityUSD})
            await contracts.router.addLiquidityETH(tokenB.address, amountToAddLiquidityBTC, 0, 0, governance, deadline, {value: amountToAddLiquidityUSD})
            await contracts.router.addLiquidityETH(tokenC.address, amountToAddLiquidityBTC, 0, 0, governance, deadline, {value: amountToAddLiquidityUSD})
        })

        it('Check additional pool creation via factory', async function () {
            await deployer.createPool(contracts.factory, contracts.swapper.address, tokens, tokenA.address, true);
            expect(await contracts.factory.poolsCount()).to.equal(2)
        })

        it('Check pool details', async function () {
            const poolDetails = await pool.poolDetails()
            expect(poolDetails[0].toLowerCase()).to.equal(contracts.swapper.address.toLowerCase())
            expect(poolDetails[1].toString()).to.equal(poolParams.minInvestment)
            expect(poolDetails[2]).to.equal(parseInt(poolParams.entryFee))
            expect(poolDetails[3]).to.equal(parseInt(poolParams.successFee))
            expect(await pool.poolStorage()).to.equal(poolStorageAddress)
        })

        it('Check default assets weights', async function () {
            expect(deployer.WEIGHT_SUM).to.equal(await pool.weightsSum())
        })

        describe('Invest & Withdraw', async function () {
            let balanceABefore: BigNumber, balanceABeforeGov: BigNumber, balanceKBefore: BigNumber, poolValueAfterFirstInvest: BigNumber
            let balanceAAfter: BigNumber, balanceAAfterGov: BigNumber, balanceKAfter: BigNumber, sharePrice: BigNumber

            before(async function () {
                balanceABefore = await tokenA.balanceOf(investor)
                balanceABeforeGov = await tokenA.balanceOf(governance)
                balanceKBefore = await poolStorage.balanceOf(investor)
                sharePrice = await poolStorage.callStatic.sharePrice(); // callStatic because of UniswapV3 Quoter...

                await pool.connect(investorAcc).invest(investor, entryAmountToInvest)

                balanceAAfter = await tokenA.balanceOf(investor)
                balanceAAfterGov = await tokenA.balanceOf(governance)
                balanceKAfter = await poolStorage.balanceOf(investor)
            })

            it('First invest.', async function () {
                expect(balanceAAfter).to.equal(balanceABefore.sub(entryAmountToInvest))
                expect(balanceAAfterGov).to.equal(balanceABeforeGov.add(fee))
                poolValueAfterFirstInvest = await pool.callStatic.totalValue();
                const expectedShares = await poolStorage.calculateSharesBySpecificPrice(poolValueAfterFirstInvest, sharePrice)
                expect(balanceKAfter).to.equal(balanceKBefore.add(expectedShares))
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
                const sharePrice2 = await poolStorage.callStatic.sharePrice(); 

                await pool.connect(investor2Acc).invest(investor2, entryAmountToInvest)

                const secondInvestAmount = (await pool.callStatic.totalValue()).sub(poolValueAfterFirstInvest);
                const calculatedKTokens = await poolStorage.callStatic.calculateSharesBySpecificPrice(secondInvestAmount, sharePrice2);
                balanceAAfter = await tokenA.balanceOf(investor2)
                balanceAAfterGov = await tokenA.balanceOf(governance)
                balanceKAfter = await poolStorage.balanceOf(investor2)

                expect(balanceAAfter).to.equal(balanceABefore.sub(entryAmountToInvest))
                expect(balanceAAfterGov).to.equal(balanceABeforeGov.add(fee))
                expect(balanceKAfter).to.equal(calculatedKTokens)

                //check poolStorage
                expect(await poolStorage.totalReceivedEntryAsset()).to.equal(entryAmountToInvest.add(totalReceivedEntryAssetBefore).sub(fee))
                expect(await poolStorage.totalEntryFeeCollected()).to.equal(fee.add(totalEntryFeeCollectedBefore))
            })

            it('Withdraw partly', async function () {
                const totalWithdrawnEntryAssetBefore = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedBefore = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceBefore = await tokenA.balanceOf(investor)
                const kTokenBalance = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).withdraw(kTokenBalance.div(2))

                const totalWithdrawnEntryAssetAfter = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedAfter = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceAfter = await tokenA.balanceOf(investor)

                expect(totalWithdrawnEntryAssetAfter).gt(totalWithdrawnEntryAssetBefore)
                expect(totalSuccessFeeCollectedAfter).gt(totalSuccessFeeCollectedBefore)
                expect(await poolStorage.balanceOf(investor)).gt(0)
                expect(entryTokenBalanceAfter).gt(entryTokenBalanceBefore) // todo: think how to enable exact checking with swapFees conditions
            })

            it('Withdraw all', async function () {
                const totalWithdrawnEntryAssetBefore = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedBefore = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceBefore = await tokenA.balanceOf(investor)
                const kTokenBalance = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).withdraw(kTokenBalance)

                const totalWithdrawnEntryAssetAfter = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedAfter = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceAfter = await tokenA.balanceOf(investor)

                expect(totalWithdrawnEntryAssetAfter).gt(totalWithdrawnEntryAssetBefore)
                expect(totalSuccessFeeCollectedAfter).gt(totalSuccessFeeCollectedBefore)
                expect(await poolStorage.balanceOf(investor)).to.equal(0)
                expect(entryTokenBalanceAfter).gt(entryTokenBalanceBefore) // todo: think how to enable exact checking with swapFees conditions
            })
        })

        describe('Invest & Earn', async function () {
            let entryBalanceBefore: BigNumber, balanceKBefore: BigNumber;
            let entryBalanceAfterInvest: BigNumber, balanceKAfterInvest: BigNumber;
            let entryBalanceAfterWithdraw: BigNumber, balanceKAfterWithdraw: BigNumber;
            // @ts-ignore
            let sharePriceBeforeInvest: BigNumber, sharePriceAfterInvest: BigNumber;
            let sharePriceBeforeMint: BigNumber, sharePriceAfterMint: BigNumber;
            let sharePriceAfterWithdraw: BigNumber;

            before(async function () {
                entryBalanceBefore = await tokenA.balanceOf(investor)
                balanceKBefore = await poolStorage.balanceOf(investor)
                sharePriceBeforeInvest = await poolStorage.callStatic.sharePrice()

                await pool.connect(investorAcc).invest(investor, entryAmountToInvest)

                sharePriceAfterInvest = await poolStorage.callStatic.sharePrice()
                entryBalanceAfterInvest = await tokenA.balanceOf(investor)
                balanceKAfterInvest = await poolStorage.balanceOf(investor)
            })

            it('Invest and earn', async function () {

                sharePriceBeforeMint = await poolStorage.callStatic.sharePrice()

                // Mint assets to imitate earning
                await tokenB.mint(pool.address, ethers.utils.parseEther("200"))
                await tokenC.mint(pool.address, ethers.utils.parseEther("200"))
                sharePriceAfterMint = await poolStorage.callStatic.sharePrice()

                const kTokenBalance = await poolStorage.balanceOf(investor)
                await pool.connect(investorAcc).withdraw(kTokenBalance)

                sharePriceAfterWithdraw = await poolStorage.callStatic.sharePrice()
                entryBalanceAfterWithdraw = await tokenA.balanceOf(investor)
                balanceKAfterWithdraw = await poolStorage.balanceOf(investor)

                expect(sharePriceAfterMint).gt(sharePriceBeforeMint)
                equalWithInaccuracy(sharePriceAfterWithdraw, sharePriceAfterMint)
                expect(entryBalanceAfterWithdraw).to.gt(entryBalanceBefore)
                expect(balanceKAfterWithdraw).to.equal(0)
            })
        })

        describe('Includes entryAsset as a pool asset', async function () {
            let balanceABefore: BigNumber, balanceABeforeGov: BigNumber, balanceKBefore: BigNumber, poolValueAfterFirstInvest: BigNumber
            let balanceAAfter: BigNumber, balanceAAfterGov: BigNumber, balanceKAfter: BigNumber, sharePrice: BigNumber

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
                expect(await contracts.factory.poolsCount()).to.equal(3)

                balanceABefore = await tokenA.balanceOf(investor)
                balanceABeforeGov = await tokenA.balanceOf(governance)
                balanceKBefore = await poolStorage.balanceOf(investor)
                sharePrice = await poolStorage.callStatic.sharePrice(); // callStatic because of UniswapV3 Quoter...

                await tokenA.connect(investorAcc).approve(pool.address, ethers.constants.MaxUint256)
                await pool.connect(investorAcc).invest(investor, entryAmountToInvest)

                balanceAAfter = await tokenA.balanceOf(investor)
                balanceAAfterGov = await tokenA.balanceOf(governance)
                balanceKAfter = await poolStorage.balanceOf(investor)
            })

            it('First invest.', async function () {
                expect(balanceAAfter).to.equal(balanceABefore.sub(entryAmountToInvest))
                expect(balanceAAfterGov).to.equal(balanceABeforeGov.add(fee))
                poolValueAfterFirstInvest = await pool.callStatic.totalValue();
                const expectedShares = await poolStorage.calculateSharesBySpecificPrice(poolValueAfterFirstInvest, sharePrice)
                expect(balanceKAfter).to.equal(balanceKBefore.add(expectedShares))
                
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

                const sharePrice2 = await poolStorage.callStatic.sharePrice(); 

                await tokenA.connect(investor2Acc).approve(pool.address, ethers.constants.MaxUint256)
                await pool.connect(investor2Acc).invest(investor2, entryAmountToInvest)

                const secondInvestAmount = (await pool.callStatic.totalValue()).sub(poolValueAfterFirstInvest);
                const calculatedKTokens = await poolStorage.callStatic.calculateSharesBySpecificPrice(secondInvestAmount, sharePrice2);

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

            it('Withdraw partly', async function () {
                const poolDetails = await pool.poolDetails()

                const totalWithdrawnEntryAssetBefore = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedBefore = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceBefore = await tokenA.balanceOf(investor)
                const kTokenBalance = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).withdraw(kTokenBalance.div(2))

                const totalWithdrawnEntryAssetAfter = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedAfter = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceAfter = await tokenA.balanceOf(investor)

                expect(totalWithdrawnEntryAssetAfter).gt(totalWithdrawnEntryAssetBefore)
                expect(totalSuccessFeeCollectedAfter).gt(totalSuccessFeeCollectedBefore)
                expect(await poolStorage.balanceOf(investor)).gt(0)
                expect(entryTokenBalanceAfter).gt(entryTokenBalanceBefore)
            })

            it('Withdraw all', async function () {
                const poolDetails = await pool.poolDetails()

                const totalWithdrawnEntryAssetBefore = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedBefore = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceBefore = await tokenA.balanceOf(investor)
                const kTokenBalance = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).withdraw(kTokenBalance)

                const totalWithdrawnEntryAssetAfter = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedAfter = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceAfter = await tokenA.balanceOf(investor)

                expect(totalWithdrawnEntryAssetAfter).gt(totalWithdrawnEntryAssetBefore)
                expect(totalSuccessFeeCollectedAfter).gt(totalSuccessFeeCollectedBefore)
                expect(await poolStorage.balanceOf(investor)).to.equal(0)
                expect(entryTokenBalanceAfter).gt(entryTokenBalanceBefore)
            })
        })

        describe('Entry asset is native && native as pool asset', async function () {
            let balanceABefore: BigNumber, balanceABeforeGov: BigNumber, balanceKBefore: BigNumber, poolValueAfterFirstInvest: BigNumber
            let balanceAAfter: BigNumber, balanceAAfterGov: BigNumber, balanceKAfter: BigNumber, sharePrice: BigNumber

            before(async function () {
                const entryAsset = ethers.constants.AddressZero;

                tokens = [
                    {name: "USDC", network: hre.network.name, address: tokenB.address},
                    {name: "Bitcoin", network: hre.network.name, address: tokenC.address},
                    {name: "NATIVE", network: hre.network.name, address: entryAsset}
                ]
                // @ts-ignore
                poolInfo = await deployer.createPool(contracts.factory, contracts.swapper.address, tokens, entryAsset, true);
                poolAddress = poolInfo[0]
                poolStorageAddress = poolInfo[1]
                pool = await ethers.getContractAt("Pool", poolAddress);
                poolStorage = await ethers.getContractAt("PoolStorage", poolStorageAddress);

                balanceABefore = await ethers.provider.getBalance(investor)
                balanceABeforeGov = await ethers.provider.getBalance(governance)
                balanceKBefore = await poolStorage.balanceOf(investor)

                sharePrice = await poolStorage.callStatic.sharePrice(); // callStatic because of UniswapV3 Quoter...
                await pool.connect(investorAcc).invest(investor, entryAmountToInvest, {value: entryAmountToInvest})
                
                balanceAAfter = await ethers.provider.getBalance(investor)
                balanceAAfterGov = await ethers.provider.getBalance(governance)
                balanceKAfter = await poolStorage.balanceOf(investor)
            })

            it('First invest native', async function () {
                expect(balanceAAfter).lt(balanceABefore.sub(entryAmountToInvest))
                expect(balanceAAfterGov).to.equal(balanceABeforeGov.add(fee))
                poolValueAfterFirstInvest = await pool.callStatic.totalValue();
                const expectedShares = await poolStorage.calculateSharesBySpecificPrice(poolValueAfterFirstInvest, sharePrice)
                expect(balanceKAfter).to.equal(balanceKBefore.add(expectedShares))
                
                //check poolStorage
                expect(await poolStorage.totalReceivedEntryAsset()).to.equal(investedAmount)
                expect(await poolStorage.totalEntryFeeCollected()).to.equal(fee)
            })

            it('Second Native Invest from other account', async function () {
                const totalReceivedEntryAssetBefore = await poolStorage.totalReceivedEntryAsset()
                const totalEntryFeeCollectedBefore = await poolStorage.totalEntryFeeCollected()

                balanceABefore = await ethers.provider.getBalance(investor2)
                balanceABeforeGov = await ethers.provider.getBalance(governance)
                balanceKBefore = await poolStorage.balanceOf(investor2)

                const sharePrice2 = await poolStorage.callStatic.sharePrice(); 

                await pool.connect(investor2Acc).invest(investor2, entryAmountToInvest, {value: entryAmountToInvest})

                const secondInvestAmount = (await pool.callStatic.totalValue()).sub(poolValueAfterFirstInvest);
                const calculatedKTokens = await poolStorage.callStatic.calculateSharesBySpecificPrice(secondInvestAmount, sharePrice2);

                balanceAAfter = await ethers.provider.getBalance(investor2)
                balanceAAfterGov = await ethers.provider.getBalance(governance)
                balanceKAfter = await poolStorage.balanceOf(investor2)

                expect(balanceAAfter).lt(balanceABefore.sub(entryAmountToInvest))
                expect(balanceAAfterGov).to.equal(balanceABeforeGov.add(fee))
                expect(balanceKAfter).to.equal(balanceKBefore.add(calculatedKTokens))

                //check poolStorage
                expect(await poolStorage.totalReceivedEntryAsset()).to.equal(investedAmount.add(totalReceivedEntryAssetBefore))
                expect(await poolStorage.totalEntryFeeCollected()).to.equal(fee.add(totalEntryFeeCollectedBefore))
            })

            it('Withdraw partly', async function () {
                const poolDetails = await pool.poolDetails()

                const totalWithdrawnEntryAssetBefore = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedBefore = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceBefore = await ethers.provider.getBalance(investor)
                const kTokenBalance = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).withdraw(kTokenBalance.div(2))

                const totalWithdrawnEntryAssetAfter = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedAfter = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceAfter = await ethers.provider.getBalance(investor)

                expect(totalWithdrawnEntryAssetAfter).gt(totalWithdrawnEntryAssetBefore)
                expect(totalSuccessFeeCollectedAfter).gt(totalSuccessFeeCollectedBefore)
                expect(await poolStorage.balanceOf(investor)).gt(0)
                expect(entryTokenBalanceAfter).gt(entryTokenBalanceBefore)
            })

            it('Withdraw all', async function () {
                const poolDetails = await pool.poolDetails()

                const totalWithdrawnEntryAssetBefore = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedBefore = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceBefore = await ethers.provider.getBalance(investor)
                const kTokenBalance = await poolStorage.balanceOf(investor)

                await pool.connect(investorAcc).withdraw(kTokenBalance)

                const totalWithdrawnEntryAssetAfter = await poolStorage.totalWithdrawnEntryAsset()
                const totalSuccessFeeCollectedAfter = await poolStorage.totalSuccessFeeCollected()
                const entryTokenBalanceAfter = await ethers.provider.getBalance(investor)

                expect(totalWithdrawnEntryAssetAfter).gt(totalWithdrawnEntryAssetBefore)
                expect(totalSuccessFeeCollectedAfter).gt(totalSuccessFeeCollectedBefore)
                expect(await poolStorage.balanceOf(investor)).to.equal(0)
                expect(entryTokenBalanceAfter).gt(entryTokenBalanceBefore)
            })
        })
    })
})

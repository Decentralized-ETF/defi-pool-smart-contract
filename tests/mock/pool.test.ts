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
    let signerAcc: SignerWithAddress, signer: string, bob: string, sam: string
    let contracts: any;
    let poolAddress: string;
    let poolStorageAddress: string;
    let tokens: Token[];
    let poolInfo: string[];
    let pool: Pool;
    let poolStorage: PoolStorage;
    let entryTokenBalanceBeforeInvest: BigNumber;
    let entryAmountToInvest: BigNumber = ethers.utils.parseEther(poolParams.minInvestment)
    let entryAmountToMint: BigNumber = ethers.utils.parseEther((parseInt(poolParams.minInvestment) * 10).toString())
    let tokenA: MockToken, tokenB: MockToken, tokenC: MockToken

    before(async function () {
        this.signers = await ethers.getSigners()
        signerAcc = this.signers[0]
        signer = signerAcc.address

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

        await tokenA.mint(signer, entryAmountToMint)
        entryTokenBalanceBeforeInvest = await tokenA.balanceOf(signer)
        await tokenA.approve(pool.address, entryAmountToMint)
        console.log("entry token address: ", tokenA.address)
        console.log("entryTokenBalanceBeforeInvest: ", entryTokenBalanceBeforeInvest.toString())
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
        })

        it('Invest', async function () {

            await pool.invest(signer, entryAmountToInvest.mul(2))
            expect(await tokenA.balanceOf(signer)).to.equal(entryTokenBalanceBeforeInvest.sub(entryAmountToInvest))
        })
    })
})

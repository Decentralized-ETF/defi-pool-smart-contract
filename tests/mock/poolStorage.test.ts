import chai from 'chai'
import { solidity } from 'ethereum-waffle'

chai.use(solidity)
const { ethers } = require("hardhat");
import hre from 'hardhat'
import { Deployer } from '../../scripts/classes/Deployer'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

import {Token} from "../../scripts/interfaces";
import {MockToken, Pool, PoolStorage} from "../../typechain";
const { expect } = chai;


describe('PoolStorage Contract', () => {
    let deployer: Deployer
    let governanceAcc: SignerWithAddress, governance: string, investorAcc: SignerWithAddress, investor: string
    let contracts: any;
    let poolAddress: string;
    let poolStorage: PoolStorage;
    let poolStorageAddress: string;
    let tokens: Token[];
    let poolInfo: string[];
    let tokenA: MockToken, tokenB: MockToken, tokenC: MockToken

    before(async function () {
        this.signers = await ethers.getSigners()
        governanceAcc = this.signers[0]
        investorAcc = this.signers[0]
        governance = governanceAcc.address
        investor = investorAcc.address

        deployer = new Deployer()
        contracts = await deployer.deployTestContracts(2)

        tokenA = (await deployer.deploy('MockToken', ['USDT', 'USDT', 18])) as MockToken
        tokenB = (await deployer.deploy('MockToken', ['USDC', 'USDC', 18])) as MockToken
        tokenC = (await deployer.deploy('MockToken', ['Bitcoin', 'BTC', 18])) as MockToken
        tokens = [
            {name: "USDT", network: hre.network.name, address: tokenA.address},
            {name: "USDC", network: hre.network.name, address: tokenB.address},
        ]

        // @ts-ignore
        poolInfo = await deployer.createPool(contracts.factory, contracts.swapper.address, tokens, true);
        poolAddress = poolInfo[0]
        poolStorageAddress = poolInfo[1]
        poolStorage = await ethers.getContractAt("PoolStorage", poolStorageAddress);
    })

    describe('PoolStorage', async function () {

        it('factory', async function () {
            expect(await poolStorage.factory()).to.equal(contracts.factory.address)
        })

        it('pool', async function () {
            expect(await poolStorage.pool()).to.equal(poolAddress)
        })

        it('poolStorageId', async function () {
            expect(await poolStorage.poolStorageId()).to.equal(await contracts.factory.poolsCount())
        })

        it('feeReceiver', async function () {
            expect(await poolStorage.feeReceiver()).to.equal(governance)
        })

        it('entryAsset', async function () {
            expect(await poolStorage.entryAsset()).to.equal(tokens[0].address)
        })

        it('setFeeReceiver CALLER_IS_NOT_FACTORY', async function () {
            await expect(poolStorage.setFeeReceiver(investor)).to.be.revertedWith("CALLER_IS_NOT_FACTORY")
        })

        it('setFeeReceiver', async function () {
            await contracts.factory.setFeeReceiver(poolStorageAddress, investor)
            expect(await poolStorage.feeReceiver()).to.equal(investor)
        })

    })
})

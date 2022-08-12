import chai from 'chai'
import { solidity } from 'ethereum-waffle'

chai.use(solidity)
const { ethers } = require("hardhat");
import hre from 'hardhat'
import { Deployer } from '../../scripts/classes/Deployer'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

import {Token} from "../../scripts/interfaces";
import {MockToken, Pool} from "../../typechain";
const { expect } = chai;


describe('Factory Contract', () => {
    let deployer: Deployer
    let governanceAcc: SignerWithAddress, governance: string, dmitryAcc: SignerWithAddress, dmitry: string
    let contracts: any;
    let poolAddress: string;
    let poolStorageAddress: string;
    let tokens: Token[];
    let tokens2: Token[];
    let poolInfo: string[];
    let pool: Pool;
    let tokenA: MockToken, tokenB: MockToken, tokenC: MockToken

    before(async function () {
        this.signers = await ethers.getSigners()
        governanceAcc = this.signers[0]
        dmitryAcc = this.signers[0]
        governance = governanceAcc.address
        dmitry = dmitryAcc.address

        deployer = new Deployer()
        contracts = await deployer.deployTestContracts(2)
    })

    describe('Factory', async function () {
        it('defaultFeeReceiver', async function () {
            expect(await contracts.factory.defaultFeeReceiver()).to.equal(governance)
        })
        it('swapper', async function () {
            expect(await contracts.factory.swapper()).to.equal(contracts.swapper.address)
        })
        it('pools', async function () {
            expect(await contracts.factory.poolsCount()).to.equal(0)
        })
        it('poolStorages', async function () {
            expect(await contracts.factory.poolStorages.length).to.equal(0)
        })
        describe('Create pool and Storages', async function () {
            before(async function () {
                tokenA = (await deployer.deploy('MockToken', ['USDT', 'USDT', 18])) as MockToken
                tokenB = (await deployer.deploy('MockToken', ['USDC', 'USDC', 18])) as MockToken
                tokenC = (await deployer.deploy('MockToken', ['Bitcoin', 'BTC', 18])) as MockToken
                tokens = [
                    {name: "USDT", network: hre.network.name, address: tokenA.address},
                    {name: "USDC", network: hre.network.name, address: tokenB.address},
                ]
                tokens2 = [
                    {name: "USDT", network: hre.network.name, address: tokenA.address},
                    {name: "Bitcoin", network: hre.network.name, address: tokenC.address},
                ]

                // @ts-ignore
                poolInfo = await deployer.createPool(contracts.factory, contracts.swapper.address, tokens, true);
                poolAddress = poolInfo[0]
                poolStorageAddress = poolInfo[1]
                pool = await ethers.getContractAt("Pool", poolAddress);
            })

            it('Increase pools array length while creating pool ', async function () {
                const poolsCount = await contracts.factory.poolsCount()
                expect(poolsCount).to.equal(1)
                expect(await contracts.factory.poolStorages(poolsCount - 1)).to.equal(poolStorageAddress)
            })

            it('Match latest storage created with poolsStorages array', async function () {
                expect(await contracts.factory.poolStorages((await contracts.factory.poolsCount()) - 1)).to.equal(poolStorageAddress)
            })

            it('Re-link pool with another storage', async function () {
                // @ts-ignore
                const poolInfo2: string[] = await deployer.createPool(contracts.factory, contracts.swapper.address, tokens2, true);
                const poolAddress2 = poolInfo2[0]
                const poolStorageAddress2 = poolInfo2[1]
                expect(await contracts.factory.poolsCount()).to.equal(2)
                expect(await contracts.factory.poolStorages((await contracts.factory.poolsCount()) - 1)).to.equal(poolStorageAddress2)

                const pool2 = await ethers.getContractAt("Pool", poolAddress2);
                expect(await pool.poolStorage()).to.equal(poolStorageAddress)
                expect(await pool2.poolStorage()).to.equal(poolStorageAddress2)

                await contracts.factory.switchStorageToNewPool(poolAddress2, poolStorageAddress)
                expect(await pool.poolStorage()).to.equal(poolStorageAddress)
                expect(await pool2.poolStorage()).to.equal(poolStorageAddress)
                // ToDo Не нужно ли разлинковывать старый пул со сторейдж?
            })
        })
    })
})

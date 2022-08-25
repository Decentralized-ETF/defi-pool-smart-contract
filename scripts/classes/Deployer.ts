import hre, { ethers } from 'hardhat'
import { poolParams, ROUTERS, TEST_ROUTERS, TOKENS } from '../config'
import { PoolDetails, Routers, TestRouter, Token, PoolConfig, SavedPool } from '../interfaces'
import { Factory, MockToken, MockWeth, Swapper } from '../../typechain'
import { loadPools, saveJSON } from '../utils'
import { BigNumber, Contract } from 'ethers'
import {sleep} from "../../tests/helpers";

export class Deployer {
    WEIGHT_SUM: BigNumber
    constructor() {
        this.WEIGHT_SUM = BigNumber.from(1000000)
    }

    async deployOnChain(verify: boolean = false) {
        const [governance] = await ethers.getSigners()
        const network = hre.network.name

        const routers = ROUTERS.filter((router) => router.network === network)

        const routerAddresses = routers.map((val) => val.address)
        const routerTypes = routers.map((val) => val.type)
        const defaultRouter = routers.find((val) => val.isDefault)?.address || routers[0].address

        const Swapper = (await this.deploy(
            'Swapper',
            [routerAddresses, routerTypes, defaultRouter, ethers.constants.AddressZero],
            verify
        )) as Swapper
        const Factory = (await this.deploy('Factory', [governance.address, Swapper.address], verify)) as Factory
        await saveJSON({ swapper: Swapper.address, factory: Factory.address }, 'core')

        await this.createPool(Factory, Swapper.address, TOKENS) // create default pool
        return { swapper: Swapper, factory: Factory, defaultRouter }
    }

    async deployTestContracts(routerType: number, _routers: TestRouter[] = TEST_ROUTERS) {
        const [governance] = await ethers.getSigners()

        const routersConfig = _routers.filter((router) => router.network === 'hardhat' && router.type === routerType.toString())
        const { router, routerFactory } = await this.deployMockRouter(routersConfig[0])
        //Todo change _uniswapV3quoter
        const Swapper = await this.deploy('Swapper', [[router.address], [routerType], router.address, governance.address])
        const Factory = await this.deploy('Factory', [governance.address, Swapper.address])
        return { swapper: Swapper, factory: Factory, router, routerFactory }
    }

    async deployMockRouter(routerData: TestRouter) {
        const routerFactory = await this.deploy(routerData.factoryName, [])
        const WETH = await this.deploy('MockWeth', ['Wrapped ETH', 'WETH'])
        const router = await this.deploy(routerData.name, [routerFactory.address, WETH.address])
        return { router, routerFactory }
    }

    async deploy(contractName: string, args: any[], verify: boolean = false): Promise<Contract> {
        const needLibrary = ['Pool', 'Factory']
        const Lib = await ethers.getContractFactory('KedrLib')
        const lib = await Lib.deploy()
        await lib.deployed()

        let factory
        if (needLibrary.includes(contractName)) {
            factory = await ethers.getContractFactory(contractName, { libraries: { KedrLib: lib.address } })
        } else {
            factory = await ethers.getContractFactory(contractName)
        }

        const [signer] = await ethers.getSigners()

        const Contract = await factory.connect(signer).deploy(...args)
        await Contract.deployed()
        console.log(`Contract ${contractName} is deployed at: ${Contract.address}`)
        if (verify) {
            try {
                await sleep(5)
                await this.verify(Contract.address, ...args)
                console.log(`Contract ${contractName} is verified`)
            } catch (e) {
                console.log(`There is an error During verification ${contractName} contract\n${e}`)
            }
        }
        return Contract
    }

    async verify(_address: string, ...args: any[]) {
        await hre.run('verify:verify', {
            address: _address,
            constructorArguments: args,
        })
    }

    async createPool(Factory: Factory, swapper: string, _tokensConfig = TOKENS, _entryAsset: string = '', _test: boolean = false) {
        const [governance] = await ethers.getSigners()
        const tokensByNetwork = _tokensConfig.filter((val) => val.network == hre.network.name)
        const filteredTokens = tokensByNetwork.filter((token) => token.name !== 'DAI')
        const tokens = filteredTokens.map((token) => token.address)
        let entryAsset = tokensByNetwork.find((token) => token.name === 'DAI')?.address as string
        const poolDetails: PoolDetails = {
            swapper,
            successFee: poolParams.successFee,
            entryFee: poolParams.entryFee,
            assets: tokens,
            weights: new Array(tokens.length).fill(this.WEIGHT_SUM.div(tokens.length)), // similar weights
            minInvestment: poolParams.minInvestment,
            balanceable: true,
        }
        if (_entryAsset) {
            entryAsset = _entryAsset
        }

        const poolsCountBefore = await Factory.poolsCount()
        if (_test) {
            const poolInfo = await Factory.callStatic.create(poolDetails, entryAsset)
            await Factory.create(poolDetails, entryAsset)

            console.log(
                `Pool created on address: ${poolInfo} with params:\nEntry asset: ${entryAsset}\nTokens: ${filteredTokens.map(
                    (token) => token.name
                )}`
            )
            return poolInfo
        }
        await Factory.create(poolDetails, entryAsset)
        console.log(`Pool creation tx is sended`)
        while (true) {
            await sleep(10)
            const count = await Factory.poolsCount()
            if (count.gt(poolsCountBefore) || +poolsCountBefore > 0) {
                const poolId = count.toString()
                const pool = await Factory.pools(+poolId - 1)
                const poolStorageId = (await Factory.poolsStorageCount()).toString()
                const poolStorage = await Factory.poolStorages(+poolStorageId - 1)

                const PoolStorage = await hre.ethers.getContractAt("PoolStorage", poolStorage);
                const name = await PoolStorage.name();
                const symbol = await PoolStorage.symbol();
                const poolItem: SavedPool = {
                    poolStorageId,
                    poolStorage,
                    poolId,
                    pool,
                    entryToken: entryAsset,
                    symbol,
                    name
                }

                let pools = await loadPools();
                if (+poolsCountBefore == 0) {
                    pools = [poolItem]
                } else {
                    pools.push(poolItem)
                }

                console.log(JSON.stringify(pools))

                await saveJSON(JSON.stringify(pools), 'pools')
                console.log(`Pool created: ${pool}`)
                console.log(`Pool storage created: ${poolStorage}`)
                await this.verify(pool, poolId, swapper)
                await this.verify(poolStorage, poolStorageId, entryAsset, governance.address, name, symbol);

                return pool
            }
        }
    }
}

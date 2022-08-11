import hre, { ethers } from 'hardhat'
import {poolParams, ROUTERS, TEST_ROUTERS, TOKENS} from "../config";
import {PoolDetails, Routers, TestRouter} from "../interfaces";
import {Factory, MockToken, MockWeth} from "../../typechain";


export class Deployer {
  constructor() {

  }

  async deployOnChain(verify: boolean = false) {
    const [governance] = await ethers.getSigners()
    const network = hre.network.name

    const routers = ROUTERS.filter(router => router.network === network)

    const routerAddresses = routers.map(val => val.address);
    const routerTypes = routers.map(val => val.type);
    const defaultRouter = routers.find(val => val.isDefault)?.address || routers[0].address

    const Swapper = await this.deploy("Swapper", [routerAddresses, routerTypes, defaultRouter], verify);
    const Factory = await this.deploy("Factory", [governance.address, Swapper.address], verify);

    await this.createPool(Factory, Swapper.address); // create default pool
    return { swapper: Swapper, factory: Factory, defaultRouter }
  }

  async deployTestContracts(routerType: number, _routers: TestRouter[] = TEST_ROUTERS) {
    const [governance] = await ethers.getSigners()

    const routersConfig = _routers.filter(router => router.network === "hardhat" && router.type === routerType.toString())
    const {router} = await this.deployMockRouter(routersConfig[0])

    const Swapper = await this.deploy("Swapper", [[router.address], [routerType], router.address]);
    const Factory = await this.deploy("Factory", [governance.address, Swapper.address]);
    return { swapper: Swapper, factory: Factory, router }
  }

  async deployMockRouter(routerData: TestRouter){
    const routerFactory = await this.deploy(routerData.factoryName, []);
    const WETH = await this.deploy('MockWeth', ['Wrapped ETH', 'WETH'])
    const router = await this.deploy(routerData.name, [routerFactory.address, WETH.address]);
    return {router, routerFactory}
  }

  async deploy(contractName: string, args: any[], verify: boolean = false): Promise<any> {
    const factory = await ethers.getContractFactory(contractName);
    const [signer] = await ethers.getSigners();

    const Contract = await factory.connect(signer).deploy(...args);
    await Contract.deployed();
    console.log(`Contract ${contractName} is deployed at: ${Contract.address}`);
    if (verify) {
      try {
        await this.sleep(5);
        await this.verify(Contract.address, ...args);
        console.log(`Contract ${contractName} is verified`);
      } catch (e) {
        console.log(`There is an error During verification ${contractName} contract\n${e}`)
      }
    }
    return Contract;
  }

  async verify(_address: string, ...args: any[]) {
    await hre.run('verify:verify', {
      address: _address,
      constructorArguments: args
    })
  }

  async createPool(Factory: Factory, swapper: string, _tokensConfig = TOKENS, _test: boolean = false) {
    const tokens = _tokensConfig.filter(val => val.network == hre.network.name).map(token => token.address);
    const poolDetails: PoolDetails = {
      swapper,
      successFee: poolParams.successFee,
      entryFee: poolParams.entryFee,
      assets: tokens,
      weights: new Array(tokens.length).fill((100 / tokens.length).toFixed(0).toString()),
      minInvestment: poolParams.minInvestment
    }
    const entryAsset = tokens[0]
    if(_test) {
      const poolInfo = await Factory.callStatic.create(poolDetails, entryAsset);
      await Factory.create(poolDetails, entryAsset);
      return poolInfo

    }
    return await Factory.create(poolDetails, entryAsset);
  }

  async sleep(seconds: number) {
    return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
  }
}

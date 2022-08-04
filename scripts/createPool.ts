import hre from "hardhat";
import {PoolDetails} from "./interfaces";
import {TOKENS} from "./config";
import { Factory } from "../typechain/Factory";

export async function createPool(Factory: Factory, swapper: string) {

    const tokens = TOKENS.filter(val => val.network == hre.network.name).map(token => token.address);
    const poolDetails: PoolDetails = {
        swapper,
        successFee: "500",
        entryFee: "1000",
        assets: tokens,
        weights: new Array().fill((100 / tokens.length).toString()),
        minInvestment: "1000"
    }
    const entryAsset = tokens[0]

    await Factory.create(poolDetails, entryAsset);
}
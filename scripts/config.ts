import {Routers, PoolDetails, Token, TestRouter} from "./interfaces";

export const ROUTERS: Routers[] = [
    {   
        name: "pancakeswap",
        network: "bsc",
        address: "0x10ED43C718714eb63d5aA57B78B54704E256024E",
        type: "2",
        isDefault: true
    },
    {   
        name: "uniswap",
        network: "ethereum",
        address: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        type: "2",
        isDefault: true
    },
    {   
        name: "quickswap",
        network: "polygon",
        address: "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff",
        type: "2",
        isDefault: true
    }
]

export const TEST_ROUTERS: TestRouter[] = [
    {
        name: "UniswapV2RouterMock",
        factoryName: "UniswapV2FactoryMock",
        network: "hardhat",
        type: "2",
    },
    {
        name: "",
        factoryName: "",
        network: "hardhat",
        type: "2",
    },
    {
        name: "",
        factoryName: "",
        network: "hardhat",
        type: "3",
    }
]

export const TOKENS: Token[] = [
    {
        name: "USDT",
        network: "bsc",
        address: "0x55d398326f99059fF775485246999027B3197955"
    }
]

export const poolParams = {
    successFee: "500",
    entryFee: "1000",
    minInvestment: "1000"
}
  
import {Routers, PoolDetails, Token, TestRouter, PoolConfig} from "./interfaces";
const AddressZero = "0x0000000000000000000000000000000000000000"

const wETH_P = {
    name: 'wETH',
    network: 'polygon',
    address: '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
}
const wMATIC_P = {
    name: 'wMATIC',
    network: 'polygon',
    address: '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270',
}
const USDT_P = {
    name: 'USDT',
    network: 'polygon',
    address: '0xc2132d05d31c914a87c6611c10748aeb04b58e8f',
};
const USDC_P = {
    name: 'USDC',
    network: 'polygon',
    address: '0x2791bca1f2de4661ed88a30c99a7a9449aa84174',
};
const CRV_P = {
    name: 'CRV',
    network: 'polygon',
    address: '0x172370d5cd63279efa6d502dab29171933a610af',
};

const AAVE_P = {
    name: 'AAVE',
    network: 'polygon',
    address: '0xd6df932a45c0f255f85145f286ea0b292b21c90b',
};

const wBTC_P = {
    name: 'wBTC',
    network: 'polygon',
    address: '0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6',
};

const UNI_P = {
    name: 'UNI',
    network: 'polygon',
    address: '0xb33eaad8d922b1083446dc23f610c2567fb5180f',
};

// const MKR_P = {
//     name: 'MKR',
//     network: 'polygon',
//     address: '0x6f7C932e7684666C9fd1d44527765433e01fF61d',
// }

const YFI_P = {
    name: 'YFI',
    network: 'polygon',
    address: '0xda537104d6a5edd53c6fbba9a898708e465260b6',
}

const DAI_P = {
    name: 'DAI',
    network: 'polygon',
    address: '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063',
}

const QUICK_P = {
    name: 'QUICK(OLD)',
    network: 'polygon',
    address: '0x831753DD7087CaC61aB5644b308642cc1c33Dc13',
}

const SAND_P = {
    name: 'SAND',
    network: 'polygon',
    address: '0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683',
}



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
    },
    // {   
    //     name: "uniswap-polygon",
    //     network: "polygon",
    //     address: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
    //     type: "3",
    //     isDefault: true
    // }
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


export const topTVLDeFiUSDT: PoolConfig = {
    entryAsset: USDT_P,
    assets: [CRV_P, AAVE_P, wBTC_P, UNI_P],
    weights: [25, 25, 25, 25],
    name: 'TOP TVL DeFi',
    symbol: 'kTVLDeFi_USDT'
}

export const topTVLDeFiWETH: PoolConfig = {
    entryAsset: wETH_P,
    assets: [CRV_P, AAVE_P, wBTC_P, UNI_P],
    weights: [25, 25, 25, 25],
    name: 'TOP TVL DeFi',
    symbol: 'kTVLDeFi_wETH'
}

export const etherEssentialsUSDT: PoolConfig = {
    entryAsset: USDT_P,
    assets: [wETH_P, CRV_P, SAND_P, AAVE_P, UNI_P, QUICK_P],
    weights: [20,15,15,15,15,20],
    name: 'Ethereum Essentials',
    symbol: 'kEE_USDT'
}

export const etherEssentialsETH: PoolConfig = {
    entryAsset: wETH_P,
    assets: [wBTC_P, CRV_P, SAND_P, AAVE_P, UNI_P, QUICK_P],
    weights: [20,15,15,15,15,20],
    name: 'Ethereum Essentials',
    symbol: 'kEE_wETH'
}

export const etherEssentialsBTC: PoolConfig = {
    entryAsset: wBTC_P,
    assets: [wETH_P, CRV_P, SAND_P, AAVE_P, UNI_P, QUICK_P],
    weights: [20,15,15,15,15,20],
    name: 'Ethereum Essentials',
    symbol: 'kEE_wBTC'
}

export const cmiPolygonUSDC: PoolConfig = {
    entryAsset: USDC_P,
    assets: [USDT_P, wETH_P, wBTC_P],
    weights: [34,33,33],
    name: 'CMI Polygon Index',
    symbol: 'kCMIPo_USDC'
}

export const cmiPolygonUSDT: PoolConfig = {
    entryAsset: USDT_P,
    assets: [USDC_P, wETH_P, wBTC_P],
    weights: [34,33,33],
    name: 'CMI Polygon Index',
    symbol: 'kCMIPo_USDT'
}

export const cmiPolygonMATIC: PoolConfig = {
    entryAsset: wMATIC_P,
    assets: [USDC_P, wETH_P, wBTC_P],
    weights: [34,33,33],
    name: 'CMI Polygon Index',
    symbol: 'kCMIPo_wMATIC'
}

export const usdSafeMatic: PoolConfig = {
    entryAsset: wMATIC_P,
    assets: [USDC_P, USDT_P, DAI_P],
    weights: [33,33,34],
    name: 'USD Safe deposit',
    symbol: 'kUSDSafe_wMATIC',
}

export const usdSafeBTC: PoolConfig = {
    entryAsset: wBTC_P,
    assets: [USDC_P, USDT_P, DAI_P],
    weights: [33,33,34],
    name: 'USD Safe deposit',
    symbol: 'kUSDSafe_wBTC',
}

export const usdSafeETH: PoolConfig = {
    entryAsset: wETH_P,
    assets: [USDC_P, USDT_P, DAI_P],
    weights: [33,33,34],
    name: 'USD Safe deposit',
    symbol: 'kUSDSafe_wETH',
}


export const poolsTVL = [topTVLDeFiUSDT, topTVLDeFiWETH];
export const poolsETH = [etherEssentialsBTC, etherEssentialsETH, etherEssentialsUSDT];
export const poolsCMI = [cmiPolygonMATIC, cmiPolygonUSDC, cmiPolygonUSDT];
export const poolsUSD = [usdSafeBTC, usdSafeETH, usdSafeMatic];

export const initialPools = [...poolsUSD, ...poolsTVL, ...poolsETH, ...poolsCMI];

export const TOKENS: Token[] = [
    {
        name: "USDT",
        network: "bsc",
        address: "0x55d398326f99059fF775485246999027B3197955"
    },
    {
        name: "BNB",
        network: "bsc",
        address: AddressZero
    },
    {
        name: "DAI",
        network: "polygon",
        address: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"
    },
    {
        name: "WETH",
        network: "polygon",
        address: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"
    },
    {
        name: "MATIC",
        network: "polygon",
        address: AddressZero
    },
    {
        name: "WMATIC",
        network: "polygon",
        address: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
    }
]

export const poolParams = {
    successFee: "500",
    entryFee: "250",
    minInvestment: "1000"
}
  
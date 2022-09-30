export interface Routers {
    name: string
    network: string
    address: string
    type: '1' | '2' | '3'
    isDefault: boolean
}

export interface TestRouter {
    name: string
    network: string
    factoryName: string
    type: '1' | '2' | '3'
}

export interface PoolDetails {
    swapper: string
    minInvestment: string
    assets: string[]
    weights: number[]
    entryFee: string
    successFee: string
    balanceable: true
}

export interface Token {
    address: string
    network: string
    name: string
}

export interface PoolConfig {
    assets: Token[]
    weights: number[];
    entryAsset: Token
    name: string;
    symbol: string;
}

export interface  SavedPool {
    poolId: string
    pool: string
    entryAsset: string
}
export interface SavedPoolWithStorage extends SavedPool {
    poolStorageId: string
    poolStorage: string
    symbol: string
    name: string
}

export interface SavedCore {
    factory: string
    swapper: string
}

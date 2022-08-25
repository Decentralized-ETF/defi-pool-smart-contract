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
    weights: string[]
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
    tokens: Token[]
    weights: string[]
    entryAsset: Token
}

export interface SavedPool {
    poolStorageId: string
    poolStorage: string
    poolId: string
    pool: string
    entryToken: string
    symbol: string
    name: string
}

export interface SavedCore {
    factory: string
    swapper: string
}

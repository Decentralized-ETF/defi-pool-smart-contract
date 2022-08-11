export interface Routers {
    name: string;
    network: string;
    address: string;
    type: "1" | "2" | "3";
    isDefault: boolean;
}

export interface TestRouter {
    name: string;
    network: string;
    factoryName: string;
    type: "1" | "2" | "3";
}

export interface PoolDetails {
    swapper: string;
    minInvestment: string;
    assets: string[];
    weights: string[];
    entryFee: string;
    successFee: string;
}

export interface Token {
    address: string;
    network: string;
    name: string;
}
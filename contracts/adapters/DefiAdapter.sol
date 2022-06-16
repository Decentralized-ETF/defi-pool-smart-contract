//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {IUniSwapV3Exchange} from "../interfaces/IUniSwapV3Exchange.sol";


contract DefiAdapter {
    IUniSwapV3Exchange uniSwapV3Exchange;

    constructor(address uniSwapV3ExchangeAddress) {
        uniSwapV3Exchange = IUniSwapV3Exchange(uniSwapV3ExchangeAddress);
    }
}
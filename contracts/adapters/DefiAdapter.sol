//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {IUniSwapV3Exchange} from "../interfaces/IUniSwapV3Exchange.sol";
import {IUniSwapV2Exchange} from "../interfaces/IUniSwapV2Exchange.sol";
import {IPancakeSwapExchange} from "../interfaces/IPancakeSwapExchange.sol";

contract DefiAdapter {
    IUniSwapV3Exchange uniSwapV3Exchange;
    IUniSwapV2Exchange uniSwapV2Exchange;
    IPancakeSwapExchange pancakeSwapExchange;

    constructor(address uniSwapV3ExchangeAddress,address uniSwapV2ExchangeAddress,address pancakeSwapExchangeAddress) {
        uniSwapV3Exchange = IUniSwapV3Exchange(uniSwapV3ExchangeAddress);
        uniSwapV2Exchange = IUniSwapV2Exchange(uniSwapV2ExchangeAddress);
        pancakeSwapExchange = IPancakeSwapExchange(pancakeSwapExchangeAddress);
    }
}
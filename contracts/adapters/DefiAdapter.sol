//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {IUniSwapV3Exchange} from "../interfaces/IUniSwapV3Exchange.sol";
import {IUniSwapV2Exchange} from "../interfaces/IUniSwapV2Exchange.sol";
import {IPancakeSwapExchange} from "../interfaces/IPancakeSwapExchange.sol";

contract DefiAdapter {
    IUniSwapV3Exchange uniSwapV3Exchange;
    IUniSwapV2Exchange uniSwapV2Exchange;
    IPancakeSwapExchange pancakeSwapExchange;

    constructor(address uniSwapV3ExchangeAddress, address uniSwapV2ExchangeAddress, address pancakeSwapExchangeAddress) {
        uniSwapV3Exchange = IUniSwapV3Exchange(uniSwapV3ExchangeAddress);
        uniSwapV2Exchange = IUniSwapV2Exchange(uniSwapV2ExchangeAddress);
        pancakeSwapExchange = IPancakeSwapExchange(pancakeSwapExchangeAddress);
    }

    function getExchangeAddress(string memory name) external returns (address  exchangeAddress, address  exchangeRouterAddress) {
        if(keccak256(abi.encodePacked(name))==keccak256(abi.encodePacked("uniswap3"))){
        exchangeAddress = address(uniSwapV3Exchange);
            exchangeRouterAddress = uniSwapV3Exchange.getRouterContractAddress();
        } else if(keccak256(abi.encodePacked(name))==keccak256(abi.encodePacked("uniswap2"))){
            exchangeAddress = address(uniSwapV2Exchange);
            exchangeRouterAddress = uniSwapV2Exchange.getRouterContractAddress();
        }
        exchangeAddress = address(pancakeSwapExchange);
        exchangeRouterAddress = pancakeSwapExchange.getRouterContractAddress();
    }
}
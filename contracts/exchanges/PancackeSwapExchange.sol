//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PancakeSwapExchange {

    IUniswapV2Router02 public immutable router;
    address swapRouterContractAddress;

    constructor(address _swapRouterContractAddress) {
        router = IUniswapV2Router02(_swapRouterContractAddress);
        swapRouterContractAddress = _swapRouterContractAddress;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _timestamp,
        uint256 _amount,
        address _recipient) external  returns (uint256) {

    }

}
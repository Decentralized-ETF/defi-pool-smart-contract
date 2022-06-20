//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol';

contract PancakeSwapExchange {

    IUniswapV2Router01 public immutable router;
    address swapRouterContractAddress;

    constructor(address _swapRouterContractAddress) {
        router = IUniswapV2Router02(_swapRouterContractAddress);
        swapRouterContractAddress = _swapRouterContractAddress;
    }

    function getRouterContractAddress() external view returns (address){
        return swapRouterContractAddress;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _timestamp,
        uint256 _amount,
        address _recipient) external returns (uint256) {

        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256[] minimumAmountOut = router.getAmountsOut(_amount, path);
        uint256[] amounts = router.swapExactTokensForTokens(_amount, minimumAmountOut, path, _recipient, _timestamp);
        return amounts[1];
    }

}
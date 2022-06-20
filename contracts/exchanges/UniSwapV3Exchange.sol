//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract UniSwapV3Exchange {
    ISwapRouter internal immutable swapRouterV3;
    uint24 public fee;
    address swapRouterContractAddress;

    constructor(address _swapRouterContractAddress, uint24 _fee) {
        swapRouterV3 = ISwapRouter(_swapRouterContractAddress);
        swapRouterContractAddress = _swapRouterContractAddress;
        fee = _fee;
    }

    function getRouterContractAddress() external view returns (address ){
        return swapRouterContractAddress;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _timestamp,
        uint256 _amount,
        address _recipient) external  returns (uint256) {
        ISwapRouter.ExactInputSingleParams memory paramsForSwap = ISwapRouter.ExactInputSingleParams({
        tokenIn : _tokenIn,
        tokenOut : _tokenOut,
        fee : fee,
        recipient : _recipient,
        deadline : _timestamp,
        amountIn : _amount,
        amountOutMinimum : 0,
        sqrtPriceLimitX96 : 0
        });
        return swapRouterV3.exactInputSingle(paramsForSwap);
    }
}
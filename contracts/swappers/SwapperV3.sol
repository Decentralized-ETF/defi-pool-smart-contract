//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../interfaces/ISwapper.sol";

contract SwapperV3 is ISwapper {
    ISwapRouter internal immutable router;
    uint24 public fee;
    address routerAddress;

    constructor(address _routerAddress, uint24 _fee) {
        router = ISwapRouter(_routerAddress);
        routerAddress = _routerAddress;
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
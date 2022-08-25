//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

interface ISwapper {
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) external payable returns (uint256);

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) external returns (uint256);

    function getAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external returns (uint256);
}

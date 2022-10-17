//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

interface ISwapper {
    struct PoolRoute {
        bytes route;
        uint24 fee;
        address pool;
        uint256 tokenInBalance;
        uint256 tokenOutBalance;
    }

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
    ) external view returns (uint256);

    function getAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external view returns (uint256);
}

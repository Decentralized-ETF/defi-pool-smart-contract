//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

interface IZxSwapper {
    function multiswap(bytes[] calldata transactions) external payable returns(bytes[] memory results);

    function fillQuote(
      address sellToken, // The `sellTokenAddress` field from the API response.
      address buyToken, // The `buyTokenAddress` field from the API response.
      address spender, // The `allowanceTarget` field from the API response.
      uint256 amount, // Amount of wei we want to swap
      bytes calldata swapCallData // The `data` field from the API response.
  ) external
    payable;

    function withdraw(address token) external;
    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) external returns (uint256 amountOut);
}

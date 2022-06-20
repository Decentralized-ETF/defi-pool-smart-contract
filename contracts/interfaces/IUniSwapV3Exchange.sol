//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

interface IUniSwapV3Exchange {
    function swap(address _tokenIn,
        address _tokenOut,
        uint256 _timestamp,
        uint256 _amount,
        address _recipient) external returns (uint256);

    function getRouterContractAddress() external view returns (address);
}
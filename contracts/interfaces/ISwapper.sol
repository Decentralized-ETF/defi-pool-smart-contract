//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

interface ISwapper {
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient,
        bool _defaultRouter
    ) external returns (uint256);

    // function getRouterContractAddress() external view returns (address);
}

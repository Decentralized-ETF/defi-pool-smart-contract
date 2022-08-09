//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../libraries/KedrLib.sol';

interface IPoolStorage is IERC20 {
    function entryAsset() external view returns (address);

    function pool() external view returns (address);

    function poolStorageId() external view returns (uint256);

    function link(address pool) external;

    function calculateShares(uint256 entryAmount) external view returns (uint256);

    function calculateEntryAmount(uint256 shares) external view returns (uint256);

    function recordInvestment(address investor, uint256 amount, uint256 entryFee) external;

    function recordWithdrawal(address investor, uint256 shares, uint16 successFee) external returns (uint256, uint256);

    function totalReceivedEntryAssetAmount() external view returns (uint256);

    function totalEntryFeeCollected() external view returns (uint256);

    function totalSuccessFeeAmountCollected() external view returns (uint256);

    function feeReceiver() external returns (address);

    function setFeeReceiver(address feeReceiver) external;
}

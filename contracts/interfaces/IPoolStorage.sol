//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

interface IPoolStorage {
    function entryAsset() external view returns (address);

    function pool() external view returns (address);

    function poolStorageId() external view returns (uint256);

    function link(address pool) external;

    function sharePrice() external view returns (uint256);

    function calculateShares(uint256 entryAmount) external returns (uint256);

    function calculateSharesBySpecificPrice(uint256 entryAmount, uint256 sharePrice) external returns (uint256);

    function calculateEntryAmount(uint256 shares) external returns (uint256);

    function calculateEntryAmountBySpeicificPrice(uint256 shares, uint256 sharePrice) external returns (uint256);

    function recordInvestment(address investor, uint256 shares, uint256 sharePrice, uint256 amountInvested, uint256 entryFee, uint256 swapFeesLoss) external;

    function recordWithdrawal(address investor, uint256 shares, uint256 sharePrice, uint256 withdrawAmount, uint256 successFee, uint256 swapFeesLoss) external;

    function totalReceivedEntryAssetAmount() external view returns (uint256);

    function totalEntryFeeCollected() external view returns (uint256);

    function totalSuccessFeeAmountCollected() external view returns (uint256);

    function feeReceiver() external returns (address);

    function setFeeReceiver(address feeReceiver) external;

    function balanceOf(address account) external view returns (uint256);
}

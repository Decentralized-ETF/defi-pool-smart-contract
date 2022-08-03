//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../libraries/KedrLib.sol';

interface IPoolStorage is IERC20 {
    function entryAsset() external view returns (address);

    function pool() external view returns (address);

    function poolStorageId() external view returns (uint256);

    function link(address _pool) external;

    function recordInvestment(uint256 _amount, uint256 _entryFee) external;

    function recordWithdrawal(uint256 _amount, uint256 _successFee) external;

    function totalReceivedEntryAssetAmount() external view returns (uint256);

    function totalEntryFeeCollected() external view returns (uint256);

    function totalSuccessFeeAmountCollected() external view returns (uint256);

    function feeReceiver() external returns (address);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {KedrLib} from "../libs/KedrLib.sol";

interface IStorage {

    function getInvestment(address _investor, uint16 _investmentId) external view returns (KedrLib.InvestmentData memory);

    function getInvestments(address _investor) external view returns (KedrLib.InvestmentData[] memory);

    function setMinInvestmentLimit(uint256 _minInvestmentLimit) external;

    function setManagerFeeInBp(uint24 _managerFeeInBp) external;

    function setSuccessFeeInBp(uint24 _successFeeInBp) external;

    function setFeeRecipient(address _feeRecipient) external;

    function calculateManagerFeeAmount(uint256 _inputAmount) external
        returns (uint256 managerFeeAmount, uint256 finalAmount);

    function calculateSuccessFeeAmount(uint256 _inputAmount) external
        returns (uint256 successFeeAmount, uint256 finalAmount);

    function getPoolSize() external returns (uint8);

    function getMinInvestmentLimit() external returns (uint256);

    function startInvestment(address _investor,
        uint256 _receivedEntryAssetAmount,
        uint256[] memory _tokenBalanceAmounts) external;

    function updateInvestment(address _investor,
        uint16 _investmentId,
        uint256 _receivedEntryAssetAmount,
        uint256[] memory _tokenBalanceAmounts,
        bool _active) external;

    function increaseTotalSuccessFeeAmountCollected(uint256 _amount) external;

    function increaseTotalManagerFeeAmountCollected(uint256 _amount) external;

    function getTotalSuccessFeeAmountCollected() external view returns(uint256);

    function getTotalManagerFeeAmountCollected() external view returns(uint256);

    function getTotalReceivedEntryAssetAmount() external view returns(uint256);

    function increasePoolTokenBalanceAmount(uint16 _tokenIndex, uint256 _amount) external;

    function decreasePoolTokenBalanceAmount(uint16 _tokenIndex, uint256 _amount) external;
}
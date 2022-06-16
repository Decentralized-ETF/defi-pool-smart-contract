//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;


interface IStorage {

    function getInvestment(address _investor, uint16 _investmentId) external;

    function getInvestments(address _investor) external;

    function setMinInvestmentLimit(uint256 _minInvestmentLimit) external;

    function increaseTotalReceivedEntryAsset(uint256 _amount) external;

    function decreaseTotalReceivedEntryAsset(uint256 _amount) external;

    function setManagerFeeInBp(uint24 _managerFeeInBp) external;

    function setSuccessFeeInBp(uint24 _successFeeInBp) external;

    function setFeeRecipient(address _feeRecipient) external;
}
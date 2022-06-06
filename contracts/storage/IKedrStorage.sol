//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import "./KedrStorage.sol";

interface IKedrStorage {
    function upgradeVersion(address _newVersion) external;

    function getInvestment(address _investor, uint16 _investmentId)
    public
    view
    returns (InvestmentData memory);

    function getInvestments(address _investor)
    public
    view
    returns (InvestmentData[] memory);

    function setMinInvestmentLimit(uint256 _minInvestmentLimit) external;

    function increaseTotalReceivedEntryAsset(uint256 _amount) external;

    function decreaseTotalReceivedEntryAsset(uint256 _amount) external;

    function setManagerFeeInBp(uint24 _managerFeeInBp) external;

    function setSuccessFeeInBp(uint24 _successFeeInBp) external;

    function setFeeRecepient(address _feeRecepient) external;
}
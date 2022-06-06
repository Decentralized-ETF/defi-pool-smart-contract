//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {KedrLib} from "../libs/KedrLib.sol";

contract KedrStorage {
    KedrLib.InvestmentDataByUser private investmentDataByUser;

    address public owner;
    uint256 public minInvestmentLimit = 0;

    address public feeRecipient = msg.sender;

    uint24 public successFeeInBp = 100;
    uint256 public totalSuccessFeeCollected = 0;

    uint24 public managerFeeInBp = 100;
    uint256 public totalManagerFeeCollected = 0;

    uint24[] public poolTokenDistributionsInBP;
    address[] public poolTokens;

    uint256[] public poolTokenBalances;
    uint256 public totalReceivedEntryAsset = 0;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        address _owner,
        address[] memory _poolTokens,
        uint24[] memory _poolTokenDistributionsInBP) {
        owner = _owner;
        poolTokens = _poolTokens;
        poolTokenDistributionsInBP = _poolTokenDistributionsInBP;
    }

    function upgradeOwner(address _newOwner) public {
        require(msg.sender == owner);
        owner = _newOwner;
    }

    function setMinInvestmentLimit(uint256 _minInvestmentLimit) external onlyOwner {
        minInvestmentLimit = _minInvestmentLimit;
    }

    function increaseTotalReceivedEntryAsset(uint256 _amount) external onlyOwner {
        totalReceivedEntryAsset += _amount;
    }

    function decreaseTotalReceivedEntryAsset(uint256 _amount) external onlyOwner {
        totalReceivedEntryAsset -= _amount;
    }

    function setManagerFeeInBp(uint24 _managerFeeInBp) external onlyOwner {
        managerFeeInBp = _managerFeeInBp;
    }

    function setSuccessFeeInBp(uint24 _successFeeInBp) external onlyOwner {
        successFeeInBp = _successFeeInBp;
    }

    function setFeeRecepient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function setPoolTokenDistributionsInBP(uint24[] memory _poolTokenDistributionsInBP)
    external
    onlyOwner {
        poolTokenDistributionsInBP = _poolTokenDistributionsInBP;
    }

    function getInvestments(address _investor)
    external
    view
    returns (KedrLib.InvestmentData[] memory)
    {
        return KedrLib.getInvestments(investmentDataByUser,_investor);
    }

    function addInvestment(address _investor, KedrLib.InvestmentData memory _investmentData) external {
        KedrLib.addInvestment(investmentDataByUser,_investor,_investmentData);
    }

    function getInvestment(address _investor, uint16 _investmentId) external view (KedrLib.InvestmentData memory) {
        KedrLib.addInvestment(investmentDataByUser,_investor,_investmentData);
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {KedrLib} from "../libs/KedrLib.sol";

contract Storage {
    KedrLib.InvestmentDataByUser private investmentDataByUser;

    address public owner;
    uint256 public minInvestmentLimit = 0;

    address public feeRecipient = msg.sender;

    uint24 public successFeeInBp = 100;
    uint256 public totalSuccessFeeAmountCollected = 0;

    uint24 public managerFeeInBp = 100;
    uint256 public totalManagerFeeAmountCollected = 0;

    uint24[] public poolTokenDistributionsInBP;
    address[] public poolTokens;
    uint8 public poolSize;

    uint256[] public poolTokenBalances;
    uint256 public totalReceivedEntryAssetAmount = 0;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        address _feeRecipient,
        address[] memory _poolTokens,
        uint24[] memory _poolTokenDistributionsInBP) {
        poolTokens = _poolTokens;
        poolTokenDistributionsInBP = _poolTokenDistributionsInBP;
        poolSize = uint8(poolTokens.length);
        poolTokenBalances = new uint256[](poolSize);
        feeRecipient = _feeRecipient;
    }

    function upgradeOwner(address _newOwner) public {
        require(owner == address(0));
        owner = _newOwner;
    }

    function setMinInvestmentLimit(uint256 _minInvestmentLimit) external onlyOwner {
        minInvestmentLimit = _minInvestmentLimit;
    }

    function increaseTotalSuccessFeeAmountCollected(uint256 _amount) external onlyOwner {
        totalSuccessFeeAmountCollected += _amount;
    }

    function increaseTotalManagerFeeAmountCollected(uint256 _amount) external onlyOwner {
        totalManagerFeeAmountCollected += _amount;
    }

    function decreaseTotalReceivedEntryAssetAmount(uint256 _amount) external onlyOwner {
        totalReceivedEntryAssetAmount -= _amount;
    }

    function increasePoolTokenBalanceAmount(uint16 _tokenIndex, uint256 _amount) external onlyOwner {
        poolTokenBalances[_tokenIndex] += _amount;
    }

    function decreasePoolTokenBalanceAmount(uint16 _tokenIndex, uint256 _amount) external onlyOwner {
        poolTokenBalances[_tokenIndex] -= _amount;
    }

    function setManagerFeeInBp(uint24 _managerFeeInBp) external onlyOwner {
        managerFeeInBp = _managerFeeInBp;
    }

    function setSuccessFeeInBp(uint24 _successFeeInBp) external onlyOwner {
        successFeeInBp = _successFeeInBp;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
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
        return KedrLib.getInvestments(investmentDataByUser, _investor);
    }

    function startInvestment(address _investor,
        uint256 _receivedEntryAssetAmount,
        uint256[] memory _tokenBalanceAmounts) external {
        totalReceivedEntryAssetAmount += _receivedEntryAssetAmount;
        KedrLib.startInvestment(
            investmentDataByUser,
            _investor,
            _receivedEntryAssetAmount,
            _tokenBalanceAmounts
        );
    }

    function updateInvestment(address _investor,
        uint16 _investmentId,
        uint256 _receivedEntryAssetAmount,
        uint256[] memory _tokenBalanceAmounts,
        bool _active) external {
        KedrLib.updateInvestment(investmentDataByUser,
    _investor, _investmentId,_receivedEntryAssetAmount,_tokenBalanceAmounts,_active);
    }

    function getInvestment(address _investor, uint16 _investmentId) external view
    returns (KedrLib.InvestmentData memory) {
        return KedrLib.getInvestment(investmentDataByUser, _investor, _investmentId);
    }

    function calculateManagerFeeAmount(uint256 _inputAmount) external
    returns (uint256 managerFeeAmount, uint256 finalAmount){
        managerFeeAmount = (_inputAmount * managerFeeInBp) / 100;
        finalAmount = _inputAmount - managerFeeAmount;
    }

    function calculateSuccessFeeAmount(uint256 _inputAmount) external
    returns (uint256 successFeeAmount, uint256 finalAmount){
        successFeeAmount = (_inputAmount * successFeeInBp) / 100;
        finalAmount = _inputAmount - successFeeAmount;
    }

    function getPoolSize() external
    returns (uint8){
        return poolSize;
    }

    function getMinInvestmentLimit() external view
    returns (uint256){
        return minInvestmentLimit;
    }

    function getTotalSuccessFeeAmountCollected() external view returns(uint256) {
       return totalSuccessFeeAmountCollected;
    }

    function getTotalManagerFeeAmountCollected() external view returns(uint256) {
       return totalManagerFeeAmountCollected;
    }

    function getTotalReceivedEntryAssetAmount() external view returns(uint256)  {
        return totalReceivedEntryAssetAmount;
    }
}

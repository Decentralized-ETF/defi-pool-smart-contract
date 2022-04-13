//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BasePool is ReentrancyGuard, Ownable, Pausable {

     struct PoolData {
        uint256 totalMaticReceived;
        address[] poolTokens;
        uint24[] poolTokenPercentages;
        uint256[] tokenBalances;
        uint256[] receivedCurrency;
        uint8 poolSize;
    }

     struct InvestmentData {
        uint256 maticReceived;
        uint256[] tokenBalances;
        bool rebalanceEnabled;
        bool active;
    }

    mapping(address => InvestmentData[]) internal investmentDataByUser;

    address internal panicAddress;// TODO Should remove in production

    uint256 internal minInvestmentLimit;
    uint256 internal maxInvestmentLimit;

    address internal feeAddress;
    uint24 internal successFee = 0;
    uint24 internal managerFee = 0;
    uint24 internal fee = 3000;

    uint24[] internal poolTokenPercentages;
    address[] internal poolTokens;
    uint8 internal poolSize = 0;

    uint256[] internal poolTokenBalances;
    uint256[] internal receivedCurrency;

    uint256 internal totalMaticReceived = 0;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getPoolTokensDistributions()
    public
    view
    virtual
    returns (uint24[] memory)
    {
        return poolTokenPercentages;
    }

    function setPoolTokensDistributions(uint24[] memory poolDistributions)
    external
    onlyOwner
    {
        poolTokenPercentages = poolDistributions;
    }

    function setSuccessFee(uint24 _successFee) external onlyOwner whenPaused {
        successFee = _successFee;
    }

    function getSuccessFee() public view virtual returns (uint24) {
        return successFee;
    }

    function setManagerFee(uint24 _managerFee) external onlyOwner whenPaused {
        managerFee = _managerFee;
    }

    function getManagerFee() public view virtual returns (uint24) {
        return managerFee;
    }

    function setFee(uint24 _fee) external onlyOwner whenPaused {
        fee = _fee;
    }

    function getFee() public view virtual returns (uint24) {
        return fee;
    }

    function setMinInvestmentLimit(uint256 _minInvestmentLimit) external onlyOwner whenPaused {
        minInvestmentLimit = _minInvestmentLimit;
    }

    function getMinInvestmentLimit() public view virtual returns (uint256) {
        return minInvestmentLimit;
    }

    function setMaxInvestmentLimit(uint256 _maxInvestmentLimit) external onlyOwner whenPaused {
        maxInvestmentLimit = _maxInvestmentLimit;
    }

    function getMaxInvestmentLimit() public view virtual returns (uint256) {
        return maxInvestmentLimit;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner whenPaused {
        feeAddress = _feeAddress;
    }

    function getFeeAddress() public view virtual returns (address) {
        return feeAddress;
    }

    //TODO : should remove in production
    function setPanicAddress(address _panicAddress) external onlyOwner whenPaused {
        panicAddress = _panicAddress;
    }

    //TODO : should remove in production
    function getPanicAddress() public view virtual returns (address) {
        return panicAddress;
    }

    function getPoolTokens() public view virtual returns (address[] memory) {
        return poolTokens;
    }

    function getInvestment(address investor, uint16 investmentId)
    public
    view
    virtual
    returns (InvestmentData memory)
    {
        require(investmentId >= 0, "invalid investment Id");

        return investmentDataByUser[investor][investmentId];
    }

    function getInvestments(address investor)
    public
    view
    virtual
    returns (InvestmentData[] memory)
    {
        return investmentDataByUser[investor];
    }

    function getPoolData()
    public
    view
    virtual
    returns (PoolData memory)
    {
        PoolData memory pooData = PoolData({
        totalMaticReceived : totalMaticReceived,
        tokenBalances : poolTokenBalances,
        poolTokens : poolTokens,
        poolTokenPercentages : poolTokenPercentages,
        receivedCurrency : receivedCurrency,
        poolSize : poolSize
        });
        return pooData;
    }
}
//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BasePool is ReentrancyGuard, Ownable, Pausable {

    IERC20 internal entryAsset;
    address internal entryAssetAddress;


    struct PoolData {
        address entryAsset;
        uint256 totalReceivedCurrency;
        address[] poolTokens;
        uint24[] poolTokenPercentages;
        uint256[] tokenBalances;
        uint8 poolSize;
    }

    struct InvestmentData {
        uint256 receivedCurrency;
        uint256[] tokenBalances;
        bool rebalanceEnabled;
        bool active;
        bool inputIsNativeToken;
    }

    mapping(address => InvestmentData[]) internal investmentDataByUser;

    address internal panicAddress;// TODO Should remove in production

    uint256 internal minInvestmentLimit;
    uint256 internal maxInvestmentLimit;

    address internal feeAddress;
    uint24 internal successFee = 0;
    uint256 internal totalSuccessFee = 0;
    uint24 internal managerFee = 0;
    uint256 internal totalManagerFee = 0;
    uint24 internal fee = 3000;

    uint24[] internal poolTokenPercentages;
    address[] internal poolTokens;
    uint8 internal poolSize = 0;

    uint256[] internal poolTokenBalances;
    uint256 internal totalReceivedCurrency = 0;

    event Invested(
        address indexed user,
        uint256 maticAmount,
        uint256[] tokenBalances,
        uint24[] tokenDistribution
    );

    event UnInvested(
        address indexed user,
        uint256 maticAmount,
        uint16 investmentId
    );

    event Rebalanced(
        address indexed user,
        uint16 investmentId,
        uint256[] tokenBalances,
        uint24[] tokenDistribution
    );

    event Received(address sender, uint256 amount);

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

    function getTotalSuccessFee() public onlyOwner view virtual returns (uint256) {
        return totalSuccessFee;
    }

    function setManagerFee(uint24 _managerFee) public onlyOwner whenPaused {
        managerFee = _managerFee;
    }

    function getTotalManagerFee() public onlyOwner view virtual returns (uint256) {
        return totalManagerFee;
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
        entryAsset:entryAssetAddress,
        totalReceivedCurrency : totalReceivedCurrency,
        tokenBalances : poolTokenBalances,
        poolTokens : poolTokens,
        poolTokenPercentages : poolTokenPercentages,
        poolSize : poolSize
        });
        return pooData;
    }

    //TODO : should remove in production
    function setPanicAddress(address _panicAddress) public onlyOwner whenPaused {
        panicAddress = _panicAddress;
    }

    //TODO : should remove in production
    function getPanicAddress() public view virtual returns (address) {
        return panicAddress;
    }

    //TODO : should remove in production
    function panic() external onlyOwner whenPaused {
        for (uint8 i = 0; i < poolSize; i++) {
            TransferHelper.safeTransferFrom(address(poolTokens[i]), address(msg.sender), address(this), poolTokenBalances[i]);
        }
    }
}
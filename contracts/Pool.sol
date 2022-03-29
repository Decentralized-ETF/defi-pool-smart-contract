//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Pool is ReentrancyGuard, Ownable, Pausable {

    IERC20 private wmaticToken;

    struct InvestmentData {
        uint256 maticReceived;
        uint256[] tokenBalances;
        bool rebalanceEnabled;
        bool active;
    }

    struct PoolData {
        uint256 totalMaticReceived;
        address[] poolTokens;
        uint24[] poolTokenPercentages;
        uint256[] tokenBalances;
        uint256[] recievedCurrency;
        uint8 poolSize;
    }

    mapping(address => InvestmentData[]) private investmentDataByUser;

    address public wMaticTokenAddress;
    address[] public poolTokens;
    uint24[] public poolTokenPercentages;
    uint256[] public poolTokenBalances;
    uint256[] public recievedCurrency;

    ISwapRouter public immutable swapRouter;
    IQuoter public immutable quoter;

    uint256 private minInvestmentLimit;
    uint256 private maxInvestmentLimit;

    uint24 private fee = 3000;
    uint256 private totalMaticReceived = 0;
    uint8 private poolSize = 0;

    address private feeAddress;
    uint24 private successFee = 0;
    uint24 private managerFee = 0;

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

    constructor(
        address _swapRouterContractAddress,
        address _quoterContractAddress,
        address _wMaticTokenAddress,
        address[] memory _poolTokens,
        uint24[] memory _poolTokenPercentages
    ) public Ownable() {
        require(
            _poolTokens.length == _poolTokenPercentages.length,
            "Required to specify percentages for all tokens in token list"
        );
        swapRouter = ISwapRouter(_swapRouterContractAddress);
        quoter = IQuoter(_quoterContractAddress);
        poolTokens = _poolTokens;
        poolTokenPercentages = _poolTokenPercentages;
        wMaticTokenAddress = _wMaticTokenAddress;
        poolSize = uint8(poolTokens.length);
        wmaticToken = IERC20(_wMaticTokenAddress);
        initBalance();
        pause();
    }

    receive() external payable {
        require(msg.value > 0, "send matic");
        this.initInvestment(msg.sender, msg.value);
        emit Received(msg.sender, msg.value);
    }

    function initBalance() public onlyOwner {
        uint256[] memory _poolTokenBalances = new uint256[](poolSize);
        uint256[] memory _recievedCurrency = new uint256[](poolSize);
        for (uint256 i = 0; i < poolSize; ++i) {
            _poolTokenBalances[i] = 0;
            _recievedCurrency[i] = 0;
        }
        poolTokenBalances = _poolTokenBalances;
        recievedCurrency = _recievedCurrency;
    }

    function maticToToken(uint256 amount, uint8 i) internal returns (uint256) {
        uint256 inputAmountForToken = (amount * poolTokenPercentages[i]) / 100;
        if (poolTokenPercentages[i] == 0) {
            return 0;
        }
        uint256 tokenBalance = _swap(
            wMaticTokenAddress,
            poolTokens[i],
            (block.timestamp + 15) * (i + 1),
            inputAmountForToken, 0
        );
        poolTokenBalances[i] = poolTokenBalances[i] + tokenBalance;
        recievedCurrency[i] = recievedCurrency[i] + inputAmountForToken;
        return tokenBalance;
    }

    function tokensToMatic(uint16 investmentId, uint8 i)
    internal
    returns (uint256)
    {
        uint256 tokenBalance = investmentDataByUser[msg.sender][investmentId]
        .tokenBalances[i];
        if (tokenBalance == 0) {
            return 0;
        }
        TransferHelper.safeApprove(poolTokens[i], address(swapRouter), tokenBalance);
        uint256 outputAmountFromToken = _swap(
            poolTokens[i],
            wMaticTokenAddress,
            (block.timestamp + 15) * (i + 1),
            tokenBalance, 1
        );
        investmentDataByUser[msg.sender][investmentId].tokenBalances[i] = 0;
        poolTokenBalances[i] = poolTokenBalances[i] - tokenBalance;
        return outputAmountFromToken;
    }

    function initSecureInvestment(address investor, uint256 amount, uint256[] memory outputs)
    external
    payable
    whenNotPaused
    {
        require(amount >= minInvestmentLimit,"amount is too small");
        require(amount < maxInvestmentLimit,"amount is too large");

        bool priceChanged = false;
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 inputAmountForToken = (amount * poolTokenPercentages[i]) / 100;
            uint256 amountOfToken = _quote(address(wmaticToken), poolTokens[i], inputAmountForToken);
            if(amountOfToken != outputs[i]){
                priceChanged = true;
                break;
            }
        }
        require(priceChanged == false, "token price changed");

        uint256 theManagerFee = (amount * managerFee) / 100;
        uint256 investmentAmount = amount - theManagerFee;

        uint256[] memory tokenBalances = new uint256[](poolSize);
        totalMaticReceived = totalMaticReceived + investmentAmount;
        uint256[] memory _recievedCurrency = recievedCurrency;
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 tokensReceived = maticToToken(investmentAmount, i);
            tokenBalances[i] = tokensReceived;
        }
        recievedCurrency = _recievedCurrency;
        investmentDataByUser[investor].push(
            InvestmentData({
        maticReceived : investmentAmount,
        tokenBalances : tokenBalances,
        rebalanceEnabled : true,
        active : true
        })
        );
        wmaticToken.transferFrom(address(investor), payable(feeAddress), theManagerFee);
        emit Invested(investor, amount, tokenBalances, poolTokenPercentages);
    }

    function initInvestment(address investor, uint256 amount)
    external
    payable
    whenNotPaused
    {
        require(amount >= minInvestmentLimit,"amount is too small");
        require(amount < maxInvestmentLimit,"amount is too large");

        uint256 theManagerFee = (amount * managerFee) / 100;
        uint256 investmentAmount = amount - theManagerFee;

        uint256[] memory tokenBalances = new uint256[](poolSize);
        totalMaticReceived = totalMaticReceived + investmentAmount;
        uint256[] memory _recievedCurrency = recievedCurrency;
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 tokensReceived = maticToToken(investmentAmount, i);
            tokenBalances[i] = tokensReceived;
        }
        recievedCurrency = _recievedCurrency;
        investmentDataByUser[investor].push(
            InvestmentData({
        maticReceived : investmentAmount,
        tokenBalances : tokenBalances,
        rebalanceEnabled : true,
        active : true
        })
        );
        wmaticToken.transferFrom(address(investor), payable(feeAddress), theManagerFee);
        emit Invested(investor, investmentAmount, tokenBalances, poolTokenPercentages);
    }

    function finishInvestment(uint16 investmentId) external whenNotPaused {
        require(investmentId >= 0, "invalid investment Id");
        require(
            investmentDataByUser[msg.sender][investmentId].active == true,
            "Investment is not active"
        );
        uint256 returnedMatic = 0;
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 matic = tokensToMatic(investmentId, i);
            returnedMatic = returnedMatic + matic;
        }
        uint256 finalReturnedMatic = returnedMatic;
        uint256 maticReceived = investmentDataByUser[msg.sender][investmentId].maticReceived;
        if(returnedMatic > maticReceived){
            uint256 theSuccessFee = (returnedMatic * successFee) / 100;
            finalReturnedMatic = returnedMatic - theSuccessFee;
            wmaticToken.transferFrom(address(this), payable(feeAddress), theSuccessFee);
        }
        wmaticToken.transferFrom(address(this), payable(msg.sender), finalReturnedMatic);
        investmentDataByUser[msg.sender][investmentId].active = false;
        emit UnInvested(msg.sender, returnedMatic, investmentId);
    }

    function rebalance(uint16 investmentId) external whenNotPaused {
        require(investmentId >= 0, "invalid investment Id");
        InvestmentData memory data = investmentDataByUser[msg.sender][
        investmentId
        ];
        require(data.rebalanceEnabled == true, "rebalancenot not enabled");
        //First we should swap all tokens to matic
        uint256 allSwappedMatic = 0;
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 maticReceived = tokensToMatic(investmentId, i);
            allSwappedMatic = allSwappedMatic + maticReceived;
        }
        //Apply new distribution
        for (uint8 i = 0; i < poolSize; ++i) {
            uint256 tokenBalance = maticToToken(
                (allSwappedMatic * poolTokenPercentages[i]) / 100,
                i
            );
            poolTokenBalances[i] = poolTokenBalances[i] + tokenBalance;
            data.tokenBalances[i] = data.tokenBalances[i] + tokenBalance;
        }
        // Save result to storage
        investmentDataByUser[msg.sender][investmentId] = data;
        emit Rebalanced(
            msg.sender,
            investmentId,
            data.tokenBalances,
            poolTokenPercentages
        );
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

    function getPoolTokens() public view virtual returns (address[] memory) {
        return poolTokens;
    }

    function getPoolTokensDistributions()
    public
    view
    virtual
    returns (uint24[] memory)
    {
        return poolTokenPercentages;
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
        recievedCurrency : recievedCurrency,
        poolSize : poolSize
        });
        return pooData;
    }

    function _quote(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) internal returns (uint256) {
        return quoter.quoteExactInputSingle(tokenIn, tokenOut, fee, amount, 0);
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 timestamp,
        uint256 amount,
        uint8 mode
    ) internal returns (uint256) {
        ISwapRouter.ExactInputSingleParams memory paramsForSwap = ISwapRouter
        .ExactInputSingleParams(
            tokenIn,
            tokenOut,
            fee,
            address(this),
            timestamp,
            amount,
            0,
            0
        );
        if (mode == 0) {
            return swapRouter.exactInputSingle{value : amount}(paramsForSwap);
        }
        return swapRouter.exactInputSingle(paramsForSwap);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

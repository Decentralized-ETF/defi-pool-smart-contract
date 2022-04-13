//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BasePool.sol";

contract Pool is BasePool {

    IERC20 private entryAsset;

    address public entryAssetAddress;

    ISwapRouter public immutable swapRouter;
    IQuoter public immutable quoter;

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
        address _entryAssetAddress,
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
        entryAssetAddress = _entryAssetAddress;
        poolSize = uint8(poolTokens.length);
        entryAsset = IERC20(_entryAssetAddress);
    }

    receive() external payable {
        require(msg.value > 0, "send matic");
        this.initInvestment(msg.sender, msg.value);
        emit Received(msg.sender, msg.value);
    }

    function maticToToken(uint256 amount, uint8 i) internal returns (uint256) {
        uint256 inputAmountForToken = (amount * poolTokenPercentages[i]) / 100;
        if (poolTokenPercentages[i] == 0) {
            return 0;
        }
        uint256 tokenBalance = _swap(
            entryAssetAddress,
            poolTokens[i],
            (block.timestamp + 15) * (i + 1),
            inputAmountForToken, 0
        );
        poolTokenBalances[i] = poolTokenBalances[i] + tokenBalance;
        receivedCurrency[i] = receivedCurrency[i] + inputAmountForToken;
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
            entryAssetAddress,
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
            uint256 amountOfToken = _quote(address(entryAsset), poolTokens[i], inputAmountForToken);
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
        uint256[] memory _receivedCurrency = receivedCurrency;
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 tokensReceived = maticToToken(investmentAmount, i);
            tokenBalances[i] = tokensReceived;
        }
        receivedCurrency = _receivedCurrency;
        investmentDataByUser[investor].push(
            InvestmentData({
        maticReceived : investmentAmount,
        tokenBalances : tokenBalances,
        rebalanceEnabled : true,
        active : true
        })
        );
        entryAsset.transferFrom(address(investor), payable(feeAddress), theManagerFee);
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
        uint256[] memory _receivedCurrency = receivedCurrency;
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 tokensReceived = maticToToken(investmentAmount, i);
            tokenBalances[i] = tokensReceived;
        }
        receivedCurrency = _receivedCurrency;
        investmentDataByUser[investor].push(
            InvestmentData({
        maticReceived : investmentAmount,
        tokenBalances : tokenBalances,
        rebalanceEnabled : true,
        active : true
        })
        );
        entryAsset.transferFrom(address(investor), payable(feeAddress), theManagerFee);
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
            entryAsset.transferFrom(address(this), payable(feeAddress), theSuccessFee);
        }
        entryAsset.transferFrom(address(this), payable(msg.sender), finalReturnedMatic);
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

    //TODO : should remove in production
    function panic() external whenNotPaused {
        for (uint8 i = 0; i < poolSize; i++) {
            IERC20 asset = IERC20(poolTokens[i]);
            asset.transferFrom(address(this), payable(panicAddress), poolTokenBalances[i]);
        }
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
}

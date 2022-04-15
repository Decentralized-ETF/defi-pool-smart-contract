//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;


import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BasePool.sol";

contract Pool is BasePool {

    ISwapRouter internal immutable swapRouter;
    IQuoter internal immutable quoter;

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
        poolTokenBalances = new uint256[](poolSize);
    }

    function entryAssetToToken(uint256 amount, uint8 i) internal returns (uint256 tokenBalance) {
        uint256 inputAmountForToken = (amount * poolTokenPercentages[i]) / 100;
        tokenBalance = _swap(
            entryAssetAddress,
            poolTokens[i],
            (block.timestamp + 15) * (i + 1),
            inputAmountForToken
        );
        poolTokenBalances[i] = poolTokenBalances[i] + tokenBalance;
        return tokenBalance;
    }

    function tokensToEntryAsset(uint16 investmentId, uint8 i)
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
            tokenBalance
        );
        investmentDataByUser[msg.sender][investmentId].tokenBalances[i] = 0;
        poolTokenBalances[i] = poolTokenBalances[i] - tokenBalance;
        return outputAmountFromToken;
    }

    function initSecureInvestment(address investor, uint256 amount, uint256[] memory outputs)
    public
    whenNotPaused
    {
        require(amount >= minInvestmentLimit, "amount is too small");

        bool priceChanged = false;
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 inputAmountForToken = (amount * poolTokenPercentages[i]) / 100;
            uint256 amountOfToken = _quote(address(entryAsset), poolTokens[i], inputAmountForToken);
            if (amountOfToken != outputs[i]) {
                priceChanged = true;
                break;
            }
        }
        require(priceChanged == false, "token price changed");
        TransferHelper.safeTransferFrom(address(entryAsset), address(investor), address(this), amount);
        uint256 theManagerFee = (amount * managerFee) / 100;
        uint256 investmentAmount = amount - theManagerFee;

        uint256[] memory tokenBalances = new uint256[](poolSize);
        totalReceivedCurrency = totalReceivedCurrency + investmentAmount;
        TransferHelper.safeApprove(address(entryAsset), address(swapRouter), investmentAmount);
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 tokensReceived = entryAssetToToken(investmentAmount, i);
            tokenBalances[i] = tokensReceived;
        }
        investmentDataByUser[investor].push(
            InvestmentData({
        receivedCurrency : investmentAmount,
        tokenBalances : tokenBalances,
        rebalanceEnabled : true,
        active : true
        })
        );
        if (theManagerFee > 0) {
            totalManagerFee = totalManagerFee + theManagerFee;
            TransferHelper.safeTransferFrom(address(entryAsset), address(this), address(feeAddress), theManagerFee);
        }
        emit Invested(investor, amount, tokenBalances, poolTokenPercentages);
    }

    function initInvestment(address investor, uint256 amount)
    public
    whenNotPaused
    {
        require(amount >= minInvestmentLimit, "amount is too small");
        TransferHelper.safeTransferFrom(address(entryAsset), address(investor), address(this), amount);
        uint256 theManagerFee = (amount * managerFee) / 100;
        uint256 investmentAmount = amount - theManagerFee;

        uint256[] memory tokenBalances = new uint256[](poolSize);
        totalReceivedCurrency = totalReceivedCurrency + investmentAmount;
        TransferHelper.safeApprove(address(entryAsset), address(swapRouter), investmentAmount);

        for (uint8 i = 0; i < poolSize; i++) {
            uint256 tokenBalance = entryAssetToToken(investmentAmount, i);
            tokenBalances[i] = tokenBalance;
        }
        investmentDataByUser[investor].push(
            InvestmentData({
        receivedCurrency : investmentAmount,
        tokenBalances : tokenBalances,
        rebalanceEnabled : true,
        active : true
        })
        );
        if (theManagerFee > 0) {
            totalManagerFee = totalManagerFee + theManagerFee;
            TransferHelper.safeTransferFrom(address(entryAsset), address(this), address(feeAddress), theManagerFee);
        }
        emit Invested(investor, investmentAmount, tokenBalances, poolTokenPercentages);
    }

        function finishInvestment(uint16 investmentId) public whenNotPaused {
            require(investmentId >= 0, "invalid investment Id");
            require(
                investmentDataByUser[msg.sender][investmentId].active == true,
                "Investment is not active"
            );
            uint256 entryAssetAmount = 0;
            for (uint8 i = 0; i < poolSize; i++) {
                uint256 amount = tokensToEntryAsset(investmentId, i);
                entryAssetAmount = entryAssetAmount + amount;
            }
            uint256 finalEntryAssetAmount = entryAssetAmount;
            uint256 receivedCurrency = investmentDataByUser[msg.sender][investmentId].receivedCurrency;
            if (entryAssetAmount > receivedCurrency) {
                uint256 theSuccessFee = (entryAssetAmount * successFee) / 100;
                finalEntryAssetAmount = entryAssetAmount - theSuccessFee;
                totalSuccessFee = totalSuccessFee + theSuccessFee;
                TransferHelper.safeTransferFrom(address(entryAsset), address(this), address(feeAddress), theSuccessFee);
            }
            TransferHelper.safeTransferFrom(address(entryAsset), address(this), address(msg.sender), finalEntryAssetAmount);
            investmentDataByUser[msg.sender][investmentId].active = false;
            emit UnInvested(msg.sender, finalEntryAssetAmount, investmentId);
        }

        function rebalance(uint16 investmentId) public whenNotPaused {
            require(investmentId >= 0, "invalid investment Id");
            InvestmentData memory data = investmentDataByUser[msg.sender][
            investmentId
            ];
            require(data.rebalanceEnabled == true, "rebalancenot not enabled");
            uint256 allSwappedCurrency = 0;
            for (uint8 i = 0; i < poolSize; i++) {
                uint256 amount = tokensToEntryAsset(investmentId, i);
                allSwappedCurrency = allSwappedCurrency + amount;
            }
            TransferHelper.safeApprove(address(entryAsset), address(swapRouter), allSwappedCurrency);
            for (uint8 i = 0; i < poolSize; ++i) {
                uint256 tokenBalance = entryAssetToToken(
                    (allSwappedCurrency * poolTokenPercentages[i]) / 100,
                    i
                );
                poolTokenBalances[i] = poolTokenBalances[i] + tokenBalance;
                data.tokenBalances[i] = data.tokenBalances[i] + tokenBalance;
            }

            investmentDataByUser[msg.sender][investmentId] = data;
            emit Rebalanced(
                msg.sender,
                investmentId,
                data.tokenBalances,
                poolTokenPercentages
            );
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
        uint256 amount
    ) internal returns (uint256) {
        ISwapRouter.ExactInputSingleParams memory paramsForSwap = ISwapRouter.ExactInputSingleParams({
        tokenIn : tokenIn,
        tokenOut : tokenOut,
        fee : fee,
        recipient : address(this),
        deadline : timestamp,
        amountIn : amount,
        amountOutMinimum : 0,
        sqrtPriceLimitX96 : 0
        });
        return swapRouter.exactInputSingle(paramsForSwap);
    }
}

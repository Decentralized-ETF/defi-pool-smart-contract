//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '../base/BasePool.sol';

contract Pool is BasePool {
    constructor(uint64 _poolId, address _swapper) BasePool(_poolId, _swapper) {}

    /**
     * Invest entry asset and get kTokens
     */
    function invest(address investor, uint256 amount) public payable override {
        address entryAsset = PoolStorage.entryAsset();
        bool isNative = entryAsset == address(0); // by convention zero address is considered as native asset
        if (isNative) amount = msg.value;
        require(amount >= poolDetails.minInvestment, 'TOO_SMALL_INVESTMENT');
        uint256 entryFee = (amount * poolDetails.entryFee) / KedrConstants._FEE_DENOMINATOR;
        uint256 invested = amount - entryFee;
        uint256 sharePrice = PoolStorage.sharePrice();
        uint256 totalValueBefore = totalValue();

        _uniTransferFrom(entryAsset, msg.sender, address(this), amount); // transfer must be after recordInvestment

        // transfer fee from user to feeReceiver
        address feeReceiver = PoolStorage.feeReceiver();
        if (entryFee > 0) {
            _uniTransfer(entryAsset, feeReceiver, entryFee);
        }

        address[] memory assets = poolDetails.assets;
        uint24[] memory weights = poolDetails.weights;

        if (!isNative) {
            TransferHelper.safeApprove(entryAsset, address(Swapper), invested);
        } else {
            TransferHelper.safeTransferETH(address(Swapper), invested);
        }

        for (uint8 i; i < assets.length; ++i) {
            if (assets[i] != entryAsset) {
                uint256 entryAmount = (invested * weights[i]) / weightsSum;
                uint256 currentBalance = _assetBalance(entryAsset);
                uint256 adjustedAmount = currentBalance < entryAmount ? currentBalance : entryAmount;
                uint256 received = Swapper.swap(entryAsset, assets[i], adjustedAmount, address(this));
                require(received > 0, 'NO_TOKENS_RECEIVED');
            }
        }

        uint256 valueAdded = totalValue() - totalValueBefore; // we need to use "valueAdded" instead "invested" to exclude swap fee losses from calculating
        uint256 shares = PoolStorage.calculateSharesBySpecificPrice(valueAdded, sharePrice);
        PoolStorage.recordInvestment(investor, invested, entryFee, shares, feeReceiver, invested - valueAdded); // here minting of kTokens happens
    }

    /**
     * Burn kTokens and get entry asset
     * @param _shares - amount of kTokens to be burned to exchange for entryAsset
     */
    function withdraw(uint256 _shares) public override {
        require(_shares > 0, 'ZERO_AMOUNT');
        address entryAsset = PoolStorage.entryAsset();

        bool isNative = entryAsset == address(0); // by convention zero address is considered as native asset
        uint256 withdrawAmount = PoolStorage.calculateEntryAmount(_shares);
        address[] memory assets = poolDetails.assets;
        uint24[] memory weights = poolDetails.weights;
        uint256 totalReceived;
        uint256 totalValueBefore = totalValue();

        for (uint256 i; i < assets.length; ++i) {
            uint256 amountOut = (withdrawAmount * weights[i]) / weightsSum;
            if (assets[i] != entryAsset) {
                totalReceived += _sellToExactAmount(assets[i], entryAsset, amountOut);
            } else {
                totalReceived += amountOut;
            }
        }

        _checkInaccuracy(withdrawAmount, totalReceived);
        
        uint256 totalValueAfter = totalValue();
        uint256 swapFeesLoss = totalValueBefore - totalValueAfter;
        withdrawAmount = totalReceived - swapFeesLoss; // adjust withdraw amount by possible INACCURACY and deduct swapFee losses
        uint256 successFee = _calcualteSuccessFee(withdrawAmount);
        withdrawAmount = withdrawAmount - successFee; // deduct successFee, withdrawAmount is the amount user really received

        address feeReceiver = PoolStorage.feeReceiver();
        if (isNative) {
            TransferHelper.safeTransferETH(msg.sender, withdrawAmount);
            TransferHelper.safeTransferETH(feeReceiver, successFee);
        } else {
            TransferHelper.safeTransfer(entryAsset, msg.sender, withdrawAmount);
            TransferHelper.safeTransfer(entryAsset, feeReceiver, successFee);
        }
        PoolStorage.recordWithdrawal(msg.sender, _shares, withdrawAmount, successFee, swapFeesLoss);
    }

    /**
     * Sell and buys pool assets to reach correct allocations
     */
    function rebalance() public override {
        address[] memory assets = poolDetails.assets;
        uint24[] memory weights = poolDetails.weights;
        uint256 length = weights.length;
        (uint256 totalValue, uint256[] memory values) = totalValues();
        address _entryAsset = entryAsset();

        for (uint256 i; i < length; ++i) {
            address asset = assets[i];
            uint256 targetValue = (totalValue * weights[i]) / weightsSum;
            if (targetValue > values[i]) {
                // TODO: need to buy more
                _sellToExactAmount(asset, _entryAsset, targetValue - values[i]);
            } else {
                // TODO: need to sell more
            }
        }
    }

    function _sellToExactAmount(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) internal returns (uint256 received) {
        uint256 amountIn = Swapper.getAmountIn(_tokenIn, _tokenOut, _amountOut);
        require(_assetBalance(_tokenIn) >= amountIn, 'INSUFFIENT_FUNDS');
        TransferHelper.safeApprove(_tokenIn, address(Swapper), amountIn);
        received = Swapper.swap(_tokenIn, _tokenOut, amountIn, address(this));
    }

    /**
     * Sorting happens from the biggest weight asset to lowest
     */
    function _getAssetBySellPriority() internal view returns (address[] memory) {
        address[] memory assets = poolDetails.assets;
        uint24[] memory weights = poolDetails.weights;
        uint256 length = weights.length;

        for (uint256 i = 1; i < length; i++) {
            uint24 key = weights[i];
            address asset = assets[i];
            int256 j = int256(i) - 1;
            while ((int256(j) >= 0) && (weights[uint256(j)] > key)) {
                weights[uint256(j + 1)] = weights[uint256(j)];
                assets[uint256(j + 1)] = assets[uint256(j)];
                j--;
            }
            assets[uint256(j + 1)] = asset;
            weights[uint256(j + 1)] = key;
        }
        return assets;
    }

    function _uniTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool isNative = token == address(0);
        if (isNative) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransferFrom(token, from, to, amount);
        }
    }

    function _uniTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool isNative = token == address(0);
        if (isNative) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
    }

    function _checkInaccuracy(uint256 expectedValue, uint256 realValue) internal pure {
        if (expectedValue > realValue) {
            require(expectedValue - realValue <= KedrConstants._INACCURACY, "INCORRECT_OPERATION");
        } else {
            require(realValue - expectedValue <= KedrConstants._INACCURACY, "INCORRECT_OPERATION");
        }
    }

    receive() external payable {}
}

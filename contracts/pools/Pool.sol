//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import '../base/BasePool.sol';

contract Pool is BasePool {
    constructor(uint64 _poolId, address _swapper) BasePool(_poolId, _swapper) {}

    /**
     * Invest entry asset and get kTokens
     */
    function invest(address investor, uint256 amount, bytes[] memory transactions) public payable override {
        address entryAsset = PoolStorage.entryAsset();
        bool isNative = KedrLib.isNative(entryAsset);
        require(amount >= poolDetails.minInvestment, 'TOO_SMALL_INVESTMENT');
        uint256 totalValueBefore;
        if (isNative) {
            amount = msg.value;
            totalValueBefore = totalValue() - amount; // we deduct amount because msg.value already included in pool balance
        } else {
            totalValueBefore = totalValue();
        }
        uint256 entryFee = (amount * poolDetails.entryFee) / KedrConstants._FEE_DENOMINATOR;
        uint256 invested = amount - entryFee;
        uint256 sharePrice = PoolStorage.calculateSharePrice(totalValueBefore);
        address feeReceiver = PoolStorage.feeReceiver();

        if (!isNative) {
            TransferHelper.safeTransferFrom(entryAsset, msg.sender, address(this), invested);
            if (entryFee > 0) {
                TransferHelper.safeTransferFrom(entryAsset, msg.sender, feeReceiver, entryFee);
            }
            TransferHelper.safeApprove(entryAsset, address(Swapper), invested);
        } else {
            if (entryFee > 0) {
                TransferHelper.safeTransferETH(feeReceiver, entryFee);
            }
            //TransferHelper.safeTransferETH(address(Swapper), invested/2);
        }

        address[] memory assets = poolDetails.assets;
        uint24[] memory weights = poolDetails.weights;

        for (uint256 i; i < assets.length; ++i) {
            if(weights[i] == 0) { continue; }
            if (assets[i] != entryAsset) {
                // uint256 entryAmount = (invested * weights[i]) / weightsSum;
                // uint256 currentBalance = _assetBalance(entryAsset);
                // uint256 adjustedAmount = currentBalance < entryAmount ? currentBalance : entryAmount;
                // if (isNative) {
                    // require(Swapper.multiswap(transactions), 'NO_TOKENS_RECEIVED');
                Swapper.multiswap(transactions);
                // } else {
                //     require(Swapper.multiswap(transactions), 'NO_TOKENS_RECEIVED');
                // }
            }
        }

        uint256 valueAdded = totalValue() - totalValueBefore; // we need to use "valueAdded" instead "invested" to exclude swap fee losses from calculating
        uint256 shares = PoolStorage.calculateSharesBySpecificPrice(valueAdded, sharePrice);
        PoolStorage.recordInvestment(investor, shares, sharePrice, invested, entryFee, invested - valueAdded);
    }

    /**
     * Burn kTokens and get entry asset
     * @param _shares - amount of kTokens to be burned to exchange for entryAsset
     */
    function withdraw(uint256 _shares, bytes[] memory transactions) public override {
        require(_shares > 0, 'ZERO_AMOUNT');
        address entryAsset = entryAsset(); // gas saving
        uint256 sharePrice = PoolStorage.sharePrice();
        uint256 withdrawAmount = PoolStorage.calculateEntryAmountBySpeicificPrice(_shares, sharePrice);
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

        uint256 swapFeesLoss = totalValueBefore - totalValue();
        withdrawAmount = totalReceived - swapFeesLoss; // adjust withdraw amount by possible INACCURACY and deduct swapFee losses
        uint256 successFee = _calcualteSuccessFee(withdrawAmount);
        withdrawAmount = withdrawAmount - successFee; // deduct successFee, withdrawAmount is the amount user really received

        address feeReceiver = PoolStorage.feeReceiver();
        if (KedrLib.isNative(entryAsset)) {
            TransferHelper.safeTransferETH(msg.sender, withdrawAmount);
            TransferHelper.safeTransferETH(feeReceiver, successFee);
        } else {
            TransferHelper.safeTransfer(entryAsset, msg.sender, withdrawAmount);
            TransferHelper.safeTransfer(entryAsset, feeReceiver, successFee);
        }
        PoolStorage.recordWithdrawal(msg.sender, _shares, sharePrice, withdrawAmount, successFee, swapFeesLoss);
    }

    /**
     * Do exactly the same as withdraw, but have no inacuracy check
     * required in order to be able to withdraw at least something if
     * main method always reverting tx
     */
    function withdrawUnsafe(uint256 _shares) public {
        require(_shares > 0, 'ZERO_AMOUNT');
        address entryAsset = entryAsset(); // gas saving
        uint256 sharePrice = PoolStorage.unsafeSharePrice();
        uint256 withdrawAmount = PoolStorage.calculateEntryAmountBySpeicificPrice(_shares, sharePrice);
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
        uint256 swapFeesLoss = totalValueBefore - unsafeTotalValue();
        withdrawAmount = totalReceived - swapFeesLoss; // adjust withdraw amount by possible INACCURACY and deduct swapFee losses
        uint256 successFee = _calcualteSuccessFee(withdrawAmount);
        withdrawAmount = withdrawAmount - successFee; // deduct successFee, withdrawAmount is the amount user really received

        address feeReceiver = PoolStorage.feeReceiver();
        if (KedrLib.isNative(entryAsset)) {
            TransferHelper.safeTransferETH(msg.sender, withdrawAmount);
            TransferHelper.safeTransferETH(feeReceiver, successFee);
        } else {
            TransferHelper.safeTransfer(entryAsset, msg.sender, withdrawAmount);
            TransferHelper.safeTransfer(entryAsset, feeReceiver, successFee);
        }
        PoolStorage.recordWithdrawal(msg.sender, _shares, sharePrice, withdrawAmount, successFee, swapFeesLoss);
    }

    // function withdrawAll() public override {
    //     uint256 shares = PoolStorage.balanceOf(msg.sender);
    //     withdraw(shares);
    // }

    function _sellToExactAmount(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) internal returns (uint256 received) {
        uint256 amountIn = Swapper.getAmountOut(_tokenOut, _tokenIn, _amountOut);
        uint256 actualBalance = _assetBalance(_tokenIn);
        uint256 amount = actualBalance < amountIn ? actualBalance : amountIn;
        TransferHelper.safeApprove(_tokenIn, address(Swapper), amount);
        // received = Swapper.swap(_tokenIn, _tokenOut, amount, address(this));
    }

    function _checkInaccuracy(uint256 expectedValue, uint256 realValue) internal pure {
        if (expectedValue > realValue) {
            require(expectedValue - realValue <= KedrConstants._INACCURACY, 'INCORRECT_OPERATION');
        } else {
            require(realValue - expectedValue <= KedrConstants._INACCURACY, 'INCORRECT_OPERATION');
        }
    }

    receive() external payable {}
}

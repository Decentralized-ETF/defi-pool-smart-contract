//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import '../base/BasePool.sol';

contract Pool is BasePool {
    constructor(uint64 _poolId, address _swapper) BasePool(_poolId, _swapper) {}

    /**
     * Invest entry asset and get kTokens
     */
    function invest(address investor, uint256 amount) public payable override {
        address entryAsset = PoolStorage.entryAsset();
        bool isNative = KedrLib.isNative(entryAsset);
        require(amount >= poolDetails.minInvestment, 'TOO_SMALL_INVESTMENT');
        uint256 entryFee = (amount * poolDetails.entryFee) / KedrConstants._FEE_DENOMINATOR;
        uint256 invested = amount - entryFee;
        uint256 sharePrice = PoolStorage.sharePrice();
        uint256 totalValueBefore = totalValue();

        KedrLib.uniTransferFrom(entryAsset, msg.sender, address(this), amount);

        // transfer fee from user to feeReceiver
        address feeReceiver = PoolStorage.feeReceiver();
        if (entryFee > 0) {
            KedrLib.uniTransfer(entryAsset, feeReceiver, entryFee);
        }

        address[] memory assets = poolDetails.assets;
        uint24[] memory weights = poolDetails.weights;

        if (!isNative) {
            TransferHelper.safeApprove(entryAsset, address(Swapper), invested);
        } else {
            TransferHelper.safeTransferETH(address(Swapper), invested);
        }

        for (uint256 i; i < assets.length; ++i) {
            if (assets[i] != entryAsset) {
                uint256 entryAmount = (invested * weights[i]) / weightsSum;
                uint256 currentBalance = _assetBalance(entryAsset);
                uint256 adjustedAmount = currentBalance < entryAmount ? currentBalance : entryAmount;
                require(Swapper.swap(entryAsset, assets[i], adjustedAmount, address(this)) != 0, 'NO_TOKENS_RECEIVED');
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
    function withdraw(uint256 _shares) public override {
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

    function withdrawAll() public override {
        uint256 shares = PoolStorage.balanceOf(msg.sender);
        withdraw(shares);
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

    function _checkInaccuracy(uint256 expectedValue, uint256 realValue) internal pure {
        if (expectedValue > realValue) {
            require(expectedValue - realValue <= KedrConstants._INACCURACY, 'INCORRECT_OPERATION');
        } else {
            require(realValue - expectedValue <= KedrConstants._INACCURACY, 'INCORRECT_OPERATION');
        }
    }

    receive() external payable {}
}

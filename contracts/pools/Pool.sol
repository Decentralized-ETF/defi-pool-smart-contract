//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import '../base/BasePool.sol';
import '../libraries/KedrConstants.sol';

contract Pool is BasePool {
    constructor(uint64 _poolId, address _swapper) BasePool(_poolId, _swapper) {}

    /**
     * Invest entry asset and get kTokens
     */
    function invest(address investor, uint256 amount) public payable override {
        require(amount >= poolDetails.minInvestment, 'TOO_SMALL_INVESTMENT');
        address entryAsset = PoolStorage.entryAsset();
        bool isNative = entryAsset == address(0); // by convention zero address is considered as native asset
        if (isNative) {
            require(msg.value > poolDetails.minInvestment, 'TOO_SMALL_MSG_VALUE_INVESTMENT');
            TransferHelper.safeTransferETH(address(this), msg.value);
            amount = msg.value; // adjust amount to msg.value
        } else {
            TransferHelper.safeTransferFrom(entryAsset, msg.sender, address(this), amount);
        }
        uint256 entryFee = (amount * poolDetails.entryFee) / KedrConstants._FEE_DENOMINATOR;
        uint256 invested = amount - entryFee;
        PoolStorage.recordInvestment(investor, invested, entryFee); // here minting of kTokens happens

        TransferHelper.safeApprove(entryAsset, poolDetails.swapper, invested);
        for (uint8 i; i < poolDetails.assets.length; ++i) {
            uint256 received = Swapper.swap(entryAsset, poolDetails.assets[i], amount, address(this));
            require(received > 0, 'NO_TOKENS_RECEIVED');
        }

        address feeReceiver = PoolStorage.feeReceiver();
        if (entryFee > 0) {
            if (isNative) {
                TransferHelper.safeTransferETH(feeReceiver, entryFee);
            } else {
                TransferHelper.safeTransfer(entryAsset, feeReceiver, entryFee);
            }
        }
        emit Invested(msg.sender, entryAsset, feeReceiver, invested, entryFee);
    }

    /**
     * Burn kTokens and get entry asset
     * @param _shares - amount of kTokens to be burned to exchange for entryAsset
     */
    function withdraw(uint256 _shares) public override {
        require(_shares > 0, 'ZERO_AMOUNT');
        address entryAsset = PoolStorage.entryAsset();
        bool isNative = entryAsset == address(0); // by convention zero address is considered as native asset
        (uint256 withdrawAmount, uint256 successFee) = PoolStorage.recordWithdrawal(msg.sender, _shares, poolDetails.successFee);
        uint256 availableBalance = _assetBalance(entryAsset);
        uint256 totalAmount = withdrawAmount + successFee;

        if (availableBalance < totalAmount) {
            uint256 diff = totalAmount - availableBalance;
            address[] memory sortedAssets = _getAssetBySellPriority();

            uint256 i = 0;
            while (diff != 0) {
                diff = _sellToExactAmount(sortedAssets[i], entryAsset, diff);
                i++;
            }
        }

        address feeReceiver = PoolStorage.feeReceiver();

        if (isNative) {
            TransferHelper.safeTransferETH(msg.sender, withdrawAmount);
            TransferHelper.safeTransferETH(feeReceiver, successFee);
        } else {
            TransferHelper.safeTransfer(entryAsset, msg.sender, withdrawAmount);
            TransferHelper.safeTransfer(entryAsset, feeReceiver, successFee);
        }
    }

    /**
     * Rebalance pool to make rigth allocations
     */
    function rebalance() public override {
        // TODO: on stage #3
    }

    function _sellToExactAmount(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) internal returns (uint256 remaining) {
        uint256 amountIn = Swapper.getReturn(_tokenOut, _tokenIn, _amountOut);
        TransferHelper.safeApprove(_tokenIn, address(Swapper), amountIn);
        uint256 received = Swapper.swap(_tokenIn, _tokenOut, amountIn, address(this));

        if (received < _amountOut) {
            remaining = _amountOut - received;
        } else {
            remaining = 0;
        }
    }

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

    receive() external payable {}
}

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
        require(_shares > 0, "ZERO_AMOUNT");
        address entryAsset = PoolStorage.entryAsset();
        bool isNative = entryAsset == address(0); // by convention zero address is considered as native asset
        (uint256 withdrawAmount, uint256 successFee) = PoolStorage.recordWithdrawal(msg.sender, _shares, poolDetails.successFee);
        uint256 availableBalance = _assetBalance(entryAsset);
        uint256 totalAmount = withdrawAmount + successFee;

        if (availableBalance < totalAmount) {
            
        }
    }

    /**
     * Rebalance pool to make rigth allocations
     */
    function rebalance() public override {
        // TODO: on stage #3
    }

    function _sell(address _asset) internal {
        
    }
    

    receive() external payable {}
}

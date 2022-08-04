//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '../base/BasePool.sol';
import "../libraries/KedrConstants.sol";

contract Pool is BasePool {

    constructor(uint64 _poolId, address _swapper) BasePool(_poolId, _swapper) {}

    /**
     * Invest entry asset
     */
    function invest(uint256 amount, bool defaultRouter) public override payable {
        require(amount >= poolDetails.minInvestment, 'TOO_SMALL_INVESTMENT');
        address entryAsset = PoolStorage.entryAsset();
        if (entryAsset == address(0)) {
            // entryAsset is native, by convention zero address is native asset
            require(msg.value > poolDetails.minInvestment, 'TOO_SMALL_MSG_VALUE_INVESTMENT');
            amount = msg.value; // adjust amount to msg.value
        } else {
            TransferHelper.safeTransferFrom(entryAsset, msg.sender, address(this), amount);
        }
        uint256 entryFee = (amount * poolDetails.entryFee) / KedrConstants._FEE_DENOMINATOR;
        uint256 invested = amount - entryFee;

        PoolStorage.recordInvestment(invested, entryFee);
        TransferHelper.safeApprove(entryAsset, poolDetails.swapper, invested);

        for (uint8 i; i < poolDetails.assets.length; ++i) {
            uint256 received = Swapper.swap(entryAsset, poolDetails.assets[i], amount, address(this), defaultRouter);
            require(received > 0, "zero tokens received");
        }

        address feeReceiver = PoolStorage.feeReceiver();
        if (entryFee > 0) {
            // TODO: make generic TransferHelper for native and ERC20 
            TransferHelper.safeTransferFrom(entryAsset, address(this), feeReceiver, entryFee);
        }
        emit Invested(msg.sender, entryAsset, feeReceiver, invested, entryFee);
    }

    /**
     * Withdraw entry asset
     */
    function withdraw(uint256 _amount) public override {
        // TODO: on stage #2
    }

    /**
     * Rebalance pool to make rigth allocations
     */
    function rebalance() public override {
        // TODO: on stage #3
    }

    receive() external payable {}
}

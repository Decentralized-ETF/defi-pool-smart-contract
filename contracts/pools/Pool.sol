//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '../base/BasePool.sol';
import "../libraries/KedrConstants.sol";

contract Pool is BasePool {
    // TODO

    constructor(uint64 _poolId) BasePool(_poolId) {}

    /**
     * Invest entry asset
     */
    function invest(uint256 amount) public override {
        require(amount >= poolDetails.minInvestment, 'TOO_SMALL_INVESTMENT');
        address entryAsset = PoolStorage.entryAsset();
        if (entryAsset == address(0)) {
            // entryAsset is native, by convention zero address is native asset
            require(msg.value > poolDetails.minInvestment, 'TOO_SMALL_MSG_VALUE_INVESTMENT');
            amount = msg.value; // adjust amount to msg.value
        } else {
            TransferHelper.safeTransferFrom(entryAsset, msg.sender, address(this), amount);
        }

        uint256 managerFee = (amount * poolDetails.entryFee) / KedrConstants._FEE_DENOMINATOR;
        uint256 invested = amount - managerFee;

        uint256[] memory tokenBalances = new uint256[](poolSize);
        totalReceivedCurrency = totalReceivedCurrency + investmentAmount;

        TransferHelper.safeApprove(entryAsset, swapper, invested);
        for (uint8 i = 0; i < poolSize; i++) {
            uint256 tokenBalance = entryAssetToToken(investmentAmount, i, inputIsNativeToken);
            tokenBalances[i] = tokenBalance;
        }
        investmentDataByUser[investor].push(
            InvestmentData({
                inputIsNativeToken: inputIsNativeToken,
                receivedCurrency: investmentAmount,
                tokenBalances: tokenBalances,
                rebalanceEnabled: true,
                active: true
            })
        );
        if (theManagerFee > 0) {
            totalManagerFee = totalManagerFee + theManagerFee;
            TransferHelper.safeTransferFrom(address(entryAsset), address(this), address(feeAddress), theManagerFee);
        }
        emit Invested(investor, investmentAmount, tokenBalances, poolTokenPercentages);
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

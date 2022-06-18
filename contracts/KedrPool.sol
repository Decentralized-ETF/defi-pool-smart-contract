//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {BaseKedrPool} from "./BaseKedrPool.sol";
import {DefiAdapter} from "./adapters/DefiAdapter.sol";
import {KedrLib} from "./libs/KedrLib.sol";

contract KedrPool is BaseKedrPool {

    DefiAdapter defiAdapter;

    constructor(address _storageAddress, address _mainTokenAddress) BaseKedrPool(_storageAddress, _mainTokenAddress)  {

    }

    function initInvestment(address _investor, uint256 _amount) external {
        require(_amount > kedrStorage.getMinInvestmentLimit(), "amount is too small");

        //TODO transfer token from user to smart contract

        (uint256 managerFeeAmount,uint256 finalAmount) = kedrStorage.calculateManagerFeeAmount(_amount);

        uint8 poolSize =  kedrStorage.getPoolSize();
        uint256[] memory tokenBalanceAmounts = new uint256[](poolSize);
        for (uint8 i = 0; i < poolSize; i++) {
            //TODO get token balance from exchange with adapter
            uint256 tokenBalance = i;
            tokenBalanceAmounts[i] = tokenBalance;
            kedrStorage.increasePoolTokenBalanceAmount(i,tokenBalance);
        }

        kedrStorage.startInvestment(_investor, finalAmount ,tokenBalanceAmounts);
        if (managerFeeAmount > 0) {
            kedrStorage.increaseTotalManagerFeeAmountCollected(managerFeeAmount);
            //TODO transfer fee to recipient
            //TransferHelper.safeTransferFrom(address(entryAsset), address(this), address(feeAddress), theManagerFee);
        }
        emit KedrLib.Invested(_investor,finalAmount,tokenBalanceAmounts);
    }

    function finishInvestment(uint16 _investmentId) external {
        require(_investmentId >= 0, "invalid investment Id");
        KedrLib.InvestmentData memory investmentData = kedrStorage.getInvestment(msg.sender, _investmentId);
        require(investmentData.active == true, "investment is not active");

        uint256 receivedEntryAssetAmount = 0;
        uint8 poolSize =  kedrStorage.getPoolSize();
        for (uint8 i = 0; i < poolSize; i++) {
            //TODO get token balance from exchange with adapter
            uint256 receivedEntryAssetAmountForThisToken = i;
            receivedEntryAssetAmount += receivedEntryAssetAmountForThisToken;
            kedrStorage.decreasePoolTokenBalanceAmount(i,investmentData.tokenBalanceAmounts[i]);
        }
        (uint256 successFeeAmount,uint256 finalAmount) = kedrStorage.calculateSuccessFeeAmount(receivedEntryAssetAmount);

        if (receivedEntryAssetAmount > investmentData.receivedEntryAssetAmount) {
            kedrStorage.increaseTotalSuccessFeeAmountCollected(successFeeAmount);
            //TODO transfer fee to recipient
        }

        emit KedrLib.UnInvested(msg.sender,finalAmount,_investmentId);
    }

    function updateAdapater(address adapterAddress) public {
        defiAdapter = DefiAdapter(adapterAddress);
    }
}
//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {BaseKedrPool} from "./BaseKedrPool.sol";
import {KedrLib} from "./libs/KedrLib.sol";

contract KedrPool is BaseKedrPool {

    function initialize(
        address _storageAddress,
        address _mainTokenAddress,
        address _defiAdapterAddress) public override initializer {
        BaseKedrPool.initialize(_storageAddress, _mainTokenAddress,_defiAdapterAddress);
    }

    function initInvestment(address _investor, uint256 _amount) external {
        require(_amount > kedrStorage.getMinInvestmentLimit(), "amount is too small");

        require(mainErc20Token.transferFrom(_investor, address(this), _amount), 'transfer failed');

        (uint256 managerFeeAmount,uint256 finalAmount) = kedrStorage.calculateManagerFeeAmount(_amount);

        uint8 poolSize = kedrStorage.getPoolSize();
        uint256[] memory tokenBalanceAmounts = new uint256[](poolSize);
        for (uint8 i = 0; i < poolSize; i++) {
            //TODO get token balance from exchange with adapter
            uint256 tokenBalance = i;
            tokenBalanceAmounts[i] = tokenBalance;
            kedrStorage.increasePoolTokenBalanceAmount(i, tokenBalance);
        }

        kedrStorage.startInvestment(_investor, finalAmount, tokenBalanceAmounts);
        if (managerFeeAmount > 0) {
            kedrStorage.increaseTotalManagerFeeAmountCollected(managerFeeAmount);
            require(mainErc20Token.transfer(kedrStorage.getFeeRecipient(),managerFeeAmount), 'fee transfer failed');
        }
        emit KedrLib.Invested(_investor, finalAmount, tokenBalanceAmounts);
    }

    function finishInvestment(uint16 _investmentId) external {
        require(_investmentId >= 0, "invalid investment Id");
        KedrLib.InvestmentData memory investmentData = kedrStorage.getInvestment(msg.sender, _investmentId);
        require(investmentData.active == true, "investment is not active");

        uint256 receivedEntryAssetAmount = 0;
        uint8 poolSize = kedrStorage.getPoolSize();
        for (uint8 i = 0; i < poolSize; i++) {
            //TODO get token balance from exchange with adapter
            uint256 receivedEntryAssetAmountForThisToken = i;
            receivedEntryAssetAmount += receivedEntryAssetAmountForThisToken;
            kedrStorage.decreasePoolTokenBalanceAmount(i, investmentData.tokenBalanceAmounts[i]);
        }
        (uint256 successFeeAmount,uint256 finalAmount) = kedrStorage.calculateSuccessFeeAmount(receivedEntryAssetAmount);

        if (receivedEntryAssetAmount > investmentData.receivedEntryAssetAmount) {
            kedrStorage.increaseTotalSuccessFeeAmountCollected(successFeeAmount);
            require(mainErc20Token.transfer(kedrStorage.getFeeRecipient(),successFeeAmount), 'fee transfer failed');
        }

        require(mainErc20Token.transfer(msg.sender,finalAmount), 'transfer failed');

        emit KedrLib.UnInvested(msg.sender, finalAmount, _investmentId);
    }
}
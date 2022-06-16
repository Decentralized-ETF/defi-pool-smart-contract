//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {BaseKedrPool} from "./BaseKedrPool.sol";
import {DefiAdapter} from "./adapters/DefiAdapter.sol";

contract KedrPool is BaseKedrPool {

    DefiAdapter defiAdapter;

    constructor(address _storageAddress, address _mainTokenAddress) BaseKedrPool(_storageAddress, _mainTokenAddress)  {

    }

    function initInvestment(address _investor, uint256 _amount) external {
        require(_amount >= kedrStorage.minInvestmentLimit(), "amount is too small");
        uint256 theManagerFee = (_amount * kedrStorage.managerFeeInBp()) / 100;
        uint256 investmentAmount = amount - theManagerFee;

        uint256[] memory tokenBalances = new uint256[](poolSize);
        totalReceivedCurrency = totalReceivedCurrency + investmentAmount;
    }

    function finishInvestment(uint16 _investmentId) external {

    }

    function updateAdapater(address adapterAddress) public {
        defiAdapter = DefiAdapter(adapterAddress);
    }
}
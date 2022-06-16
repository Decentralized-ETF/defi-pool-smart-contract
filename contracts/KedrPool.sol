//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {BaseKedrPool} from "./BaseKedrPool.sol";

contract KedrPool is BaseKedrPool {

    constructor(address _storageAddress) BaseKedrPool(_storageAddress)  {

    }

    function initInvestment(address _investor, uint256 _amount) external {

    }

    function finishInvestment(uint16 _investmentId) external {

    }
}
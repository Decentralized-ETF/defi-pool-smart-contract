//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '../base/BasePool.sol';

contract Pool is BasePool {
    // TODO

    constructor(uint64 _poolId) BasePool(_poolId) {

    }
}

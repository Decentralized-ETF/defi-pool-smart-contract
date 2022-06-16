//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {Storage} from "./storage/Storage.sol";

contract BaseKedrPool {
    Storage kedrStorage;

    constructor(address _storageAddress) {
        kedrStorage = Storage(_storageAddress);
    }
}
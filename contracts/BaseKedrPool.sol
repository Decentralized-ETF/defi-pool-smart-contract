//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {IStorage} from "./interfaces/IStorage.sol";

contract BaseKedrPool {
    IStorage kedrStorage;

    constructor(address _storageAddress) {
        kedrStorage = IStorage(_storageAddress);
    }
}
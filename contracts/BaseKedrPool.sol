//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

import {IStorage} from "./interfaces/IStorage.sol";

contract BaseKedrPool {
    IStorage kedrStorage;
    IERC20Upgradeable mainErc20Token;

    constructor(address _storageAddress, address _mainTokenAddress) {
        kedrStorage =IStorage(_storageAddress);
        mainErc20Token = IERC20Upgradeable(_mainTokenAddress);
    }
}
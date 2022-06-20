//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;


import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IStorage} from "./interfaces/IStorage.sol";
import {DefiAdapter} from "./adapters/DefiAdapter.sol";

contract BaseKedrPool is Initializable {
    IStorage kedrStorage;
    IERC20 mainErc20Token;
    DefiAdapter defiAdapter;

    function initialize(address _storageAddress,
        address _mainTokenAddress,
        address _defiAdapterAddress) public virtual initializer {
        kedrStorage = IStorage(_storageAddress);
        mainErc20Token = IERC20(_mainTokenAddress);
        defiAdapter = DefiAdapter(_defiAdapterAddress);
    }

    function updateAdapater(address _adapterAddress) public {
        defiAdapter = DefiAdapter(_adapterAddress);
    }
}
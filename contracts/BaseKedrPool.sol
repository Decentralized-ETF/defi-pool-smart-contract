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

    function initialize(address _storageAddress, address _mainTokenAddress) public virtual initializer {
        kedrStorage = IStorage(_storageAddress);
        mainErc20Token = IERC20(_mainTokenAddress);
    }

    function updateAdapater(address adapterAddress) public {
        defiAdapter = DefiAdapter(adapterAddress);
    }
}
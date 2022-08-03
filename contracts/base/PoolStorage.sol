//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../libraries/KedrLib.sol';
import '../interfaces/IPoolStorage.sol';

contract PoolStorage is ERC20 {
    using SafeMath for uint256;

    address public factory;
    address public pool;
    uint256 public poolStorageId;
    address public feeReceiver;
    address public entryAsset;
    uint256 public totalSuccessFeeCollected = 0;
    uint256 public totalEntryFeeCollected = 0;
    uint256 public totalReceivedEntryAsset = 0;
    uint256 public totalWithdrawnEntryAsset = 0;

    modifier onlyFactory() {
        require(msg.sender == factory, 'CALLER_IS_NOT_FACTORY');
        _;
    }

    modifier onlyPool() {
        require(msg.sender == pool, 'CALLER_IS_NOT_POOL');
        _;
    }

    constructor(
        uint256 _poolStorageId,
        address _entryAsset,
        address _feeReceiver,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        poolStorageId = _poolStorageId;
        require(_feeReceiver != address(0) && _entryAsset != address(0), 'ZERO_ADDRESS');
        factory = msg.sender;
        feeReceiver = _feeReceiver;
        entryAsset = _entryAsset;
    }

    // called once by the factory during deployment
    function link(address _pool) external onlyFactory {
        require(_pool != address(0), 'ZERO_ADDRESS');
        pool = _pool;
    }
 
    function recordInvestment(uint256 _amount, uint256 _entryFee) external onlyPool {
        totalReceivedEntryAsset += _amount;
        totalEntryFeeCollected += _entryFee;
    }

    function recordWithdrawal(uint256 _amount, uint256 _successFee) external onlyPool {
        totalWithdrawnEntryAsset += _amount;
        totalSuccessFeeCollected += _successFee;
    }


    function setFeeReceiver(address _feeReceiver) external onlyFactory {
        require(_feeReceiver != address(0), 'ZERO_ADDRESS');
        feeReceiver = _feeReceiver;
    }
}

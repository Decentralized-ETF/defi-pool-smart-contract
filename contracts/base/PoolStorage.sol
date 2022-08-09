//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../libraries/KedrLib.sol';
import '../libraries/KedrConstants.sol';
import '../interfaces/IPoolStorage.sol';
import '../interfaces/IPool.sol';

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
    IPool internal Pool;

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

    function link(address _pool) external onlyFactory {
        require(_pool != address(0), 'ZERO_ADDRESS');
        pool = _pool;
        Pool = IPool(_pool);
    }
 
    function recordInvestment(address _investor, uint256 _amount, uint256 _entryFee) external onlyPool {
        uint256 shares = calculateShares(_amount);
        require(shares > 0, "ZERO_SHARES_AMOUNT");
        _mint(_investor, shares);
        totalReceivedEntryAsset += _amount;
        totalEntryFeeCollected += _entryFee;
    }

    function recordWithdrawal(address _investor, uint256 _shares, uint16 _successFee) external onlyPool returns (uint256 withdrawAmount, uint256 successFeeSize) {
        withdrawAmount = calculateEntryAmount(_shares);
        require(withdrawAmount > 0, "ZERO_WITHDRAW_AMOUNT");
        _burn(_investor, _shares);
        successFeeSize =  (withdrawAmount  * _successFee) / KedrConstants._FEE_DENOMINATOR;
        totalWithdrawnEntryAsset += withdrawAmount;
        totalSuccessFeeCollected += successFeeSize;
    }

    function setFeeReceiver(address _feeReceiver) external onlyFactory {
        require(_feeReceiver != address(0), 'ZERO_ADDRESS');
        feeReceiver = _feeReceiver;
    }

    function sharePrice() public view returns (uint256) {
        uint256 totalValue = Pool.totalValue();
        return totalValue / totalSupply();
    }

    function calculateShares(uint256 _entryAmount) public view returns (uint256) {
        return _entryAmount / sharePrice();
    }

    function calculateEntryAmount(uint256 _shares) public view returns (uint256) {
        return _shares * sharePrice();
    }
}

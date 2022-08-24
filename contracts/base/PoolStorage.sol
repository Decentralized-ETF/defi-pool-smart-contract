//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
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
    uint256 public totalSwapFeesLoss = 0;
    uint256 internal constant NUMERATOR = 1e18;
    IPool internal Pool;

    event Withdrawal(address indexed user, address indexed entryAsset, uint256 shares, uint256 sharePrice, uint256 amountReceived, uint256 successFee, uint256 swapFeesLoss);
    event Investment(address indexed user, address indexed entryAsset, uint256 shares, uint256 sharePrice, uint256 amountInvested, uint256 entryFee, uint256 swapFeesLoss);

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
 
    function recordInvestment(address _investor, uint256 _shares, uint256 _sharePrice, uint256 _amount, uint256 _entryFee, uint256 _swapFeesLoss) external onlyPool {
        require(_shares > 0, "ZERO_SHARES_AMOUNT");
        _mint(_investor, _shares);
        totalReceivedEntryAsset += _amount;
        totalEntryFeeCollected += _entryFee;
        totalSwapFeesLoss += _swapFeesLoss;
        emit Investment(_investor, entryAsset, _shares, _sharePrice, _amount, _entryFee, _swapFeesLoss);
    }

    function recordWithdrawal(address _investor, uint256 _shares, uint256 _sharePrice, uint256 _withdrawAmount, uint256 _successFee, uint256 _swapFeesLoss) external onlyPool {
        require(_withdrawAmount > 0, "ZERO_WITHDRAW_AMOUNT");
        _burn(_investor, _shares);
        totalWithdrawnEntryAsset += _withdrawAmount;
        totalSuccessFeeCollected += _successFee;
        totalSwapFeesLoss += _swapFeesLoss;
        emit Withdrawal(_investor, entryAsset, _shares, _sharePrice, _withdrawAmount, _successFee, _swapFeesLoss);
    }

    function setFeeReceiver(address _feeReceiver) external onlyFactory {
        require(_feeReceiver != address(0), 'ZERO_ADDRESS');
        feeReceiver = _feeReceiver;
    }

    function sharePrice() public returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return NUMERATOR; // initial price
        }
        uint256 totalValue = Pool.totalValue();
        return totalValue * NUMERATOR / _totalSupply; // check: maybe need to add multiplier here, not sure
    }

    function calculateShares(uint256 _entryAmount) public returns (uint256) {
        return _entryAmount * NUMERATOR / sharePrice();
    }

    function calculateSharesBySpecificPrice(uint256 _entryAmount, uint256 _sharePrice) public pure returns (uint256) {
        return _entryAmount * NUMERATOR / _sharePrice;
    }

    function calculateEntryAmount(uint256 _shares) public returns (uint256) {
        return _shares * sharePrice() / NUMERATOR;
    }

    function calculateEntryAmountBySpeicificPrice(uint256 _shares, uint256 _sharePrice) public returns (uint256) {
        return _shares * _sharePrice / NUMERATOR;
    }
}

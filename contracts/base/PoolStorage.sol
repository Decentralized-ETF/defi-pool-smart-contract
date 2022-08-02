//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '../libraries/KedrLib.sol';

contract PoolStorage is ERC20 {
    using SafeMath for uint256;

    address public owner;
    address public feeReceiver;
    address public entryAsset;
    uint256 public totalSuccessFeeAmountCollected = 0;
    uint256 public totalEntryFeeCollected = 0;
    uint256 public totalReceivedEntryAssetAmount = 0;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        address _entryAsset,
        string memory _name,
        string memory _symbol,
        address _feeReceiver
    ) ERC20(_name, _symbol) {
        require(_feeReceiver != address(0) && _entryAsset != address(0), "ZERO_ADDRESS");
        feeReceiver = _feeReceiver;
        entryAsset = _entryAsset;
    }

    function increaseTotalSuccessFeeAmountCollected(uint256 _amount) external onlyOwner {
        totalSuccessFeeAmountCollected += _amount;
    }

    function increaseTotalManagerFeeAmountCollected(uint256 _amount) external onlyOwner {
        totalEntryFeeCollected += _amount;
    }

    function increaseTotalReceivedEntryAssetAmount(uint256 _amount) external onlyOwner {
        totalReceivedEntryAssetAmount += _amount;
    }

    function decreaseTotalReceivedEntryAssetAmount(uint256 _amount) external onlyOwner {
        totalReceivedEntryAssetAmount -= _amount;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "ZERO_ADDRESS");
        feeReceiver = _feeReceiver;
    }
}

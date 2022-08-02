//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '../libraries/KedrLib.sol';

contract PoolStorage is ERC20 {
    using SafeMath for uint256;

    address public factory;
    address public feeReceiver;
    address public entryAsset;
    uint256 public totalSuccessFeeAmountCollected = 0;
    uint256 public totalEntryFeeCollected = 0;
    uint256 public totalReceivedEntryAssetAmount = 0;

    modifier onlyFactory() {
        require(msg.sender == factory, "CALLER_IS_NOT_FACTORY");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _entryAsset,
        address _feeReceiver
    ) external onlyFactory {
        require(_feeReceiver != address(0) && _entryAsset != address(0), "ZERO_ADDRESS");
        feeReceiver = _feeReceiver;
        entryAsset = _entryAsset;
    }

    function increaseTotalSuccessFeeAmountCollected(uint256 _amount) internal {
        totalSuccessFeeAmountCollected += _amount;
    }

    function increaseTotalManagerFeeAmountCollected(uint256 _amount) internal {
        totalEntryFeeCollected += _amount;
    }

    function increaseTotalReceivedEntryAssetAmount(uint256 _amount) internal {
        totalReceivedEntryAssetAmount += _amount;
    }

    function decreaseTotalReceivedEntryAssetAmount(uint256 _amount) internal {
        totalReceivedEntryAssetAmount -= _amount;
    }

    function setFeeReceiver(address _feeReceiver) external onlyFactory {
        require(_feeReceiver != address(0), "ZERO_ADDRESS");
        feeReceiver = _feeReceiver;
    }
}

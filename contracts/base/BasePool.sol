//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IPoolStorage.sol";
import "../libraries/KedrConstants.sol";

abstract contract BasePool is IPool, ReentrancyGuard, Ownable, Pausable {
    uint64 public poolId;
    address public factory;
    IPoolStorage internal PoolStorage;
    PoolDetails public poolDetails;

    constructor(uint64 _poolId) {
        factory = msg.sender;
        poolId = _poolId;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "CALLER_IS_NOT_FACTORY");
        _;
    }

    // called once by the factory at time of deployment
    function initialize(
        PoolDetails calldata _poolDetails
    ) external onlyFactory {
        require(_poolDetails.assets.length == _poolDetails.weights.length, "INVALID_ALLOCATIONS");
        poolDetails = _poolDetails;
        PoolStorage = IPoolStorage(_poolDetails.poolStorage);
        setSuccessFee(_poolDetails.successFee);
        setEntryFee(_poolDetails.entryFee);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setWeight(address _asset, uint24 _weight) external onlyOwner {
        // TODO: find index of asset in assets and updated weights[i] = _weight
    }

    function poolSize() external view returns (uint256) {
        return poolDetails.assets.length;
    }

    /**
     * @dev this function updates allocation weights for all assets
     */
    function updateAllocations(uint24[] memory _weights) external onlyOwner {
        require(_weights.length == poolDetails.assets.length, "WRONG_LENGTH");
        poolDetails.weights = _weights;
    }

    function setSuccessFee(uint16 _successFee) public onlyOwner whenPaused {
        require(
            _successFee >= KedrConstants._MIN_SUCCESS_FEE,
            "TOO_SMALL_NUMERATOR"
        );
        require(
            _successFee <= KedrConstants._FEE_DENOMINATOR,
            "TOO_BIG_NUMERATOR"
        );
        poolDetails.successFee = _successFee;
    }

    function setEntryFee(uint16 _entryFee) public onlyOwner whenPaused {
        require(
            _entryFee >= KedrConstants._MIN_SUCCESS_FEE,
            "TOO_SMALL_NUMERATOR"
        );
        require(
            _entryFee <= KedrConstants._FEE_DENOMINATOR,
            "TOO_BIG_NUMERATOR"
        );
        poolDetails.entryFee = _entryFee;
    }

    function setMinInvestment(uint256 _minInvestment)
        external
        onlyOwner
        whenPaused
    {
        poolDetails.minInvestment = _minInvestment;
    }

    function details() external view returns (PoolDetails memory) {
        return poolDetails;
    }

    function entryFee() external view returns (uint16) {
        return poolDetails.entryFee;
    }

    function successFee() external view returns (uint16) {
        return poolDetails.successFee;
    }

    function minInvestment() external view returns (uint256) {
        return poolDetails.minInvestment;
    }

    function poolStorage() external view returns (address) {
        return poolDetails.poolStorage;
    }

    /**
     * @dev must be implemented in inherited classes
     */
    function rebalance() public virtual {}

    /**
     * @dev must be implemented in inherited classes
     */
    function invest(uint256 _amount) public virtual {}

    /**
     * @dev must be implemented in inherited classes
     */
    function withdraw(uint256 _amount) public virtual {}
}

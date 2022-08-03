//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IPoolStorage.sol";
import "../libraries/KedrConstants.sol";

abstract contract BasePool is IPool, ReentrancyGuard, Pausable {
    uint64 public override poolId;
    address public override factory;
    address public override poolStorage;
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
    ) external override onlyFactory {
        require(_poolDetails.assets.length == _poolDetails.weights.length, "INVALID_ALLOCATIONS");  
        poolDetails = _poolDetails;
        setSuccessFee(_poolDetails.successFee);
        setEntryFee(_poolDetails.entryFee);
    }

    function link(address _poolStorage) external override onlyFactory {
        require(_poolStorage != address(0), "ZERO_ADDRESS");
        poolStorage = _poolStorage;
        PoolStorage = IPoolStorage(_poolStorage);
    }

    // Must be called only inside Factory.switchStorageToNewPool function 
    function moveFunds(address _newPool) external override onlyFactory {
        require(_newPool != address(0), "ZERO_ADDRESS");
        for (uint256 i; i < poolDetails.assets.length; ++ i) {
            address token = poolDetails.assets[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                TransferHelper.safeTransfer(token, _newPool, balance);
            }
        }
    }

    function pause() external onlyFactory {
        _pause();
    }

    function unpause() external onlyFactory {
        _unpause();
    }

    function setWeight(address _asset, uint24 _weight) external override onlyFactory {
        // TODO: find index of asset in assets and updated weights[i] = _weight
    }

    function poolSize() external view override returns (uint256) {
        return poolDetails.assets.length;
    }

    /**
     * @dev this function updates allocation weights for all assets
     */
    function updateAllocations(uint24[] memory _weights) external override onlyFactory {
        require(_weights.length == poolDetails.assets.length, "WRONG_LENGTH");
        poolDetails.weights = _weights;
    }

    function setSuccessFee(uint16 _successFee) public onlyFactory whenPaused {
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

    function setEntryFee(uint16 _entryFee) public onlyFactory whenPaused {
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
        onlyFactory
        whenPaused
    {
        poolDetails.minInvestment = _minInvestment;
    }

    function details() external view override returns (PoolDetails memory) {
        return poolDetails;
    }

    function entryFee() external view override returns (uint16) {
        return poolDetails.entryFee;
    }

    function successFee() external view override returns (uint16) {
        return poolDetails.successFee;
    }

    function minInvestment() external view override returns (uint256) {
        return poolDetails.minInvestment;
    }

    /**
     * @dev must be implemented in inherited classes
     */
    function rebalance() public virtual override {}

    /**
     * @dev must be implemented in inherited classes
     */
    function invest(uint256 _amount) public virtual override {}

    /**
     * @dev must be implemented in inherited classes
     */
    function withdraw(uint256 _amount) public virtual override {}
}

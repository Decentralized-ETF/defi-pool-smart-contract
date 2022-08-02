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
    uint8 public entryFee;
    uint8 public successFee;
    uint256 public minInvestment;
    uint24[] internal weights;
    address[] internal assets;
    address public factory;
    address public poolStorage;
    IPoolStorage internal PoolStorage;

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
        address _poolStorage,
        address[] calldata _assets,
        uint24[] calldata _weights,
        uint256 _minInvestment,
        uint8 _entryFee,
        uint8 _successFee
    ) external onlyFactory {
        require(_assets.length == _weights.length, "INVALID_ALLOCATIONS");
        assets = _assets;
        weights = _weights;
        minInvestment = _minInvestment;
        poolStorage = _poolStorage;
        PoolStorage = IPoolStorage(_poolStorage);
        setSuccessFee(_successFee);
        setEntryFee(_entryFee);
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
        return assets.length;
    }

    function updateAllocations(uint24[] memory _weights) external onlyOwner {
        require(_weights.length == assets.length, "WRONG_LENGTH");
        weights = _weights;
    }

    function setSuccessFee(uint8 _successFee) public onlyOwner whenPaused {
        require(
            _successFee >= KedrConstants._MIN_SUCCESS_FEE,
            "TOO_SMALL_NUMERATOR"
        );
        require(
            _successFee <= KedrConstants._FEE_DENOMINATOR,
            "TOO_BIG_NUMERATOR"
        );
        successFee = _successFee;
    }

    function setEntryFee(uint8 _entryFee) public onlyOwner whenPaused {
        require(
            _entryFee >= KedrConstants._MIN_SUCCESS_FEE,
            "TOO_SMALL_NUMERATOR"
        );
        require(
            _entryFee <= KedrConstants._FEE_DENOMINATOR,
            "TOO_BIG_NUMERATOR"
        );
        entryFee = _entryFee;
    }

    function setMinInvestment(uint256 _minInvestment)
        external
        onlyOwner
        whenPaused
    {
        minInvestment = _minInvestment;
    }

    function details() public view returns (PoolDetails memory) {
        PoolDetails memory data = PoolDetails({
            creator: owner(),
            entryAsset: PoolStorage.entryAsset(),
            minInvestment: minInvestment,
            assets: assets,
            weights: weights,
            entryFee: entryFee,
            successFee: successFee
        });
        return data;
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

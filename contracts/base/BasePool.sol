//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IPoolStorage.sol';
import '../libraries/KedrConstants.sol';
import '../interfaces/ISwapper.sol';

abstract contract BasePool is IPool, ReentrancyGuard, Pausable {
    uint64 public override poolId;
    address public override factory;
    address public override poolStorage;
    uint24 public weightsSum;
    PoolDetails public poolDetails;
    IPoolStorage internal PoolStorage;
    ISwapper internal Swapper;

    constructor(uint64 _poolId, address _swapper) {
        factory = msg.sender;
        poolId = _poolId;
        Swapper = ISwapper(_swapper);
    }

    event Invested(address indexed user, address entryAsset, address feeReceiver, uint256 amount, uint256 entryFee);

    modifier onlyFactory() {
        require(msg.sender == factory, 'CALLER_IS_NOT_FACTORY');
        _;
    }

    // called once by the factory at time of deployment
    function initialize(PoolDetails calldata _poolDetails) external override onlyFactory {
        require(_poolDetails.assets.length == _poolDetails.weights.length, 'INVALID_ALLOCATIONS');
        poolDetails = _poolDetails;
        weightsSum = _weightsSum(_poolDetails.weights);
    }

    function link(address _poolStorage) external override onlyFactory {
        require(_poolStorage != address(0), 'ZERO_ADDRESS');
        poolStorage = _poolStorage;
        PoolStorage = IPoolStorage(_poolStorage);
    }

    // resets poolStorage to address(0), used only during Factory.switchStorageToNewPool function
    function unlink() external override onlyFactory {
        poolStorage = address(0);
        PoolStorage = IPoolStorage(address(0));
    }

    // Must be called only inside Factory.switchStorageToNewPool function
    function moveFunds(address _newPool) external override onlyFactory {
        require(_newPool != address(0), 'ZERO_ADDRESS');
        address[] memory poolAssets = poolDetails.assets; // gas savings
        for (uint256 i; i < poolAssets.length; ++i) {
            address token = poolAssets[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                TransferHelper.safeTransfer(token, _newPool, balance);
            }
        }
    }

    function totalValue() public override view returns (uint256 _totalValue) {
        address[] memory poolAssets = poolDetails.assets; // gas savings
        address _entryAsset = entryAsset(); // gas savings
        for (uint256 i; i < poolAssets.length; ++i) {
            address asset = poolAssets[i];
            uint256 valueConverted = Swapper.getReturn(asset, _entryAsset, _assetBalance(asset));
            require(valueConverted > 0, 'ORACLE_ERROR');
            _totalValue += valueConverted;
        }
    }

    /**
     * Returns totalValue() with array of values per each asset
     */
    function totalValues() internal view returns (uint256 _totalValue, uint256[] memory _values) {
        address[] memory poolAssets = poolDetails.assets; // gas savings
        address _entryAsset = entryAsset(); // gas savings
        for (uint256 i; i < poolAssets.length; ++i) {
            address asset = poolAssets[i];
            uint256 valueConverted = Swapper.getReturn(asset, _entryAsset, _assetBalance(asset));
            require(valueConverted > 0, 'ORACLE_ERROR');
            _totalValue += valueConverted;
            _values[i] = valueConverted;
        }
    } 

    function entryAsset() public override view returns (address) {
        return PoolStorage.entryAsset();
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
        require(_weights.length == poolDetails.assets.length, 'WRONG_LENGTH');
        poolDetails.weights = _weights;
        weightsSum = _weightsSum(_weights);
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
    function invest(address _investor, uint256 _amount) public payable virtual override {}

    /**
     * @dev must be implemented in inherited classes
     */
    function withdraw(uint256 _amount) public virtual override {}

    function _assetBalance(address _asset) internal view returns (uint256) {
        return _asset == address(0) ? address(this).balance : IERC20(_asset).balanceOf(address(this));
    }

    function _weightsSum(uint24[] memory weights) internal view returns(uint24 sum) {
        for (uint256 i; i < weights.length; ++i) {
            sum += weights[i];
        }
    }
}

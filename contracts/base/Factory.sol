pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IPoolStorage.sol';
import '../libraries/KedrLib.sol';
import '../pools/Pool.sol';
import './PoolStorage.sol';

contract Factory is Ownable, ReentrancyGuard {
    address public defaultFeeReceiver; // default feeReceiver is used during each deployment of poolStorage
    address public swapper;
    address[] public pools;
    address[] public poolStorages;

    event PoolCreated(address _address, uint256 _id);
    event PoolStorageCreated(address _address, uint256 _id);

    constructor(address _defaultFeeReceiver, address _swapper) {
        require(_defaultFeeReceiver != address(0) && _swapper != address(0), 'ZERO_ADDRESS');
        defaultFeeReceiver = _defaultFeeReceiver;
        swapper = _swapper;
    }

    function poolsCount() external view returns (uint256) {
        return pools.length;
    }

    function poolsStorageCount() external view returns (uint256) {
        return poolStorages.length;
    }

    /**
     * The main function for Pool Creation. Creates new Pool & PoolStorage and link each other.
     */
    function create(IPool.PoolDetails memory poolDetails, address _entryAsset)
        external
        onlyOwner
        returns (address pool, address poolStorage)
    {
        poolStorage = _createPoolStorage(_entryAsset);
        pool = createPool(poolDetails, swapper);
        _link(pool, poolStorage);
    }

    /**
     * This function is used to switch on new Pool
     * IMPORTANT: It's going to move all funds from old Pool to the new one.
     */
    function switchStorageToNewPool(address _newPool, address _poolStorage) external onlyOwner {
        address oldPool = IPoolStorage(_poolStorage).pool();
        IPool(oldPool).moveFunds(_newPool);
        IPool(oldPool).unlink();
        IPool(_newPool).link(_poolStorage);
        IPoolStorage(_poolStorage).link(_newPool);
    }

    /**
     * Creates new Pool without linking to storage
     */
    function createPool(IPool.PoolDetails memory poolDetails, address _swapper) public returns (address pool) {
        uint256 poolId = pools.length + 1;
        bytes memory poolBytecode = abi.encodePacked(type(Pool).creationCode, abi.encode(poolId, _swapper));
        pool = KedrLib.deploy(poolBytecode);
        IPool(pool).initialize(poolDetails);
        pools.push(pool);
        emit PoolCreated(pool, poolId);
    }

    /**
     * Creates new PoolStorage without linking to Pool
     */
    function _createPoolStorage(address _entryAsset) internal returns (address poolStorage) {
        uint256 id = poolStorages.length + 1;
        string memory entrySymbol = IERC20Metadata(_entryAsset).symbol();
        bytes memory symbol = abi.encodePacked('k', entrySymbol);
        bytes memory name = abi.encodePacked('KEDR_', entrySymbol);
        bytes memory storageBytecode = abi.encodePacked(type(PoolStorage).creationCode, abi.encode(id, _entryAsset, defaultFeeReceiver, symbol, name));
        poolStorage = KedrLib.deploy(storageBytecode);
        poolStorages.push(poolStorage);
        emit PoolStorageCreated(poolStorage, id);
    }

    /**
     * Links pool and poolStorage.
     */
    function _link(address _pool, address _poolStorage) internal {
        IPoolStorage(_poolStorage).link(_pool);
        IPool(_pool).link(_poolStorage);
    }

    // ADMIN SETTERS:

    function setDefaultFeeReceiver(address _receiver) external onlyOwner {
        require(_receiver != address(0), 'ZERO_ADDRESS');
        defaultFeeReceiver = _receiver;
    }

    function setFeeReceiver(address _poolStorage, address _receiver) external onlyOwner {
        IPoolStorage(_poolStorage).setFeeReceiver(_receiver);
    }

    function updateAllocations(address _pool, uint24[] memory _weights) external onlyOwner {
        IPool(_pool).updateAllocations(_weights);
    }

    function setWeight(address _pool, address asset, uint24 weight) external onlyOwner {
        IPool(_pool).setWeight(asset, weight);
    }
}

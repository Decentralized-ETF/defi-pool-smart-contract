pragma solidity >=0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IPoolStorage.sol';
import '../pools/Pool.sol';
import './PoolStorage.sol';

contract Factory is Ownable, ReentrancyGuard {
    address public feeReceiver; // default feeReceiver is used during each deployment of poolStorage
    address[] public pools;
    address[] public poolStorages;

    event PoolCreated(address _address, uint256 _id);
    event PoolStorageCreated(address _address, uint256 _id);

    constructor(address _feeReceiver) {
        require(_feeReceiver != address(0), 'ZERO_ADDRESS');
        feeReceiver = _feeReceiver;
    }

    function poolsCount() external view returns (uint256) {
        return pools.length;
    }

    /**
     * The main function for Pool Creation. Creates new Pool & PoolStorage and link each other. 
     */
    function create(
        IPool.PoolDetails memory poolDetails,
        address _entryAsset
    ) external onlyOwner returns (address pool, address poolStorage) {
        poolStorage = _createPoolStorage(_entryAsset);
        pool = _createPool(poolDetails, poolStorage);
        IPoolStorage(poolStorage).initialize(pool);
    }

    
    function setDefaultFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), 'ZERO_ADDRESS');
        feeReceiver = _feeReceiver;
    }

        /**
     * Creates new Pool and link it with existing poolStorage, poolStorage can be updated later
     */
    function _createPool(
        IPool.PoolDetails memory poolDetails,
        address _poolStorage
    ) internal returns (address pool) {
        uint256 poolId = pools.length + 1;
        bytes memory poolBytecode = abi.encodePacked(type(Pool).creationCode, poolId);
        pool = _deploy(poolBytecode);
        IPool(pool).initialize(poolDetails, _poolStorage);
        pools.push(pool);
        emit PoolCreated(pool, poolId);
    }

    /**
     * Creates new PoolStorage without linking to Pool
     */
    function _createPoolStorage(
        address _entryAsset
    ) internal returns (address poolStorage) {
        uint256 id = poolStorages.length + 1;
        string memory entrySymbol = IERC20Metadata(_entryAsset).symbol();
        bytes memory symbol = abi.encodePacked("k", entrySymbol);
        bytes memory name = abi.encodePacked("KEDR_", entrySymbol);
        bytes memory storageBytecode = abi.encodePacked(type(PoolStorage).creationCode, id, _entryAsset, feeReceiver, name, symbol);
        poolStorage = _deploy(storageBytecode);
        poolStorages.push(poolStorage);
        emit PoolStorageCreated(poolStorage, id);
    }

    /**
     * @dev deploys new contract using create2 with check of deployment
     */
    function _deploy(bytes memory bytecode) internal returns (address _contract) {
        assembly {
            _contract := create2(0, add(bytecode, 32), mload(bytecode), "")
            if iszero(extcodesize(_contract)) {
                revert(0, 0)
            }
        }
        return _contract;
    }
}

pragma solidity >=0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IPoolStorage.sol";
import "../pools/Pool.sol";
import "./PoolStorage.sol";

contract Factory is Ownable, ReentrancyGuard {
    address public feeReceiver;
    address[] public pools;

    event PoolCreated(address _pool, uint256 _poolId, address _poolStorage);

    constructor(address _feeReceiver) {
        require(_feeReceiver != address(0), "ZERO_ADDRESS");
        feeReceiver = _feeReceiver;
    }

    function poolsLength() external view returns (uint256) {
        return pools.length;
    }

    function createPool(IPool.PoolDetails poolDetails, address _entryAsset, address _feeReceiver)
        external
        returns (address pool, address poolStorage)
    {
        uint256 poolId = pools.length + 1;
        bytes memory poolBytecode = abi.encodePacked(
            type(Pool).creationCode,
            poolId // constructor parameter
        );

        assembly {
            pool := create2(0, add(bytecode, 32), mload(poolBytecode))
            if iszero(extcodesize(pool)) {
                revert(0, 0)
            }
        }

        bytes memory storageBytecode = abi.encodePacked(
            type(PoolStorage).creationCode,
            poolId // constructor parameter
        );

        assembly {
            poolStorage := create2(0, add(bytecode, 32), mload(storageBytecode))
            if iszero(extcodesize(poolStorage)) {
                revert(0, 0)
            }
        }

        IPool(pool).initialize(poolDetails, poolStorage);
        IPoolStorage(poolStorage).initialize(_entryAsset, _feeReceiver);
        pools.push(pool);
        emit PoolCreated(pool, poolId, poolStorage);
    }

    function setDefaultFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "ZERO_ADDRESS");
        feeReceiver = _feeReceiver;
    }
}

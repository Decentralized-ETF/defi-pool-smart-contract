pragma solidity >=0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPool.sol";
import "../pools/Pool.sol";

contract Factory is Ownable, ReentrancyGuard {
    address public feeReceiver;
    address[] public pools;

    event PoolCreated(address pool, uint256 poolId);

    constructor(address _feeReceiver) {
        require(_feeReceiver != address(0), "ZERO_ADDRESS");
        feeReceiver = _feeReceiver;
    }

    function poolsLength() external view returns (uint256) {
        return pools.length;
    }

    function createPool(IPool.PoolDetails poolDetails)
        external
        returns (address pool)
    {
        uint256 poolId = pools.length + 1;
        bytes memory bytecode = abi.encodePacked(
            type(Pool).creationCode,
            poolId // constructor parameter
        );

        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode))
            if iszero(extcodesize(pool)) {
                revert(0, 0)
            }
        }

        IPool(pool).initialize(poolDetails);
        pools.push(pool);
        emit PoolCreated(pool, poolId);
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

interface IPool {
    struct PoolDetails {
        uint256 minInvestment;
        address[] assets;
        uint24[] weights;
        uint16 entryFee;
        uint16 successFee;
    }

    struct PoolStorageDetails {
        string name;
        string symbol;
        address entryAsset;
    }

    function initialize(PoolDetails calldata _poolDetails) external;

    function link(address _poolStorage) external;

    function moveFunds(address _newPool) external;

    function entryFee() external view returns (uint16);

    function factory() external view returns (address);

    function successFee() external view returns (uint16);

    function minInvestment() external view returns (uint256);

    function poolStorage() external view returns (address);

    function poolId() external view returns (uint64);

    function invest(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function setWeight(address asset, uint24 weight) external; // updates allocation for specific token in pool

    function updateAllocations(uint24[] memory weights) external; // updates allocations for all tokens in pool

    function rebalance() external; // makes trades to get current allocation

    function details() external view returns (PoolDetails memory);

    function poolSize() external view returns (uint256);
}

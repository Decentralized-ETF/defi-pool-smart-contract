//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

interface IPool {
    struct PoolDetails {
        address swapper; //todo: setter for swapper
        uint256 minInvestment;
        address[] assets;
        uint24[] weights;
        uint16 entryFee;
        uint16 successFee;
        bool balanceable;
    }

    struct PoolStorageDetails {
        string name;
        string symbol;
        address entryAsset;
    }

    function initialize(PoolDetails calldata _poolDetails) external;

    function link(address _poolStorage) external;

    function unlink() external;

    function moveFunds(address _newPool) external;

    function totalValue() external returns (uint256);

    function entryAsset() external view returns (address);

    function factory() external view returns (address);

    function poolStorage() external view returns (address);

    function poolId() external view returns (uint64);

    function invest(address investor, uint256 amount) external payable;

    function withdraw(uint256 amount) external;

    function withdrawAll() external;

    function setWeight(address asset, uint24 weight) external; // updates allocation for specific token in pool

    function updateAllocations(uint24[] memory weights) external; // updates allocations for all tokens in pool

    function details() external view returns (PoolDetails memory);

    function poolSize() external view returns (uint256);
}

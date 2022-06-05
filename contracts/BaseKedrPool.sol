//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

contract BaseKedrPool {

 event Invested(
        address indexed user,
        uint256 maticAmount,
        uint256[] tokenBalances,
        uint24[] tokenDistribution
    );

    event UnInvested(
        address indexed user,
        uint256 maticAmount,
        uint16 investmentId
    );

    event Rebalanced(
        address indexed user,
        uint16 investmentId,
        uint256[] tokenBalances,
        uint24[] tokenDistribution
    );

    event Received(address sender, uint256 amount);
}
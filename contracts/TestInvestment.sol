//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract TestInvestment is ReentrancyGuard, Ownable, Pausable {
    struct InvestmentData {
        uint256 maticReceived;
        uint256 maticForSwap;
        uint256 token0Balance;
        uint256 token1Balance;
        uint256 token2Balance;
        bool rebalanceEnabled;
    }

    mapping(address => InvestmentData[]) private investmentDataByUser;

    event Invested(
        address indexed user,
        uint256 maticAmount,
        uint256 token0Balance,
        uint256 token1Balance,
        uint256 token2Balance
    );

    event UnInvested(address indexed user, uint256 maticAmount);

    event Rebalanced(
        address indexed user,
        uint256 investmentId,
        uint256 token0Balance,
        uint256 token1Balance,
        uint256 token2Balance
    );

    event Received(address sender, uint256 amount);

    uint256 private totalMaticReceived = 0;
    uint256 private totalToken0InPool = 0;
    uint256 private totalMATICSwappedToken0 = 0;
    uint256 private totalToken1InPool = 0;
    uint256 private totalMATICSwappedToken1 = 0;
    uint256 private totalToken2InPool = 0;
    uint256 private totalMATICSwappedToken2 = 0;

    struct PoolData {
        uint256 totalMaticReceived;
        uint256 totalToken0InPool;
        uint256 totalMATICSwappedToken0;
        uint256 totalToken1InPool;
        uint256 totalMATICSwappedToken1;
        uint256 totalToken2InPool;
        uint256 totalMATICSwappedToken2;
    }

    address[] poolTokens;
    uint256[] poolTokenPercentages;

    constructor(
        address[] memory _poolTokens,
        uint256[] memory _poolTokenPercentages
    ) public Ownable() {
        poolTokens = _poolTokens;
        _poolTokenPercentages = poolTokenPercentages;
    }

    function initInvestment() external payable whenNotPaused {
        require(msg.value > 0, "send matic");

        uint256 swapValueToken0 = (msg.value * poolTokenPercentages[0]) / 100;
        uint256 swapValueToken1 = (msg.value * poolTokenPercentages[1]) / 100;
        uint256 swapValueToken2 = (msg.value * poolTokenPercentages[2]) / 100;

        investmentDataByUser[msg.sender].push(
            InvestmentData({
                maticReceived: msg.value,
                maticForSwap: 0,
                token0Balance: swapValueToken0,
                token1Balance: swapValueToken1,
                token2Balance: swapValueToken2,
                rebalanceEnabled: true
            })
        );

        emit Invested(
            msg.sender,
            msg.value,
            swapValueToken0,
            swapValueToken1,
            swapValueToken2
        );
    }

    function finishInvestment(uint256 investmentId) external {
        require(investmentId >= 0, "please specify a valid investment Id");
    }

    function getMyInvestment(uint256 investmentId)
        public
        view
        virtual
        returns (InvestmentData memory)
    {
        require(investmentId >= 0, "please specify a valid investment Id");

        return investmentDataByUser[msg.sender][investmentId];
    }

    function rebalance(address user, uint256 investmentId) external {
        require(investmentId >= 0, "please specify a valid investment Id");
        require(
            investmentDataByUser[user][investmentId].rebalanceEnabled == true,
            "rebalance function is not enabled for this investment"
        );

        uint256 maticForSwap = investmentDataByUser[user][investmentId]
            .token0Balance +
            investmentDataByUser[user][investmentId].token1Balance +
            investmentDataByUser[user][investmentId].token2Balance;

        uint256 swapValueToken0 = (maticForSwap * poolTokenPercentages[0]) / 100;
        uint256 swapValueToken1 = (maticForSwap * poolTokenPercentages[1]) / 100;
        uint256 swapValueToken2 = (maticForSwap * poolTokenPercentages[2]) / 100;

        investmentDataByUser[user][investmentId].token0Balance = swapValueToken0;
        investmentDataByUser[user][investmentId].token1Balance = swapValueToken1;
        investmentDataByUser[user][investmentId].token2Balance = swapValueToken2;

        emit Rebalanced(user, investmentId, swapValueToken0, swapValueToken1, swapValueToken2);
    }

    function getMyInvestments()
        public
        view
        virtual
        returns (InvestmentData[] memory)
    {
        return investmentDataByUser[msg.sender];
    }

    function getPoolData()
        public
        view
        virtual
        onlyOwner
        returns (PoolData memory)
    {
        PoolData memory pooData = PoolData({
            totalMaticReceived: totalMaticReceived,
            totalToken0InPool: totalToken0InPool,
            totalToken1InPool: totalToken1InPool,
            totalToken2InPool: totalToken2InPool,
            totalMATICSwappedToken0: totalMATICSwappedToken0,
            totalMATICSwappedToken1: totalMATICSwappedToken1,
            totalMATICSwappedToken2: totalMATICSwappedToken2
        });
        return pooData;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

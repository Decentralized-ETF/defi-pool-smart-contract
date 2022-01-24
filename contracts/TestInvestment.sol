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
        uint256 wethBalance;
        uint256 wethPercent;
        uint256 avaxBalance;
        uint256 avaxPercent;
        uint256 wbtcBalance;
        uint256 wbtcPercent;
        bool rebalanceEnabled;
    }

    mapping(address => InvestmentData[]) private investmentDataByUser;

    event Invested(address indexed user, uint256 maticAmount);

    event UnInvested(address indexed user, uint256 maticAmount);

    event Rebalanced(address indexed user, uint256 investmentId);

    event Received(address sender, uint256 amount);

    uint256 private totalMaticReceived = 0;
    uint256 private totalAVAXInPool = 0;
    uint256 private totalMATICSwappedAVAX = 0;
    uint256 private totalWETHInPool = 0;
    uint256 private totalMATICSwappedWETH = 0;
    uint256 private totalWBTCInPool = 0;
    uint256 private totalMATICSwappedWBTC = 0;

    struct PoolData {
        uint256 totalMaticReceived;
        uint256 totalAVAXInPool;
        uint256 totalMATICSwappedAVAX;
        uint256 totalWETHInPool;
        uint256 totalMATICSwappedWETH;
        uint256 totalWBTCInPool;
        uint256 totalMATICSwappedWBTC;
    }

    constructor() public Ownable() {}

    function initInvestment() external payable whenNotPaused {
        require(msg.value > 0, "send matic");

        uint256 swapValueAVAX = (msg.value * 20) / 100;
        uint256 swapValueWBTC = (msg.value * 40) / 100;
        uint256 swapValueWETH = (msg.value * 40) / 100;

        investmentDataByUser[msg.sender].push(
            InvestmentData({
                maticReceived: msg.value,
                maticForSwap: 0,
                wethBalance: swapValueWETH,
                wethPercent: 40,
                avaxBalance: swapValueAVAX,
                avaxPercent: 20,
                wbtcBalance: swapValueWBTC,
                wbtcPercent: 40,
                rebalanceEnabled: true
            })
        );

        emit Invested(msg.sender, msg.value);
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

    function rebalance(
        address user,
        uint256 investmentId
    ) external {
        require(investmentId >= 0, "please specify a valid investment Id");
        require(
            investmentDataByUser[user][investmentId].rebalanceEnabled == true,
            "rebalance function is not enabled for this investment"
        );
      
        uint256 maticForSwap = investmentDataByUser[user][investmentId]
            .wethBalance +
            investmentDataByUser[user][investmentId].avaxBalance +
            investmentDataByUser[user][investmentId].wbtcBalance;

        uint256 swapValueAVAX = (maticForSwap * 50) / 100;
        uint256 swapValueWBTC = (maticForSwap * 25) / 100;
        uint256 swapValueWETH = (maticForSwap * 25) / 100;

        investmentDataByUser[user][investmentId].wethBalance= swapValueWETH;
        investmentDataByUser[user][investmentId].avaxBalance= swapValueAVAX;
        investmentDataByUser[user][investmentId].wbtcBalance= swapValueWBTC;

        investmentDataByUser[user][investmentId].wethPercent= 25;
        investmentDataByUser[user][investmentId].avaxPercent= 50;
        investmentDataByUser[user][investmentId].wbtcPercent= 25;

        emit Invested(user, investmentId);
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
            totalAVAXInPool: totalAVAXInPool,
            totalWETHInPool: totalWETHInPool,
            totalWBTCInPool: totalWBTCInPool,
            totalMATICSwappedAVAX: totalMATICSwappedAVAX,
            totalMATICSwappedWETH: totalMATICSwappedWETH,
            totalMATICSwappedWBTC: totalMATICSwappedWBTC
        });
        return pooData;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
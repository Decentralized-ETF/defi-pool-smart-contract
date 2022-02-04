//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract TestInvestment is ReentrancyGuard, Ownable, Pausable {
    struct InvestmentData {
        uint256 maticReceived;
        uint256 token0Balance;
        uint256 token1Balance;
        uint256 token2Balance;
        bool rebalanceEnabled;
        bool active;
    }

    mapping(address => InvestmentData[]) private investmentDataByUser;

    event Invested(
        address indexed user,
        uint256 maticAmount,
        uint256 token0Balance,
        uint256 token1Balance,
        uint256 token2Balance
    );

    event UnInvested(
        address indexed user,
        uint256 maticAmount,
        uint16 investmentId
    );

    event Rebalanced(
        address indexed user,
        uint16 investmentId,
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
    uint24[] poolTokenPercentages;

    ISwapRouter public immutable swapRouter;

    uint24 fee = 3000;

    address wMaticTokenAddress;

    constructor(
        address _swapRouterContractAddress,
        address _wMaticTokenAddress,
        address[] memory _poolTokens,
        uint24[] memory _poolTokenPercentages
    ) public Ownable() {
        swapRouter = ISwapRouter(_swapRouterContractAddress);
        poolTokens = _poolTokens;
        poolTokenPercentages = _poolTokenPercentages;
        wMaticTokenAddress = _wMaticTokenAddress;
    }

    function initInvestment() external payable whenNotPaused {
        require(msg.value > 0, "send matic");

        uint256 inputAmountForToken0 = (msg.value * poolTokenPercentages[0]) /
            100;
        uint256 inputAmountForToken1 = (msg.value * poolTokenPercentages[1]) /
            100;
        uint256 inputAmountForToken2 = (msg.value * poolTokenPercentages[2]) /
            100;

        uint256 outputAmountForToken0 = _swap(
            wMaticTokenAddress,
            poolTokens[0],
            block.timestamp + 15,
            inputAmountForToken0
        );
        uint256 outputAmountForToken1 = _swap(
            wMaticTokenAddress,
            poolTokens[1],
            block.timestamp + 30,
            inputAmountForToken1
        );
        uint256 outputAmountForToken2 = _swap(
            wMaticTokenAddress,
            poolTokens[2],
            block.timestamp + 45,
            inputAmountForToken2
        );

        investmentDataByUser[msg.sender].push(
            InvestmentData({
                maticReceived: msg.value,
                token0Balance: outputAmountForToken0,
                token1Balance: outputAmountForToken1,
                token2Balance: outputAmountForToken2,
                rebalanceEnabled: true,
                active: true
            })
        );

        emit Invested(
            msg.sender,
            msg.value,
            outputAmountForToken0,
            outputAmountForToken1,
            outputAmountForToken2
        );
    }

    function finishInvestment(uint16 investmentId) external whenNotPaused {
        require(investmentId >= 0, "please specify a valid investment Id");
        require(
            investmentDataByUser[msg.sender][investmentId].active == true,
            "Investment is not active"
        );

        uint256 inputAmountFromToken0 = investmentDataByUser[msg.sender][
            investmentId
        ].token0Balance;

        uint256 inputAmountFromToken1 = investmentDataByUser[msg.sender][
            investmentId
        ].token1Balance;

        uint256 inputAmountFromToken2 = investmentDataByUser[msg.sender][
            investmentId
        ].token2Balance;


         uint256 outputAmountFromToken0 = _swap(
            poolTokens[0],
            wMaticTokenAddress,
            block.timestamp + 15,
            inputAmountFromToken0
        );

         uint256 outputAmountFromToken1 = _swap(
            poolTokens[1],
            wMaticTokenAddress,
            block.timestamp +30,
            inputAmountFromToken1
        );

         uint256 outputAmountFromToken2 = _swap(
            poolTokens[2],
            wMaticTokenAddress,
            block.timestamp + 45,
            inputAmountFromToken2
        );

        uint256 returnedMatic = outputAmountFromToken0 +
            outputAmountFromToken1 +
            outputAmountFromToken2;
        Address.sendValue(payable(msg.sender), returnedMatic);

        investmentDataByUser[msg.sender][investmentId].active = false;
        emit UnInvested(msg.sender, returnedMatic,investmentId);
    }

    function setPoolTokensDistributions(uint24[] memory poolDistributions)
        external
        onlyOwner
    {
        poolTokenPercentages = poolDistributions;
    }

    function setFee(uint24 _fee)
        external
        onlyOwner
    {
        fee = _fee;
    }

    function getFee()
        public
        view
        virtual
        returns (uint24)
    {
        return fee;
    }

    function getPoolTokens() public view virtual returns (address[] memory) {
        return poolTokens;
    }

    function getPoolTokensDistributions()
        public
        view
        virtual
        returns (uint24[] memory)
    {
        return poolTokenPercentages;
    }

    function getMyInvestment(uint16 investmentId)
        public
        view
        virtual
        returns (InvestmentData memory)
    {
        require(investmentId >= 0, "please specify a valid investment Id");

        return investmentDataByUser[msg.sender][investmentId];
    }

    function rebalance(uint16 investmentId) external whenNotPaused {
        require(investmentId >= 0, "please specify a valid investment Id");
        InvestmentData memory data = investmentDataByUser[msg.sender][
            investmentId
        ];
        require(
            data.rebalanceEnabled == true,
            "rebalance function is not enabled for this investment"
        );

        //First we should swap all tokens to matic
        uint256 outputAmountFromToken0 = _swap(
            poolTokens[0],
            wMaticTokenAddress,
            block.timestamp + 15,
            data.token0Balance
        );
        uint256 outputAmountFromToken1 = _swap(
            poolTokens[1],
            wMaticTokenAddress,
            block.timestamp + 30,
            data.token1Balance
        );
        uint256 outputAmountFromToken2 = _swap(
            poolTokens[2],
            wMaticTokenAddress,
            block.timestamp + 45,
            data.token2Balance
        );

        // Second Apply new distributions
        uint256 allSwappedMatic = outputAmountFromToken0 +
            outputAmountFromToken1 +
            outputAmountFromToken2;

        uint256 outputAmountForToken0 = _swap(
            wMaticTokenAddress,
            poolTokens[0],
            block.timestamp + 15,
            (allSwappedMatic * poolTokenPercentages[0]) / 100
        );

        uint256 outputAmountForToken1 = _swap(
            wMaticTokenAddress,
            poolTokens[1],
            block.timestamp + 30,
            (allSwappedMatic * poolTokenPercentages[1]) / 100
        );

        uint256 outputAmountForToken2 = _swap(
            wMaticTokenAddress,
            poolTokens[2],
            block.timestamp + 45,
            (allSwappedMatic * poolTokenPercentages[2]) / 100
        );

        data.token0Balance = outputAmountForToken0;
        data.token1Balance = outputAmountForToken1;
        data.token2Balance = outputAmountForToken2;

        emit Rebalanced(
            msg.sender,
            investmentId,
            outputAmountForToken0,
            outputAmountForToken1,
            outputAmountForToken2
        );
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

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 timestamp,
        uint256 amount
    ) internal returns (uint256) {
        ISwapRouter.ExactInputSingleParams memory paramsForSwap = ISwapRouter
            .ExactInputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                address(this),
                timestamp,
                amount,
                0,
                0
            );

        return swapRouter.exactInputSingle{value: amount}(paramsForSwap);
    }
}

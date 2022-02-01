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
        uint256 maticForSwap;
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

    event UnInvested(address indexed user, uint256 maticAmount);

    event Rebalanced(
        address indexed user,
        //uint256 investmentId,
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

        uint256 deadline0 = block.timestamp + 15;
        address recipient = address(this);
        uint256 amountOutMinimum = 0;
        uint160 sqrtPriceLimitX96 = 0;

        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapToToken0 = ISwapRouter.ExactInputSingleParams(
                wMaticTokenAddress,
                poolTokens[0],
                fee,
                recipient,
                deadline0,
                inputAmountForToken0,
                amountOutMinimum,
                sqrtPriceLimitX96
            );

        uint256 outputAmountForToken0 = swapRouter.exactInputSingle{
            value: inputAmountForToken0
        }(paramsForSwapToToken0);

        uint256 deadline1 = block.timestamp + 30;

        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapToToken1 = ISwapRouter.ExactInputSingleParams(
                wMaticTokenAddress,
                poolTokens[1],
                fee,
                recipient,
                deadline1,
                inputAmountForToken1,
                amountOutMinimum,
                sqrtPriceLimitX96
            );

        uint256 outputAmountForToken1 = swapRouter.exactInputSingle{
            value: inputAmountForToken1
        }(paramsForSwapToToken1);

        uint256 deadline2 = block.timestamp + 45;
        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapToToken2 = ISwapRouter.ExactInputSingleParams(
                wMaticTokenAddress,
                poolTokens[2],
                fee,
                recipient,
                deadline2,
                inputAmountForToken2,
                amountOutMinimum,
                sqrtPriceLimitX96
            );

        uint256 outputAmountForToken2 = swapRouter.exactInputSingle{
            value: inputAmountForToken2
        }(paramsForSwapToToken2);

        investmentDataByUser[msg.sender].push(
            InvestmentData({
                maticReceived: msg.value,
                maticForSwap: 0,
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

    function finishInvestment(uint256 investmentId) external whenNotPaused {
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

        uint256 deadline0 = block.timestamp + 15;

        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapFromToken0 = ISwapRouter.ExactInputSingleParams(
                poolTokens[0],
                wMaticTokenAddress,
                fee,
                address(this),
                deadline0,
                inputAmountFromToken0,
                0,
                0
            );

        uint256 outputAmountFromToken0 = swapRouter.exactInputSingle{
            value: inputAmountFromToken0
        }(paramsForSwapFromToken0);

        uint256 deadline1 = block.timestamp + 30;
        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapFromToken1 = ISwapRouter.ExactInputSingleParams(
                poolTokens[1],
                wMaticTokenAddress,
                fee,
                address(this),
                deadline1,
                inputAmountFromToken1,
                0,
                0
            );

        uint256 outputAmountFromToken1 = swapRouter.exactInputSingle{
            value: inputAmountFromToken1
        }(paramsForSwapFromToken1);

        uint256 deadline2 = block.timestamp + 30;
        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapFromToken2 = ISwapRouter.ExactInputSingleParams(
                poolTokens[2],
                wMaticTokenAddress,
                fee,
                address(this),
                deadline2,
                inputAmountFromToken2,
                0,
                0
            );

        uint256 outputAmountFromToken2 = swapRouter.exactInputSingle{
            value: inputAmountFromToken2
        }(paramsForSwapFromToken2);

        uint256 returnedMatic = outputAmountFromToken0 +
            outputAmountFromToken1 +
            outputAmountFromToken2;
        Address.sendValue(payable(msg.sender), returnedMatic);

        investmentDataByUser[msg.sender][investmentId].active = false;
        emit UnInvested(msg.sender, returnedMatic);
    }

    function setPoolTokensDistributions(uint24[] memory poolDistributions)
        external
        onlyOwner
    {
        poolTokenPercentages = poolDistributions;
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

    function getMyInvestment(uint256 investmentId)
        public
        view
        virtual
        returns (InvestmentData memory)
    {
        require(investmentId >= 0, "please specify a valid investment Id");

        return investmentDataByUser[msg.sender][investmentId];
    }

    function rebalance(uint256 investmentId) external whenNotPaused {
        require(investmentId >= 0, "please specify a valid investment Id");
        InvestmentData memory data = investmentDataByUser[msg.sender][
            investmentId
        ];
        require(
            data.rebalanceEnabled == true,
            "rebalance function is not enabled for this investment"
        );

        //First we should swap all tokens to matic

        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapFromToken0 = ISwapRouter.ExactInputSingleParams(
                poolTokens[0],
                wMaticTokenAddress,
                fee,
                address(this),
                block.timestamp + 15,
                data.token0Balance,
                0,
                0
            );

        uint256 outputAmountFromToken0 = swapRouter.exactInputSingle{
            value: data.token0Balance
        }(paramsForSwapFromToken0);

        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapFromToken1 = ISwapRouter.ExactInputSingleParams(
                poolTokens[1],
                wMaticTokenAddress,
                fee,
                address(this),
                block.timestamp + 30,
                data.token1Balance,
                0,
                0
            );

        uint256 outputAmountFromToken1 = swapRouter.exactInputSingle{
            value: data.token1Balance
        }(paramsForSwapFromToken1);

        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapFromToken2 = ISwapRouter.ExactInputSingleParams(
                poolTokens[2],
                wMaticTokenAddress,
                fee,
                address(this),
                block.timestamp + 30,
                data.token2Balance,
                0,
                0
            );

        uint256 outputAmountFromToken2 = swapRouter.exactInputSingle{
            value: data.token2Balance
        }(paramsForSwapFromToken2);

        // Second Apply new distributions
        uint256 allSwappedMatic = outputAmountFromToken0 +
            outputAmountFromToken1 +
            outputAmountFromToken2;

        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapToToken0 = ISwapRouter.ExactInputSingleParams(
                wMaticTokenAddress,
                poolTokens[0],
                fee,
                address(this),
                block.timestamp + 15,
                (allSwappedMatic * poolTokenPercentages[0]) / 100,
                0,
                0
            );

        uint256 outputAmountForToken0 = swapRouter.exactInputSingle{
            value: (allSwappedMatic * poolTokenPercentages[0]) / 100
        }(paramsForSwapToToken0);

        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapToToken1 = ISwapRouter.ExactInputSingleParams(
                wMaticTokenAddress,
                poolTokens[1],
                fee,
                address(this),
                block.timestamp + 30,
                (allSwappedMatic * poolTokenPercentages[1]) / 100,
                0,
                0
            );

        uint256 outputAmountForToken1 = swapRouter.exactInputSingle{
            value: (allSwappedMatic * poolTokenPercentages[1]) / 100
        }(paramsForSwapToToken1);

        ISwapRouter.ExactInputSingleParams
            memory paramsForSwapToToken2 = ISwapRouter.ExactInputSingleParams(
                wMaticTokenAddress,
                poolTokens[2],
                fee,
                address(this),
                block.timestamp + 45,
                (allSwappedMatic * poolTokenPercentages[2]) / 100,
                0,
                0
            );

        uint256 outputAmountForToken2 = swapRouter.exactInputSingle{
            value: (allSwappedMatic * poolTokenPercentages[2]) / 100
        }(paramsForSwapToToken2);

        data.token0Balance = outputAmountForToken0;
        data.token1Balance = outputAmountForToken1;
        data.token2Balance = outputAmountForToken2;

        emit Rebalanced(
            msg.sender,
            //investmentId,
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
}

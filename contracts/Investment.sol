//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Investment is ReentrancyGuard, Ownable {
/*
    using Counters for Counters.Counter;
    Counters.Counter private _investmentIds;
    uint256 public minInvestmentAmount = 1 ether; // should be at least 1
    mapping(address => InvestmentData[]) private investmentDataByUser;
    struct UserInvestmentData {
        uint256 totalMaticUserInvested;
        uint256 firstActiveInvestmentIndex; // for gas optimization if many investments
        InvestmentData[] investments;
    }
    struct InvestmentData {
        bool active;
        uint256 id;
        uint256 createdAtBlock;
        uint256 updatedAtBlock;
        uint256 maticReceived;
        uint256 wethBalance;
        uint256 avaxBalance;
        uint256 wbtcBalance;
    }
    event Invested(
        address indexed user,
        uint256 maticAmount
    );
    event UnInvested(
        address indexed user,
        uint256 maticAmount
    );
    event Received(
        address sender,
        uint amount);
    uint24 public constant poolFee = 3000;
    address public constant MATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant WBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address public constant AVAX = 0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b;
    address public constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public constant MAI = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;
    address public constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address internal constant QUICKSWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    IUniswapV2Router02 public immutable router;
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
    constructor() public Ownable() {
        router = IUniswapV2Router02(QUICKSWAP_ROUTER_ADDRESS);
    }
    function initInvestment() external payable {
        require(msg.value > 0, "send matic");
        address[] memory path1 = new address[](3);
        path1[0] = MATIC;
        path1[1] = USDC;
        path1[2] = AVAX;
        uint256 swapPercentValueAVAX = msg.value * 20 / 100;
        uint256[] memory amountOutMins1 = router.getAmountsOut(swapPercentValueAVAX, path1);
        uint[] memory amounts1 = router.swapExactETHForTokens{value : swapPercentValueAVAX}(
            amountOutMins1[path1.length - 1],
            path1,
            address(this),
            block.timestamp
        );
        uint256 finalAVAXSwapped = amounts1[path1.length - 1];
        totalAVAXInPool += finalAVAXSwapped;
        totalMATICSwappedAVAX += swapPercentValueAVAX;
        address[] memory path2 = new address[](4);
        path2[0] = MATIC;
        path2[1] = MAI;
        path2[2] = DAI;
        path2[3] = WBTC;
        uint256 swapPercentValueWBTC = msg.value * 40 / 100;
        uint256[] memory amountOutMins2 = router.getAmountsOut(swapPercentValueWBTC, path2);
        uint[] memory amounts2 = router.swapExactETHForTokens{value : swapPercentValueWBTC}(
            amountOutMins2[path2.length - 1],
            path2,
            address(this),
            block.timestamp
        );
        uint256 finalWBTCSwapped = amounts2[path2.length - 1];
        totalWBTCInPool += finalWBTCSwapped;
        totalMATICSwappedWBTC += swapPercentValueWBTC;
        address[] memory path3 = new address[](4);
        path3[0] = MATIC;
        path3[1] = MAI;
        path3[2] = QUICK;
        path3[3] = WETH;
        uint256 swapPercentValueWETH = msg.value * 40 / 100;
        uint256[] memory amountOutMins3 = router.getAmountsOut(swapPercentValueWETH, path3);
        uint[] memory amounts3 = router.swapExactETHForTokens{value : swapPercentValueWETH}(
            amountOutMins3[path3.length - 1],
            path3,
            address(this),
            block.timestamp
        );
        uint256 finalWETHSwapped = amounts3[path3.length - 1];
        totalWETHInPool += finalWETHSwapped;
        totalMATICSwappedWETH += swapPercentValueWETH;
        _investmentIds.increment();
        uint256 newInvestmentId = _investmentIds.current();
        UserInvestmentData storage userInvestmentData = investmentDataByUser[msg.sender];
        userInvestmentData.investments.push(InvestmentData({
        id : newInvestmentId,
        active : true,
        maticReceived : msg.value,
        createdAtBlock : block.timestamp,
        updatedAtBlock : block.timestamp,
        avaxBalance : finalAVAXSwapped,
        wbtcBalance : finalWBTCSwapped,
        wethBalance : finalWETHSwapped
        }));
        userInvestmentData.totalMaticUserInvested += msg.value;
        totalMaticReceived += msg.value;
        emit Invested(msg.sender, msg.value);
    }
    function finishInvestment(uint256 investmentId) external {
        require(investmentId >= 0, "please specify a valid investment Id");
        InvestmentData memory investmentData = getInvestment(investmentId);
        require(investmentData.active, "this investment is not active");
        uint256 avaxBalance = investmentData.avaxBalance;
        uint256 wethBalance = investmentData.wethBalance;
        uint256 wbtcBalance = investmentData.wbtcBalance;
        require(IERC20(AVAX).approve(address(QUICKSWAP_ROUTER_ADDRESS), avaxBalance), 'avax approval failed');
        address[] memory path1 = new address[](2);
        path1[0] = AVAX;
        path1[1] = MATIC;
        uint256[] memory amountOutMins1 = router.getAmountsOut(avaxBalance, path1);
        uint[] memory amounts1 = router.swapExactTokensForETH(
            avaxBalance,
            amountOutMins1[path1.length - 1],
            path1,
            address(this),
            block.timestamp
        );
        totalAVAXInPool -= avaxBalance;
        totalMATICSwappedAVAX -= amounts1[path1.length - 1];
        require(IERC20(WBTC).approve(address(QUICKSWAP_ROUTER_ADDRESS), wbtcBalance), 'wBTC approval failed');
        address[] memory path2 = new address[](3);
        path2[0] = WBTC;
        path2[1] = WETH;
        path2[2] = MATIC;
        uint256[] memory amountOutMins2 = router.getAmountsOut(wbtcBalance, path2);
        uint[] memory amounts2 = router.swapExactTokensForETH(
            wbtcBalance,
            amountOutMins2[path2.length - 1],
            path2,
            address(this),
            block.timestamp
        );
        totalWBTCInPool -=  wbtcBalance;
        totalMATICSwappedWBTC -= amounts2[path2.length - 1];
        require(IERC20(WETH).approve(address(QUICKSWAP_ROUTER_ADDRESS), wethBalance), 'WETH approval failed');
        address[] memory path3 = new address[](2);
        path3[0] = WETH;
        path3[1] = MATIC;
        uint256[] memory amountOutMins3 = router.getAmountsOut(wethBalance, path3);
        uint[] memory amounts3 = router.swapExactTokensForETH(
            wethBalance,
            amountOutMins3[path3.length - 1],
            path3,
            address(this),
            block.timestamp
        );
        totalWETHInPool -=  wethBalance;
        totalMATICSwappedWETH -= amounts3[path3.length - 1];
        uint256 returnedMatic = amounts1[path1.length - 1] + amounts2[path2.length - 1] + amounts3[path3.length - 1];
        Address.sendValue(payable(msg.sender), returnedMatic);
        totalMaticReceived -= returnedMatic;
        UserInvestmentData storage userInvestmentData = investmentDataByUser[msg.sender];
        userInvestmentData.totalMaticUserInvested -= returnedMatic;
        investmentData.active = false;
        UnInvested(msg.sender,returnedMatic);
    }
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    function getInvestment(uint256 investmentId) public view virtual returns (InvestmentData memory) {
        require(investmentId >= 0, "please specify a valid investment Id");
        UserInvestmentData storage userInvestmentData = investmentDataByUser[msg.sender];
        uint256 i = userInvestmentData.firstActiveInvestmentIndex;
        for (; i < userInvestmentData.investments.length; i++) {
            if (userInvestmentData.investments[i].id == investmentId) {
                return userInvestmentData.investments[i];
            }
        }
        revert('Investment Not found');
    }
    function getMyInvestments() public view virtual returns (UserInvestmentData memory) {
        UserInvestmentData storage userInvestmentData = investmentDataByUser[msg.sender];
        return userInvestmentData;
    }
    function setMinInvestmentAmount(
        uint256 newMinInvestmentAmount
    )
    public
    virtual
    onlyOwner
    nonReentrant
    {
        require(newMinInvestmentAmount > 1, "Minimum investment amount must be at least 1");
        minInvestmentAmount = newMinInvestmentAmount;
    }
    function getPoolData() public virtual onlyOwner returns (PoolData memory)
    {
        PoolData memory pooData = PoolData({
        totalMaticReceived : totalMaticReceived,
        totalAVAXInPool : totalAVAXInPool,
        totalWETHInPool : totalWETHInPool,
        totalWBTCInPool : totalWBTCInPool,
        totalMATICSwappedAVAX : totalMATICSwappedAVAX,
        totalMATICSwappedWETH : totalMATICSwappedWETH,
        totalMATICSwappedWBTC : totalMATICSwappedWBTC
        });
        return pooData;
    }
    */
}
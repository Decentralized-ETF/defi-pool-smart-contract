//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/ISwapper.sol';
import '../libraries/KedrConstants.sol';

contract Swapper is ISwapper {
    mapping(address => uint8) public routerTypes; // router to ROUTER_TYPE
    address[] internal routers; // list of supported routers
    address[] internal routeTokens; // list of tokens to build composite routes if there is no direct pair
    address public defaultRouter; // default router to be used when don't want to spend gas to find best router
    address public uniswapV3quoter; // can be empty if no V3 routers are used
    uint24 internal FEE_500 = 500;
    uint24 internal FEE_3000 = 3000;
    uint24 internal FEE_10000 = 10000;

    constructor(
        address[] memory _routers,
        uint8[] memory _routerTypes,
        address _defaultRouter,
        address _uniswapV3quoter
    ) {
        require(_routers.length == _routerTypes.length, 'INVALID_ROUTERS_DATA');
        routers = _routers;
        for (uint256 i; i < _routers.length; ++i) {
            uint8 _type = _routerTypes[i];
            require(_type > 0 && _type <= 3, 'UNSUPPORTED_ROUTER_TYPE');
            routerTypes[_routers[i]] = _type;
        }
        require(routerTypes[_defaultRouter] > 0, 'INVALID DEFAULT_ROUTER');
        defaultRouter = _defaultRouter;
        uniswapV3quoter = _uniswapV3quoter;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) external override returns (uint256) {
        require(_amount > 0, 'ZERO_AMOUNT');
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amount);
        (address router, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);
        // TODO: check for native here if needed
        TransferHelper.safeApprove(_tokenIn, router, _amount);

        uint256 balanceBefore = IERC20(_tokenOut).balanceOf(_recipient);
        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            _balancerSwap(router, _tokenIn, _tokenOut, _amount, _recipient);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            _v2swap(router, getAddressRoute(router, routerType, _tokenIn, _tokenOut), _amount, _recipient);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            _v3swap(router, getBytesRoute(router, routerType, _tokenIn, _tokenOut), _amount, _recipient);
        } else {
            revert('UNSUPPORTED_ROUTER_TYPE');
        }
        return IERC20(_tokenOut).balanceOf(_recipient) - balanceBefore;
    }

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) public override returns (uint256) {
        if (_tokenIn == _tokenOut) return _amount;

        (address router, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);

        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            // todo: future work
            return _amount;
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(_amount, getAddressRoute(router, routerType, _tokenIn, _tokenOut));
            return amounts[amounts.length - 1]; // last item
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            return IQuoter(uniswapV3quoter).quoteExactInput(getBytesRoute(router, routerType, _tokenIn, _tokenOut), _amount);
        } else {
            return 0;
        }
    }

    function getAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) public override returns (uint256) {
        if (_tokenIn == _tokenOut) return _amountOut;

        (address router, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);

        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            // todo: future work
            return _amountOut;
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(_amountOut, getAddressRoute(router, routerType, _tokenIn, _tokenOut));
            return amounts[0]; // first item
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            return IQuoter(uniswapV3quoter).quoteExactOutput(getBytesRoute(router, routerType, _tokenIn, _tokenOut), _amountOut);
        } else {
            return 0;
        }
    }

    function getAddressRoute(
        address router,
        uint8 routerType,
        address tokenIn,
        address tokenOut
    ) internal view returns (address[] memory route) {
        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            route = _getBalancerRoute(router, tokenIn, tokenOut);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            route = _getV2Route(router, tokenIn, tokenOut);
        } else {
            address[] memory _route;
            route = _route;
        }
    }

    function getBytesRoute(
        address router,
        uint8 routerType,
        address tokenIn,
        address tokenOut
    ) internal view returns (bytes memory route) {
        if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            route = _getV3Route(router, tokenIn, tokenOut);
        } else {
            route = bytes('');
        }
    }

    function getBestRouter(address tokenIn, address tokenOut) internal view returns (address router, uint8 routerType) {
        router = defaultRouter;
        routerType = routerTypes[router];
    }

    function _getBalancerRoute(
        address router,
        address tokenIn,
        address tokenOut
    ) internal pure returns (address[] memory) {
        // todo: future work
        address[] memory route;
        route[0] = tokenIn;
        route[1] = tokenOut;
        return route;
    }

    function _getV2Route(
        address router,
        address tokenIn,
        address tokenOut
    ) internal view returns (address[] memory) {
        address factory = IUniswapV2Router02(router).factory();
        if (IUniswapV2Factory(factory).getPair(tokenIn, tokenOut) != address(0)) {
            address[] memory route = new address[](2);
            route[0] = tokenIn;
            route[1] = tokenOut;
            return route;
        } else {
            address[] memory tokens = routeTokens; // gas saving
            address middleToken;
            for (uint256 i; i < tokens.length; ++i) {
                if (
                    IUniswapV2Factory(factory).getPair(tokenIn, tokens[i]) != address(0) &&
                    IUniswapV2Factory(factory).getPair(tokens[i], tokenOut) != address(0)
                ) {
                    middleToken = tokens[i];
                    break;
                }
            }
            require(middleToken != address(0), 'CANT_FIND_ROUTE');
            address[] memory route = new address[](3);
            route[0] = tokenIn;
            route[1] = middleToken;
            route[2] = tokenOut;
            return route;
        }
    }

    function _getV3Route(
        address router,
        address tokenIn,
        address tokenOut
    ) internal view returns (bytes memory route) {
        address factory = IPeripheryImmutableState(router).factory();
        (route, ) = _checkEveryFeeForV3Pool(factory, tokenIn, tokenOut);

        if (route.length == 0) {
            // finding multi-hop route:
            address[] memory tokens = routeTokens; // gas saving

            for (uint256 i; i < tokens.length; ++i) {
                (bytes memory firstHop, uint24 firstFeeTier) = _checkEveryFeeForV3Pool(factory, tokenIn, tokens[i]);
                if (firstHop.length > 0) {
                    (bytes memory secondHop, uint24 secondFeeTier) = _checkEveryFeeForV3Pool(factory, tokens[i], tokenOut);
                    if (secondHop.length > 0) {
                        route = abi.encodePacked(tokenIn, firstFeeTier, tokens[i], secondFeeTier, tokenOut);
                        break;
                    }
                }
            }
        }
    }

    function _checkEveryFeeForV3Pool(
        address factory,
        address tokenIn,
        address tokenOut
    ) internal view returns (bytes memory route, uint24 fee) {
        IUniswapV3Factory Factory = IUniswapV3Factory(factory);

        if (Factory.getPool(tokenIn, tokenOut, FEE_500) != address(0)) {
            route = abi.encodePacked(tokenIn, FEE_500, tokenOut);
            fee = FEE_500;
        } else if (Factory.getPool(tokenIn, tokenOut, FEE_3000) != address(0)) {
            route = abi.encodePacked(tokenIn, FEE_3000, tokenOut);
            fee = FEE_3000;
        } else if (Factory.getPool(tokenIn, tokenOut, FEE_3000) != address(0)) {
            route = abi.encodePacked(tokenIn, FEE_10000, tokenOut);
            fee = FEE_10000;
        } else {
            route = bytes('');
        }
    }

    function _v2swap(
        address _router,
        address[] memory route,
        uint256 _amount,
        address _recipient
    ) internal returns (uint256) {
        uint256[] memory amounts = IUniswapV2Router02(_router).swapExactTokensForTokens(
            _amount,
            1, // todo: think about general control of max slippage if need
            route,
            _recipient,
            block.timestamp
        );
        return amounts[amounts.length - 1];
    }

    function _v3swap(
        address _router,
        bytes memory path,
        uint256 amountIn,
        address recipient
    ) internal {
        uint256 deadline = block.timestamp;
        uint256 amountOutMinimum = 1;
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(path, recipient, deadline, amountIn, amountOutMinimum);
        ISwapRouter(_router).exactInput{value: msg.value}(params);
    }

    function _balancerSwap(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) internal {
        // future work
    }
}
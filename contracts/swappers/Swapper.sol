//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/ISwapper.sol';
import '../libraries/KedrConstants.sol';
import '../libraries/KedrLib.sol';

contract Swapper is ISwapper, Ownable {
    mapping(address => uint8) public routerTypes; // router to ROUTER_TYPE
    mapping(address => mapping(address => mapping(address => address[]))) internal conversionPaths; // router => from => to => path
    mapping(address => mapping(address => mapping(address => bytes))) internal bytesConvestionPaths;
    address[] internal routers; // list of supported routers
    address[] internal routeTokens; // list of tokens to build composite routes if there is no direct pair
    address public defaultRouter; // default router to be used when don't want to spend gas to find best router
    address public uniswapV3quoter; // can be empty if no V3 routers are used
    uint24[] internal feeTiers;

    constructor(
        address[] memory _routers,
        uint8[] memory _routerTypes,
        address _defaultRouter
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

        // Assign default fee tiers v3
        feeTiers.push(500);
        feeTiers.push(3000);
        feeTiers.push(10000);
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) external payable override returns (uint256) {
        (address router, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);
        bool isNativeIn = KedrLib.isNative(_tokenIn);
        bool isNativeOut = KedrLib.isNative(_tokenOut);
        if (isNativeIn) {
            _amount = msg.value;
        }

        require(_amount > 0, 'ZERO_AMOUNT');

        uint256 balanceBefore;
        if (!isNativeIn) {
            TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amount);
            TransferHelper.safeApprove(_tokenIn, router, _amount);
        }

        balanceBefore = isNativeOut ? address(_recipient).balance : IERC20(_tokenOut).balanceOf(_recipient);

        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            _balancerSwap(router, _tokenIn, _tokenOut, _amount, _recipient);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            _v2swap(router, getAddressRoute(router, routerType, _tokenIn, _tokenOut), _amount, _recipient, isNativeIn, isNativeOut);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            _v3swap(router, getBytesRoute(router, routerType, _tokenIn, _tokenOut), _amount, _recipient);
        } else {
            revert('UNSUPPORTED_ROUTER_TYPE');
        }
        return isNativeOut ? address(_recipient).balance - balanceBefore : IERC20(_tokenOut).balanceOf(_recipient) - balanceBefore;
    }

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) public view override returns (uint256 amountOut) {
        if (_tokenIn == _tokenOut) return _amount;

        (address router, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);

        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            // todo: future work
            return _amount;
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(
                _amount,
                getAddressRoute(router, routerType, _tokenIn, _tokenOut)
            );
            amountOut = amounts[amounts.length - 1]; // last item
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            (, , address pool) = _findPathByTiers(IPeripheryImmutableState(router).factory(), _tokenIn, _tokenOut);
            if (pool != address(0)) {
                (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
                amountOut = _getQuoteV3(sqrtRatioX96, uint128(_amount), _tokenIn, _tokenOut);
            }
        } else {
            return 0;
        }
    }

    function getAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) public override view returns (uint256 amountOut) {
        if (_tokenIn == _tokenOut) return _amountOut;
        (address router, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);

        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            // todo: future work
            amountOut = _amountOut;
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(
                _amountOut,
                getAddressRoute(router, routerType, _tokenIn, _tokenOut)
            );
            amountOut = amounts[0]; // first item
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            (, , address pool) = _findPathByTiers(IPeripheryImmutableState(router).factory(), _tokenOut, _tokenIn);
            if (pool != address(0)) {
                (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
                amountOut = _getQuoteV3(sqrtRatioX96, uint128(_amountOut), _tokenOut, _tokenIn);
            }
        } else {
            amountOut = 0;
        }
    }

    function getAddressRoute(
        address router,
        uint8 routerType,
        address tokenIn,
        address tokenOut
    ) internal view returns (address[] memory route) {
        route = conversionPaths[router][tokenIn][tokenOut];
        if (route.length != 0) {
            return route;
        }

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
        route = bytesConvestionPaths[router][tokenIn][tokenOut];
        if (route.length != 0) {
            return route;
        }

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
        address WETH = IUniswapV2Router02(router).WETH();

        if (KedrLib.isNative(tokenIn)) tokenIn = WETH;
        if (KedrLib.isNative(tokenOut)) tokenOut = WETH;

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

    function _getQuoteV3(
        uint160 sqrtRatioX96,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken ? (ratioX192 * baseAmount) / (1 << 192) : ((1 << 192) * baseAmount) / ratioX192;
        } else {
            uint256 ratioX128 = (sqrtRatioX96 * sqrtRatioX96) / (1 << 64);
            quoteAmount = baseToken < quoteToken ? (ratioX128 * baseAmount) / (1 << 128) : ((1 << 128) * baseAmount) / ratioX128;
        }
    }

    function _getV3Route(
        address router,
        address tokenIn,
        address tokenOut
    ) internal view returns (bytes memory route) {
        address factory = IPeripheryImmutableState(router).factory();
        address WETH = IPeripheryImmutableState(router).WETH9();

        if (KedrLib.isNative(tokenIn)) tokenIn = WETH;
        if (KedrLib.isNative(tokenOut)) tokenOut = WETH;

        (route, , ) = _findPathByTiers(factory, tokenIn, tokenOut);

        if (route.length == 0) {
            // finding multi-hop route:
            address[] memory tokens = routeTokens; // gas saving

            for (uint256 i; i < tokens.length; ++i) {
                (bytes memory firstHop, uint24 firstFeeTier, ) = _findPathByTiers(factory, tokenIn, tokens[i]);
                if (firstHop.length > 0) {
                    (bytes memory secondHop, uint24 secondFeeTier, ) = _findPathByTiers(factory, tokens[i], tokenOut);
                    if (secondHop.length > 0) {
                        route = abi.encodePacked(tokenIn, firstFeeTier, tokens[i], secondFeeTier, tokenOut);
                        break;
                    }
                }
            }
        }
    }

    function _findPathByTiers(
        address factory,
        address tokenIn,
        address tokenOut
    )
        internal
        view
        returns (
            bytes memory route,
            uint24 fee,
            address pool
        )
    {
        uint24[] memory _feeTiers = feeTiers;
        uint256 _length = _feeTiers.length;
        for (uint24 i; i < _length; ++i) {
            (bool poolFound, address _pool) = _isV3PoolExists(factory, tokenIn, tokenOut, _feeTiers[i]);
            if (poolFound) {
                route = abi.encodePacked(tokenIn, _feeTiers[i], tokenOut);
                fee = _feeTiers[i];
                pool = _pool;
                break;
            }
        }
    }

    function _isV3PoolExists(
        address factory,
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) internal view returns (bool, address) {
        address pool = IUniswapV3Factory(factory).getPool(tokenIn, tokenOut, fee);
        return (pool != address(0), pool);
    }

    function _v2swap(
        address _router,
        address[] memory route,
        uint256 _amount,
        address _recipient,
        bool isNativeIn,
        bool isNativeOut
    ) internal returns (uint256) {
        uint256[] memory amounts;
        uint256 deadline = block.timestamp;
        if (isNativeIn) {
            amounts = IUniswapV2Router02(_router).swapExactETHForTokens{value: msg.value}(1, route, _recipient, deadline);
        } else if (isNativeOut) {
            amounts = IUniswapV2Router02(_router).swapExactTokensForETH(
                _amount,
                1, // todo: think about general control of max slippage if need
                route,
                _recipient,
                deadline
            );
        } else {
            amounts = IUniswapV2Router02(_router).swapExactTokensForTokens(
                _amount,
                1, // todo: think about general control of max slippage if need
                route,
                _recipient,
                deadline
            );
        }
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

    function setConversionPath(
        address _router,
        address _from,
        address _to,
        address[] memory _path
    ) public onlyOwner {
        require(_from == _path[0], 'The first token of path must be _from');
        require(_to == _path[_path.length - 1], 'The last token of path must be _to');
        conversionPaths[_router][_from][_to] = _path;
    }

    function setBytesConversionPath(
        address _router,
        address _from,
        address _to,
        bytes memory _path
    ) public onlyOwner {
        bytesConvestionPaths[_router][_from][_to] = _path;
    }
}

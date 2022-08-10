//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/ISwapper.sol';
import '../libraries/KedrConstants.sol';

contract Swapper is ISwapper {
    mapping(address => uint8) public routerTypes; // router to ROUTER_TYPE
    address[] internal routers; // list of supported routers
    address[] internal quoteTokens; // list of tokens to build composite routes if there is no direct pair
    address public defaultRouter; // default router to be used when don't want to spend gas to find best router

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
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) external override returns (uint256) {
        require(_amount > 0, 'ZERO_AMOUNT');
        (address router, address[] memory route, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);
        require(route.length > 1, 'NO_ROUTE');
        uint256 balanceBefore = IERC20(_tokenOut).balanceOf(_recipient);
        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            _balancerSwap(router, _tokenIn, _tokenOut, _amount, _recipient);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            _uniswapV2(router, _tokenIn, _tokenOut, _amount, _recipient);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            _uniswapV3(router, _tokenIn, _tokenOut, _amount, _recipient);
        } else {
            revert('UNSUPPORTED_ROUTER_TYPE');
        }
        return IERC20(_tokenOut).balanceOf(_recipient) - balanceBefore;
    }


    function getReturn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) public view override returns (uint256) {
        (address router, address[] memory route, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);

        if (route.length > 1) {
            if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
                return _balancerAmountOut(router, _tokenIn, _tokenOut, _amount);
            } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
                return _uniswapV2AmountOut(router, _tokenIn, _tokenOut, _amount);
            } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
                return _uniswapV3AmountOut(router, _tokenIn, _tokenOut, _amount);
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    function getRoute(
        address router,
        uint8 routerType,
        address tokenIn,
        address tokenOut
    ) internal view returns (address[] memory route) {
        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            route = _getBalancerRoute(router, tokenIn, tokenOut);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            route = _getV2Route(router, tokenIn, tokenOut);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            route = _getV3Route(router, tokenIn, tokenOut);
        } else {
            address[] memory _route;
            route = _route;
        }
    }

    function getBestRouter(address tokenIn, address tokenOut)
        internal
        view
        returns (
            address router,
            address[] memory route,
            uint8 routerType
        )
    {
        router = defaultRouter;
        routerType = routerTypes[router];
        route = getRoute(router, routerType, tokenIn, tokenOut);
    }

    function _getBalancerRoute(
        address router,
        address tokenIn,
        address tokenOut
    ) internal pure returns (address[] memory) {
        // TODO: complete
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
        // TODO: complete
        address[] memory route;
        route[0] = tokenIn;
        route[1] = tokenOut;
        return route;
    }

    function _getV3Route(
        address router,
        address tokenIn,
        address tokenOut
    ) internal view returns (address[] memory) {
        // TODO: complete
        address[] memory route;
        route[0] = tokenIn;
        route[1] = tokenOut;
        return route;
    }

    function _uniswapV2(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) internal {
        // path = new address[](2);
        // path[0] = _tokenIn;
        // path[1] = _tokenOut;
        // uint256[] minimumAmountOut = router.getAmountsOut(_amount, path);
        // uint256[] amounts = router.swapExactTokensForTokens(
        //     _amount,
        //     minimumAmountOut[1],
        //     path,
        //     _recipient,
        //     _timestamp
        // );
        // return amounts[1];
    }

    function _uniswapV3(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) internal {
        // TODO:
    }

    function _balancerSwap(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) internal {
        // TODO: complete balancer swaps in future releases
    }

    function _balancerAmountOut(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) internal view returns (uint256) {
        // TODO: complete
        return _amount;
    }

    function _uniswapV2AmountOut(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) internal view returns (uint256) {
        // TODO: complete
        return _amount;
    }

    function _uniswapV3AmountOut(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) internal view returns (uint256) {
        // TODO: complete
        return _amount;
    }
}

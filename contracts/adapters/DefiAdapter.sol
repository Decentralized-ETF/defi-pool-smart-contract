//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

import {IUniSwapV3Exchange} from "../interfaces/IUniSwapV3Exchange.sol";
import {IUniSwapV2Exchange} from "../interfaces/IUniSwapV2Exchange.sol";
import {IPancakeSwapExchange} from "../interfaces/IPancakeSwapExchange.sol";

contract DefiAdapter {
    IUniSwapV3Exchange uniSwapV3Exchange;
    IUniSwapV2Exchange uniSwapV2Exchange;
    IPancakeSwapExchange pancakeSwapExchange;

    constructor(address _uniSwapV3ExchangeAddress, address _uniSwapV2ExchangeAddress, address _pancakeSwapExchangeAddress) {
        uniSwapV3Exchange = IUniSwapV3Exchange(_uniSwapV3ExchangeAddress);
        uniSwapV2Exchange = IUniSwapV2Exchange(_uniSwapV2ExchangeAddress);
        pancakeSwapExchange = IPancakeSwapExchange(_pancakeSwapExchangeAddress);
    }

    function getExchangeAddress(string memory _name) external view returns (address exchangeAddress, address exchangeRouterAddress) {
        if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked("uniswap3"))) {
            exchangeAddress = address(uniSwapV3Exchange);
            exchangeRouterAddress = uniSwapV3Exchange.getRouterContractAddress();
        } else if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked("uniswap2"))) {
            exchangeAddress = address(uniSwapV2Exchange);
            exchangeRouterAddress = uniSwapV2Exchange.getRouterContractAddress();
        }
        exchangeAddress = address(pancakeSwapExchange);
        exchangeRouterAddress = pancakeSwapExchange.getRouterContractAddress();
    }

    function swap(address _exchangeAddress,
        address _tokenIn,
        address _tokenOut,
        uint256 _timestamp,
        uint256 _amount,
        address _recipient) external returns (uint256){
        if (_exchangeAddress == address(uniSwapV3Exchange)) {
            return uniSwapV3Exchange.swap(_tokenIn,
                _tokenOut,
                _timestamp,
                _amount,
                _recipient);

        } else if (_exchangeAddress == address(uniSwapV2Exchange)) {
            return uniSwapV2Exchange.swap(_tokenIn,
                _tokenOut,
                _timestamp,
                _amount,
                _recipient);
        }
        return pancakeSwapExchange.swap(_tokenIn,
            _tokenOut,
            _timestamp,
            _amount,
            _recipient);
    }
}
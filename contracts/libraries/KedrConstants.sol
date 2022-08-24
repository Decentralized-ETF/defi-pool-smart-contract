//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library KedrConstants {
    uint16 internal constant _FEE_DENOMINATOR = 10000;
    uint16 internal constant _DEFAULT_FEE_NUMERATOR = 10000; // 0% fee by default
    uint16 internal constant _MAX_ENTRY_FEE = 1000; // 10%
    uint16 internal constant _MAX_SUCCESS_FEE = 500; // 5%

    uint8 internal constant _ROUTER_TYPE_BALANCER = 1; 
    uint8 internal constant _ROUTER_TYPE_V2 = 2;
    uint8 internal constant _ROUTER_TYPE_V3 = 3;

    uint8 internal constant _INACCURACY = 5; // max permissible innacuracy in the calculation of swaps
}

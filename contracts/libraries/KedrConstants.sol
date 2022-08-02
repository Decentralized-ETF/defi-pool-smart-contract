// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

library KedrConstants {
    uint16 internal constant _FEE_DENOMINATOR = 1000;
    uint16 internal constant _DEFAULT_FEE_NUMERATOR = 1000;
    uint16 internal constant _MIN_ENTRY_FEE = 900; // max entry fee is 10%
    uint16 internal constant _MIN_SUCCESS_FEE = 950; // max success fee is 5%

    uint8 internal constant _ROUTER_TYPE_BALANCER = 1; // max success fee is 5%
    uint8 internal constant _ROUTER_TYPE_V2 = 2; // max success fee is 5%
    uint8 internal constant _ROUTER_TYPE_V3 = 3; // max success fee is 5%
}

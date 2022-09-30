//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

library KedrLib {
    /**
     * @dev deploys new contract using create2 with check of deployment
     */
    function deploy(bytes memory bytecode) external returns (address _contract) {
        assembly {
            _contract := create2(0, add(bytecode, 32), mload(bytecode), '')
            if iszero(extcodesize(_contract)) {
                revert(0, 0)
            }
        }
        return _contract;
    }

    function isNative(address token) internal pure returns (bool) {
        return token == address(0);
    }

    function uniTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (isNative(token)) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransferFrom(token, from, to, amount);
        }
    }

    function uniTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (isNative(token)) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
    }
}

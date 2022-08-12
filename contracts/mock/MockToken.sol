// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockToken is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol) {
        _decimals = _decimal;
    }

    function mint(address _receiver, uint256 _amount) external {
        _mint(_receiver, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }
}
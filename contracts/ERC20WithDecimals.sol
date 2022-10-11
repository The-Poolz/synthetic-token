// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract ERC20WithDecimals is ERC20Capped, ERC20Burnable {
    uint8 immutable private _decimals;

    constructor (uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _mint(address _account, uint _amount) internal virtual override(ERC20Capped, ERC20) {
        super._mint(_account, _amount);
    }
}
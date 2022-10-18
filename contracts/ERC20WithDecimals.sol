// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./Manageable.sol";

abstract contract ERC20WithDecimals is ERC20Capped, ERC20Burnable, Manageable {
    uint8 private immutable _decimals;

    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _mint(address _account, uint256 _amount)
        internal
        virtual
        override(ERC20Capped, ERC20)
    {
        super._mint(_account, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(
            EndTime <= block.timestamp ||
                _msgSender() == owner() ||
                to == address(0) ||
                registerWhitelist(to, amount),
            "Invalid Transfer Time or To Address"
        );
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";

contract POOLZSYNT is ERC20, ERC20Capped, ERC20Burnable {
    // uint256 _cap = 2000000 * 10**18;\

    event Becon(bytes Address, uint256 Amount);

    constructor(string memory _name, string memory _symbol, uint _cap, address _owner)
        public
        ERC20(_name, _symbol)
        ERC20Capped(_cap * 10**18)
    {
        _setupDecimals(18);
        _mint(_owner, _cap * 10**18);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override(ERC20Capped, ERC20)
    {
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
    }

    function ActivateBeacon(bytes calldata _Address) external {
        burn(balanceOf(_msgSender()));
        emit Becon(_Address, balanceOf(_msgSender()));
    }

    function ActivateBeacon(bytes calldata _Address, uint256 _Amount) external {
        burn(_Amount);
        emit Becon(_Address, _Amount);
    }
}

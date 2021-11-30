// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
* @title TestToken is a basic ERC20 Token
*/
contract Token is ERC20, Ownable{

    /**
    * @dev assign totalSupply to account creating this contract
    */
    
    constructor(string memory _TokenName, string memory _TokenSymbol) ERC20(_TokenName, _TokenSymbol) public {
        _setupDecimals(18);
        _mint(msg.sender, 10000 * 10**18);

    }
    
    function FreeTest () public {
        _mint(msg.sender, 10000 * 10**18);
    }
}

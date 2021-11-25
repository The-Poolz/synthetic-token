// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Manageable.sol";
import "poolz-helper/contracts/ERC20Helper.sol";
import "poolz-helper/contracts/ILockedDeal.sol";

contract POOLZSYNT is ERC20, ERC20Capped, ERC20Burnable, Manageable {
    // uint256 _cap = 2000000 * 10**18;\

    event Becon(bytes Address, uint256 Amount);

    constructor(string memory _name, string memory _symbol, uint _cap, uint8 _decimals, address _owner)
        public
        ERC20(_name, _symbol)
        ERC20Capped(_cap * 10**uint(_decimals))
    {
        require(_decimals <= 18, "Decimal more than 18");
        _setupDecimals(_decimals);
        _mint(_owner, _cap * 10**uint(_decimals));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override(ERC20Capped, ERC20)
    {
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
    }

    function ActivateSynthetic() external {
        require(totalUnlocks != 0, "Original Token not Ready");
        for(uint8 i=0 ; i<totalUnlocks ; i++){
            uint amount = SafeMath.div(
                SafeMath.mul( balanceOf(_msgSender()), LockDetails[i].ratio ),
                totalOfRatios
            );
            burn(amount);
            if(LockDetails[i].unlockTime <= now){
                TransferToken(OriginalTokenAddress, _msgSender(), amount );
            } else {
                ILockedDeal(LockedDealAddress).CreateNewPool(OriginalTokenAddress, LockDetails[i].unlockTime, amount, _msgSender());
            }
        }
    }
}

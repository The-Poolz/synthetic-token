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

    function SetLockingDetails(
        address _tokenAddress,
        uint64[] calldata _unlockTimes,
        uint8[] calldata _ratios
    ) external onlyOwnerOrGov  {
        _SetLockingDetails(_tokenAddress, cap(), _unlockTimes, _ratios);
    }

    function ActivateSynthetic() external {
        ActivateSynthetic(balanceOf(_msgSender()));
    }

    function ActivateSynthetic(uint _amountToActivate) public {
        require(totalUnlocks != 0, "Original Token not Ready");
        require(_amountToActivate <= balanceOf(_msgSender()), "Amount greater than balance");
        uint amountToBurn;
        (uint CreditableAmount, uint64[] memory unlockTimes, uint256[] memory unlockAmounts) = getActivationResult(_amountToActivate);
        TransferToken(OriginalTokenAddress, _msgSender(), CreditableAmount);
        amountToBurn = amountToBurn + CreditableAmount;
        for(uint8 i=0 ; i<unlockTimes.length ; i++){
            ILockedDeal(LockedDealAddress).CreateNewPool(OriginalTokenAddress, unlockTimes[i], unlockAmounts[i], _msgSender());
            amountToBurn = amountToBurn + unlockAmounts[i];
        }
        burn(amountToBurn);
        assert(amountToBurn == _amountToActivate);
    }

    function getActivationResult(uint _amountToActivate) public view returns(
        uint CreditableAmount, 
        uint64[] memory unlockTimes, 
        uint256[] memory unlockAmounts
    ) {
        for(uint8 i=0 ; i<totalUnlocks ; i++){
            uint amount = SafeMath.div(
                SafeMath.mul( _amountToActivate, LockDetails[i].ratio ),
                totalOfRatios
            );
            if(LockDetails[i].unlockTime <= now){
                CreditableAmount = CreditableAmount + amount;
            } else {
                unlockTimes[i] = LockDetails[i].unlockTime;
                unlockAmounts[i] = amount;
            }
        }
    }
}

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
    event TokenActivated(address Owner, uint256 Amount);

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

    function ActivateSynthetic(uint _amountToActivate) public tokenIsReady {
        (uint amountToBurn, uint CreditableAmount, uint64[] memory unlockTimes, uint256[] memory unlockAmounts) = getActivationResult(_amountToActivate);
        TransferToken(OriginalTokenAddress, _msgSender(), CreditableAmount);
        if(SafeMath.sub(amountToBurn, CreditableAmount) > 0){
            ApproveAllowanceERC20(OriginalTokenAddress, LockedDealAddress, SafeMath.sub(amountToBurn, CreditableAmount));
            for(uint8 i=0 ; i<unlockTimes.length ; i++){
                if(unlockAmounts[i] > 0){
                    ILockedDeal(LockedDealAddress).CreateNewPool(OriginalTokenAddress, unlockTimes[i], unlockAmounts[i], _msgSender());         
                }
            }
        }
        burn(amountToBurn);   // here will be check for balance
        emit TokenActivated(_msgSender(), amountToBurn);
        assert(amountToBurn == _amountToActivate);
    }

    function getActivationResult(uint _amountToActivate) public view tokenIsReady returns(uint, uint, uint64[] memory, uint256[] memory)  {
        uint TotalTokens;
        uint CreditableAmount; 
        uint64[] memory unlockTimes = new uint64[](totalUnlocks);
        uint256[] memory unlockAmounts = new uint256[](totalUnlocks);
        uint8 iterator;

        for(uint8 i=0 ; i<totalUnlocks ; i++){
            uint amount = SafeMath.div(
                SafeMath.mul( _amountToActivate, LockDetails[i].ratio ),
                totalOfRatios
            );
            TotalTokens = SafeMath.add(TotalTokens, amount);
            if(LockDetails[i].unlockTime <= now){
                CreditableAmount = SafeMath.add(CreditableAmount, amount);
            } else {
                unlockTimes[iterator] = LockDetails[i].unlockTime;
                unlockAmounts[iterator] = amount;
                iterator++;
            }
        }
        if(TotalTokens < _amountToActivate){
            uint difference = SafeMath.sub(_amountToActivate, TotalTokens);
            if(unlockAmounts[0] == 0){
                CreditableAmount = SafeMath.add(CreditableAmount, difference);
            } else {
                for(uint8 i=totalUnlocks - 1; i >= 0 ; i--){
                    if(unlockAmounts[i] > 0){
                        unlockAmounts[i] = SafeMath.add(unlockAmounts[i], difference);
                        break;
                    }
                }
            }
            TotalTokens = _amountToActivate;
        }
        return(TotalTokens, CreditableAmount, unlockTimes, unlockAmounts);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20WithDecimals.sol";
import "./Manageable.sol";
import "poolz-helper-v2/contracts/interfaces/ILockedDeal.sol";

contract POOLZSYNT is ERC20WithDecimals, Manageable {
    event TokenActivated(address Owner, uint256 Amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint _cap,
        uint8 _decimals,
        address _owner,
        address _lockedDealAddress,
        address _whitelistAddress
    )
        ERC20(_name, _symbol)
        ERC20WithDecimals(_decimals)
        ERC20Capped(_cap * 10**uint(_decimals))
    {
        require(_decimals <= 18, "Decimal more than 18");
        _mint(_owner, cap());
        _SetLockedDealAddress(_lockedDealAddress);
        if(_whitelistAddress != address(0)){
            uint256 whitelistId = IWhiteList(_whitelistAddress).CreateManualWhiteList(type(uint).max, address(this));
            IWhiteList(_whitelistAddress).ChangeCreator(whitelistId, _msgSender());
            _SetupWhitelist(_whitelistAddress, whitelistId);
        } else {
            _SetupWhitelist(_whitelistAddress, 0);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override
    {
        require(FinishTime <= block.timestamp 
            || _msgSender() == owner() 
            || to == address(0)
            || registerWhitelist(to, amount),
            "Invalid Transfer Time or To Address");
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
    }

    function SetLockingDetails(
        address _tokenAddress,
        uint64[] calldata _unlockTimes,
        uint8[] calldata _ratios,
        uint256 _finishTime
    ) external onlyOwnerOrGov  {
        _SetLockingDetails(_tokenAddress, cap(), _unlockTimes, _ratios, _finishTime);
    }

    function ActivateSynthetic() external {
        ActivateSynthetic(balanceOf(_msgSender()));
    }

    function ActivateSynthetic(uint _amountToActivate) public tokenReady(true) {
        (uint amountToBurn, uint CreditableAmount, uint64[] memory unlockTimes, uint256[] memory unlockAmounts) = getActivationResult(_amountToActivate);
        TransferToken(OriginalTokenAddress, _msgSender(), CreditableAmount);
        if(amountToBurn - CreditableAmount > 0){
            require(LockedDealAddress != address(0), "Error: LockedDeal Contract Address Missing");
            ApproveAllowanceERC20(OriginalTokenAddress, LockedDealAddress, amountToBurn - CreditableAmount);
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

    function getActivationResult(uint _amountToActivate)
        public view tokenReady(true) returns(uint, uint, uint64[] memory, uint256[] memory)
    {
        uint TotalTokens;
        uint CreditableAmount; 
        uint64[] memory unlockTimes = new uint64[](totalUnlocks);
        uint256[] memory unlockAmounts = new uint256[](totalUnlocks);
        uint8 iterator;

        for(uint8 i=0 ; i<totalUnlocks ; i++){
            uint amount = (_amountToActivate * LockDetails[i].ratio) / totalOfRatios;
            TotalTokens += amount;
            if(LockDetails[i].unlockTime <= block.timestamp){
                CreditableAmount += amount;
            } else {
                unlockTimes[iterator] = LockDetails[i].unlockTime;
                unlockAmounts[iterator] = amount;
                iterator++;
            }
        }
        if(TotalTokens < _amountToActivate){
            uint difference = _amountToActivate - TotalTokens;
            if(unlockAmounts[0] == 0){
                CreditableAmount += difference;
            } else {
                for(uint8 i=totalUnlocks - 1; i >= 0 ; i--){
                    if(unlockAmounts[i] > 0){
                        unlockAmounts[i] += difference;
                        break;
                    }
                }
            }
            TotalTokens = _amountToActivate;
        }
        return(TotalTokens, CreditableAmount, unlockTimes, unlockAmounts);
    }
}
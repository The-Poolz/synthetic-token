// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20WithDecimals.sol";
import "poolz-helper-v2/contracts/interfaces/ILockedDealV2.sol";

contract POOLZSYNT is ERC20WithDecimals {
    event TokenActivated(address Owner, uint256 Amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cap,
        uint8 _decimals,
        address _owner,
        address _lockedDealAddress,
        address _whitelistAddress
    )
        ERC20(_name, _symbol)
        ERC20WithDecimals(_decimals)
        ERC20Capped(_cap * 10**uint256(_decimals))
    {
        require(_decimals <= 18, "Decimal more than 18");
        _mint(_owner, cap());
        _SetLockedDealAddress(_lockedDealAddress);
        if (_whitelistAddress != address(0)) {
            uint256 whitelistId = IWhiteList(_whitelistAddress)
                .CreateManualWhiteList(type(uint256).max, address(this));
            IWhiteList(_whitelistAddress).ChangeCreator(
                whitelistId,
                _msgSender()
            );
            _SetupWhitelist(_whitelistAddress, whitelistId);
        } else {
            _SetupWhitelist(_whitelistAddress, 0);
        }
    }

    function SetLockingDetails(
        address _tokenAddress,
        uint64 _startLockTime,
        uint64 _finishLockTime,
        uint256 _finishTime
    ) external onlyOwnerOrGov {
        _SetLockingDetails(
            _tokenAddress,
            cap(),
            _startLockTime,
            _finishLockTime,
            _finishTime
        );
    }

    function ActivateSynthetic() external {
        ActivateSynthetic(balanceOf(_msgSender()));
    }

    function ActivateSynthetic(uint256 _amountToActivate) public tokenReady(true) {
        (
            uint256 amountToBurn,
            uint256 CreditableAmount,
            uint256 startTime,
            uint256 finishTime
        ) = getActivationResult(_amountToActivate);
        TransferToken(OriginalTokenAddress, _msgSender(), CreditableAmount);
        if (amountToBurn - CreditableAmount > 0) {
            require(
                LockedDealAddress != address(0),
                "Error: LockedDeal Contract Address Missing"
            );
            ApproveAllowanceERC20(
                OriginalTokenAddress,
                LockedDealAddress,
                amountToBurn - CreditableAmount
            );
            ILockedDealV2(LockedDealAddress).CreateNewPool(
                OriginalTokenAddress,
                startTime,
                finishTime,
                amountToBurn - CreditableAmount,
                _msgSender()
            );
        }
        burn(amountToBurn); // here will be check for balance
        emit TokenActivated(_msgSender(), amountToBurn);
        assert(amountToBurn == _amountToActivate);
    }

    function getActivationResult(uint256 _amountToActivate)
        public
        view 
        tokenReady(true)
        returns (
            uint256 TotalTokens,
            uint256 CreditableAmount,
            uint256 StartTime,
            uint256 FinishTime
        )
    {
        StartTime = LockDetails.startTime;
        if (LockDetails.finishTime < block.timestamp) {
            CreditableAmount = _amountToActivate;
        } else if (LockDetails.startTime < block.timestamp) {
            uint256 totalPoolDuration = LockDetails.finishTime - LockDetails.startTime;
            uint256 timePassed = block.timestamp - LockDetails.startTime;
            uint256 timePassedPermille = timePassed * 1000;
            uint256 ratioPermille = timePassedPermille / totalPoolDuration;
            CreditableAmount = (_amountToActivate * ratioPermille) / 1000;
            StartTime = block.timestamp;
        }
        return (
            _amountToActivate,
            CreditableAmount,
            StartTime,
            LockDetails.finishTime
        );
    }
}

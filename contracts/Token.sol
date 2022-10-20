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
        uint64[] calldata _startLockTime,
        uint64[] calldata _finishLockTime,
        uint8[] calldata _ratios,
        uint256 _endTime
    ) external onlyOwnerOrGov {
        _SetLockingDetails(
            _tokenAddress,
            cap(),
            _startLockTime,
            _finishLockTime,
            _ratios,
            _endTime
        );
    }

    function ActivateSynthetic() external {
        ActivateSynthetic(balanceOf(_msgSender()));
    }

    function ActivateSynthetic(uint256 _amountToActivate) public {
        (
            uint256 CreditableAmount,
            uint256[] memory lockStartTime,
            uint256[] memory unlockAmounts
        ) = getActivationResult(_amountToActivate);
        address _originalTokenAddress = OriginalTokenAddress;
        address _lockDealAddress = LockedDealAddress;
        TransferToken(_originalTokenAddress, _msgSender(), CreditableAmount);
        uint256 amountToLock = _amountToActivate - CreditableAmount;
        if (amountToLock > 0) {
            require(
                _lockDealAddress != address(0),
                "Error: LockedDeal Contract Address Missing"
            );
            ApproveAllowanceERC20(
                _originalTokenAddress,
                _lockDealAddress,
                amountToLock
            );
            for (uint8 i = 0; i < Index; i++) {
                if (unlockAmounts[i] > 0) {
                    ILockedDealV2(_lockDealAddress).CreateNewPool(
                        _originalTokenAddress,
                        lockStartTime[i],
                        LockDetails[i].finishTime,
                        unlockAmounts[i],
                        _msgSender()
                    );
                }
            }
        }
        burn(_amountToActivate); // here will be check for balance
        emit TokenActivated(_msgSender(), _amountToActivate);
    }

    function getActivationResult(uint256 _amountToActivate)
        public
        view
        tokenReady(true)
        returns (
            uint256 CreditableAmount,
            uint256[] memory lockStartTime,
            uint256[] memory unlockAmounts
        )
    {
        unlockAmounts = new uint256[](Index);
        for (uint8 i = 0; i < Index; i++) {
            uint256 amount = (_amountToActivate * LockDetails[0].ratio) / Index;
            if (LockDetails[i].finishTime <= block.timestamp) {
                CreditableAmount += amount;
            } else if (LockDetails[i].startTime <= block.timestamp) {
                uint256 totalPoolDuration = LockDetails[i].finishTime -
                    LockDetails[i].startTime;
                uint256 timePassed = block.timestamp - LockDetails[i].startTime;
                uint256 timePassedPermille = timePassed * 1000;
                uint256 ratioPermille = timePassedPermille / totalPoolDuration;
                CreditableAmount += (amount * ratioPermille) / 1000;
                unlockAmounts[i] = amount - CreditableAmount;
                lockStartTime[i] = block.timestamp;
            } else if (block.timestamp < LockDetails[i].startTime) {
                unlockAmounts[i] = amount;
                lockStartTime[i] = LockDetails[i].startTime;
            }
        }
    }
}

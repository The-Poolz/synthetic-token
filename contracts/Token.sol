// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Override.sol";
import "poolz-helper-v2/contracts/interfaces/ILockedDealV2.sol";
import "poolz-helper-v2/contracts/Array.sol";

contract POOLZSYNT is Override {
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
        Override(_decimals)
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
        uint64 _endTime
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

    function WithdrawToken() external {
        ActivateSynthetic(balanceOf(_msgSender()));
    }

    function ActivateSynthetic(uint256 _amountToActivate) public {
        (
            uint256 CreditableAmount,
            uint256[] memory lockStartTime,
            uint256[] memory lockAmounts
        ) = getWithdrawableAmount(_amountToActivate);
        address _originalTokenAddress = OriginalTokenAddress;
        address _lockDealAddress = LockedDealAddress;
        TransferToken(_originalTokenAddress, _msgSender(), CreditableAmount);
        uint256 amountToLock = _amountToActivate - CreditableAmount;
        if (amountToLock > 0) {
            ApproveAllowanceERC20(
                _originalTokenAddress,
                _lockDealAddress,
                amountToLock
            );
            for (uint8 i = 0; i < TotalLocks; i++) {
                if (lockAmounts[i] > 0) {
                    ILockedDealV2(_lockDealAddress).CreateNewPool(
                        _originalTokenAddress,
                        lockStartTime[i],
                        LockDetails[i].finishTime,
                        lockAmounts[i],
                        _msgSender()
                    );
                }
            }
        }
        burn(_amountToActivate); // here will be check for balance
        emit TokenActivated(_msgSender(), _amountToActivate);
    }

    function getWithdrawableAmount(uint256 _amountToActivate)
        public
        view
        tokenReady(true)
        returns (
            uint256 CreditableAmount,
            uint256[] memory lockStartTimes,
            uint256[] memory lockAmounts
        )
    {
        lockStartTimes = new uint256[](TotalLocks);
        lockAmounts = new uint256[](TotalLocks);
        for (uint8 i = 0; i < TotalLocks; i++) {
            uint256 amount = (_amountToActivate * LockDetails[i].ratio) /
                SumOfRatios;
            if (LockDetails[i].finishTime <= block.timestamp) {
                CreditableAmount += amount;
            } else if (LockDetails[i].startTime <= block.timestamp) {
                uint256 totalPoolDuration = LockDetails[i].finishTime - LockDetails[i].startTime;
                uint256 timePassed = block.timestamp - LockDetails[i].startTime;
                uint256 timePassedPermille = timePassed * 1000;
                uint256 ratioPermille = timePassedPermille / totalPoolDuration;
                uint256 _creditableAmount = (amount * ratioPermille) / 1000;
                CreditableAmount += _creditableAmount;
                lockStartTimes[i] = block.timestamp;
                lockAmounts[i] = amount - _creditableAmount;
            } else if (block.timestamp < LockDetails[i].startTime) {
                lockStartTimes[i] = LockDetails[i].startTime;
                lockAmounts[i] = amount;
            }
        }
        uint256 lockedAmount = Array.getArraySum(lockAmounts);
        if (lockedAmount + CreditableAmount < _amountToActivate) {
            uint256 difference = _amountToActivate - (lockedAmount + CreditableAmount);
            if (lockedAmount == 0) {
                CreditableAmount += difference;
            } else {
                for (uint8 i = 0; i < TotalLocks; i++) {
                    if (lockAmounts[i] > 0) {
                        lockAmounts[i] += difference;
                        break;
                    }
                }
            }
        }
    }
}

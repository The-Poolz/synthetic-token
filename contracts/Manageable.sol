// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "poolz-helper-v2/contracts/interfaces/IWhiteList.sol";

contract Manageable is ERC20Helper, GovManager {
    event LockingDetails(
        address TokenAddress,
        uint256 Amount,
        uint256 FinishTime
    );

    address public OriginalTokenAddress;
    address public LockedDealAddress;

    address public WhitelistAddress;
    uint256 public WhitelistId;

    uint256 public FinishTime;

    bool public LockStatus;

    struct lockDetails {
        uint64 startTime;
        uint64 finishTime;
    }

    lockDetails public LockDetails;

    modifier tokenReady(bool status) {
        require(
            LockStatus == status, "Unlock Data status error"
        );
        _;
    }

    function _SetLockingDetails(
        address _tokenAddress,
        uint256 _amount,
        uint64 _startLockTime,
        uint64 _finishLockTime,
        uint256 _finishTime
    ) internal tokenReady(false) {
        require(_tokenAddress != address(0), "Token address can't be zero");
        OriginalTokenAddress = _tokenAddress;
        TransferInToken(_tokenAddress, msg.sender, _amount);
        LockDetails = lockDetails(_startLockTime, _finishLockTime);
        FinishTime = _finishTime;
        emit LockingDetails(_tokenAddress, _amount, _finishTime);
        LockStatus = true;
    }

    function _SetLockedDealAddress(address _lockedDeal)
        internal
        onlyOwnerOrGov
    {
        require(_lockedDeal != address(0), "LockedDeal address cannot be zero");
        LockedDealAddress = _lockedDeal;
    }

    function _SetupWhitelist(address _whitelistAddress, uint256 _whitelistId)
        internal
        onlyOwnerOrGov
    {
        WhitelistAddress = _whitelistAddress;
        WhitelistId = _whitelistId;
    }

    function registerWhitelist(address _address, uint256 _amount)
        internal
        returns (bool)
    {
        if (WhitelistId == 0) return true; //turn-off
        IWhiteList(WhitelistAddress).Register(_address, WhitelistId, _amount);
        return true;
    }
}

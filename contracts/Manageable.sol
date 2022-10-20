// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "poolz-helper-v2/contracts/interfaces/IWhiteList.sol";

contract Manageable is ERC20Helper, GovManager {
    event LockingDetails(
        address TokenAddress,
        uint256 Amount,
        uint256 FinishTime,
        uint64[] startLockTime,
        uint64[] finishLockTime,
        uint8[] Ratios
    );

    address public OriginalTokenAddress;
    address public LockedDealAddress;

    address public WhitelistAddress;
    uint256 public WhitelistId;

    uint256 public EndTime;

    bool public LockStatus;

    struct lockDetails {
        uint64 startTime;
        uint64 finishTime;
        uint ratio;
    }

    mapping(uint8 => lockDetails) public LockDetails;

    uint256 public Index;

    modifier tokenReady(bool status) {
        require(
            LockStatus == status, "Unlock Data status error"
        );
        _;
    }

    function _SetLockingDetails(
        address _tokenAddress,
        uint256 _amount,
        uint64[] memory _startLockTime,
        uint64[] memory _finishLockTime,
        uint8[] memory _ratios,
        uint256 _endTime
    ) internal tokenReady(false) {
        require(_tokenAddress != address(0), "Token address can't be zero");
        require(_startLockTime.length > 0, "Array length should be greater than 0");
        require(_startLockTime.length == _finishLockTime.length, "Arrays should have same length");
        require(_finishLockTime.length == _ratios.length, "Arrays should have same length");
        OriginalTokenAddress = _tokenAddress;
        TransferInToken(_tokenAddress, msg.sender, _amount);
        for(uint8 i = 0; i < _startLockTime.length; i++){
            LockDetails[i] = lockDetails(_startLockTime[i], _finishLockTime[i], _ratios[i]);
        }
        Index = _finishLockTime.length;
        EndTime = _endTime;
        emit LockingDetails(_tokenAddress, _amount, _endTime, _startLockTime, _finishLockTime, _ratios);
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

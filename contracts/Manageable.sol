// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "poolz-helper-v2/contracts/interfaces/IWhiteList.sol";

contract Manageable is ERC20Helper, GovManager {
    event LockingDetails(
        address TokenAddress,
        uint256 Amount,
        uint256 EndTime,
        uint64[] StartLockTime,
        uint64[] FinishLockTime,
        uint8[] Ratios
    );

    address public OriginalTokenAddress;
    address public LockedDealAddress;

    address public WhitelistAddress;
    uint256 public WhitelistId;

    uint64 public EndTime;

    struct lockDetails {
        uint64 startTime;
        uint64 finishTime;
        uint8 ratio;
    }

    mapping(uint8 => lockDetails) public LockDetails;

    uint8 public TotalLocks;
    uint64 public SumOfRatios;

    modifier tokenReady(bool status) {
        require(
            status ? TotalLocks > 0 : TotalLocks == 0, "Unlock Data status error"
        );
        _;
    }

    function _SetLockingDetails(
        address _tokenAddress,
        uint256 _amount,
        uint64[] calldata _startLockTime,
        uint64[] calldata _finishLockTime,
        uint8[] calldata _ratios,
        uint64 _endTime  //Need to be 0 - until duch sale
    ) internal tokenReady(false) {
        require(_tokenAddress != address(0), "Token address can't be zero");
        require(_startLockTime.length > 0, "Array length should be greater than 0");
        require(_startLockTime.length == _finishLockTime.length, "Arrays should have same length");
        require(_finishLockTime.length == _ratios.length, "Arrays should have same length");
        OriginalTokenAddress = _tokenAddress;
        TransferInToken(_tokenAddress, msg.sender, _amount);
        for(uint8 i = 0; i < _startLockTime.length; i++){
            LockDetails[i] = lockDetails(_startLockTime[i], _finishLockTime[i], _ratios[i]);
            SumOfRatios += _ratios[i];
        }
        TotalLocks = uint8(_finishLockTime.length);
        EndTime = _endTime;
        emit LockingDetails(_tokenAddress, _amount, _endTime, _startLockTime, _finishLockTime, _ratios);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "poolz-helper-v2/contracts/interfaces/IWhiteList.sol";

contract Manageable is ERC20Helper, GovManager{

    event LockingDetails(address TokenAddress, uint256 Amount, uint8 TotalUnlocks, uint256 FinishTime);

    address public OriginalTokenAddress;
    address public LockedDealAddress;

    address public WhitelistAddress;
    uint256 public WhitelistId;

    uint256 public FinishTime;

    struct lockDetails {
        uint64 startTime;
        uint64 finishTime;
        uint ratio;
    }

    mapping(uint8 => lockDetails) public LockDetails;

    uint8 public totalUnlocks;
    uint public totalOfRatios;

    modifier tokenReady(bool status) {
        require(status ? totalUnlocks != 0 : totalUnlocks == 0, "Unlock Data status error");
        _;
    }

    function _SetLockingDetails(
        address _tokenAddress,
        uint256 _amount,
        uint64[] memory _startTimes,
        uint64[] memory _finishTimes,
        uint8[] memory _ratios,
        uint256 _finishTime
    ) internal tokenReady(false) {
        require(
            _startTimes.length == _ratios.length &&
                _startTimes.length == _finishTimes.length,
            "Arrays should have same length."
        );
        require(_startTimes.length > 0, "Array length should be greater than 0");
        OriginalTokenAddress = _tokenAddress;
        TransferInToken(_tokenAddress, msg.sender, _amount);
        for(uint8 i=0; i<_startTimes.length ; i++){
            LockDetails[i] = lockDetails(_startTimes[i], _finishTimes[i], _ratios[i]);
            totalOfRatios += _ratios[i];
        }
        require(totalOfRatios > 0, "Total Of Ratios cannot be Zero");
        totalUnlocks = uint8(_startTimes.length);
        FinishTime = _finishTime;
        emit LockingDetails(_tokenAddress, _amount, totalUnlocks, _finishTime);
    }

    function _SetLockedDealAddress(address _lockedDeal) internal onlyOwnerOrGov {
        require(_lockedDeal != address(0), "LockedDeal address cannot be zero");
        LockedDealAddress = _lockedDeal;
    }

    function _SetupWhitelist(address _whitelistAddress, uint256 _whitelistId) internal onlyOwnerOrGov {
        WhitelistAddress = _whitelistAddress;
        WhitelistId = _whitelistId;
    }

    function registerWhitelist(address _address, uint256 _amount) internal returns(bool) {
        if (WhitelistId == 0) return true; //turn-off
        IWhiteList(WhitelistAddress).Register(_address, WhitelistId, _amount);
        return true;
    }
}
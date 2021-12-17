// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "poolz-helper/contracts/ERC20Helper.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "poolz-helper/contracts/GovManager.sol";

contract Manageable is ERC20Helper, GovManager{

    event LockingDetails(address TokenAddress, uint256 Amount, uint8 TotalUnlocks);

    address public OriginalTokenAddress;
    address public LockedDealAddress;

    struct lockDetails {
        uint64 unlockTime;
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
        uint64[] memory _unlockTimes,
        uint8[] memory _ratios
    ) internal tokenReady(false) {
        require(_unlockTimes.length == _ratios.length, "Both arrays should have same length.");
        require(_unlockTimes.length > 0, "Array length should be greater than 0");
        OriginalTokenAddress = _tokenAddress;
        TransferInToken(_tokenAddress, msg.sender, _amount);
        for(uint8 i=0; i<_unlockTimes.length ; i++){
            LockDetails[i] = lockDetails(_unlockTimes[i], _ratios[i]);
            totalOfRatios = SafeMath.add(totalOfRatios, _ratios[i]);
        }
        totalUnlocks = uint8(_unlockTimes.length);
        emit LockingDetails(_tokenAddress, _amount, totalUnlocks);
    }

    function SetLockedDealAddress(address lockedDeal) external onlyOwnerOrGov {
        LockedDealAddress = lockedDeal;
    }

}
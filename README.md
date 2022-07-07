# synthetic-token

[![Build Status](https://app.travis-ci.com/The-Poolz/synthetic-token.svg?branch=locked-synthetic)](https://app.travis-ci.com/The-Poolz/synthetic-token)
[![codecov](https://codecov.io/gh/The-Poolz/synthetic-token/branch/locked-synthetic/graph/badge.svg?token=hcog4N4JHJ)](https://codecov.io/gh/The-Poolz/synthetic-token)
[![CodeFactor](https://www.codefactor.io/repository/github/the-poolz/synthetic-token/badge)](https://www.codefactor.io/repository/github/the-poolz/synthetic-token)

A synthetic token is an **ERC20** smart contract that **proof of ownership** of the original token. The owner of synthetic tokens has the right to exchange his token for the original using the properties of the contract.

### Installation

```console
npm install
```

### Testing

```console
truffle run coverage
```

### Deploy

```console
truffle dashboard
```

```console
truffle migrate --network dashboard
```

## Functions
### Constructor
```solidity
constructor(
        string memory _name, // token name
        string memory _symbol, // token symbol
        uint _cap, // better set capitalization as original token
        uint8 _decimals, // token decimals
        address _owner, // who will take synthetic tokens
        address _lockedDealAddress, // can't be zero address
        address _whitelistAddress
    )
```
### SetLockingDetails
```solidity
// Can only use the owner address or Governer contract.
SetLockingDetails(
        address _tokenAddress, // address of original token
        uint64[] calldata _unlockTimes, // times when we can unlock original tokens
        uint8[] calldata _ratios, // ratios for the time how much we take
        uint256 _finishTime // after finish time we can transfer tokens
    )
```
### getActivationResult
```solidity
getActivationResult(uint _amountToActivate)
public
view
returns(uint TotalTokens, uint CreditableAmount, uint64[] memory unlockTimes, uint256[] memory unlockAmounts)
```
### ActivateSynthetic
```solidity
// try to take original tokens if time is up or create new locked pools
ActivateSynthetic(uint _amountToActivate) 
//and
ActivateSynthetic() // _amountToActivate = balance of the tokens that the sender has
```

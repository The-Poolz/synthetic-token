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

### Contract Creation

When we create a synthetic token, we need to stick to the settings of the original token.

- Decimal numbers must be the same as the original token
- If the capitalization of the synthetic token is greater than the original token, we will not be able to block the original tokens
- Synthetic token contract can't work without Locked-Deal contract

```solidity
constructor(
        string memory _name, // token name
        string memory _symbol, // token symbol
        uint _cap, // set the capitalization of synthetic tokens
        uint8 _decimals, // token decimals
        address _owner, // who will take synthetic tokens
        address _lockedDealAddress, // can't be zero address
        address _whitelistAddress
    )
```

### Transfer the original tokens to the envelope token contract
Using **SetLockingDetails** function allows us to transfer one-time original tokens to a contract of synthetic tokens.

```solidity
// Can only use the owner address or Governer contract.
SetLockingDetails(
        address _tokenAddress, // address of original token
        uint64[] calldata _unlockTimes, // times when we can unlock original tokens
        uint8[] calldata _ratios, // ratios for the time how much we take
        uint256 _finishTime // after finish time we can transfer tokens
    )
```

### Get information about locking
getActivationResult is view function that returns main information about locking tokens. 
* Total tokens 
* Creditable amount
* Unlock times
* Unlock amounts
```solidity
getActivationResult(uint _amountToActivate)
public
view
returns(uint TotalTokens, uint CreditableAmount, uint64[] memory unlockTimes, uint256[] memory unlockAmounts)
```

### Take original tokens
Each user that have synthetic tokens can “Open” the Envelope to receive the original token. User can open the Envelopes only after the expiration of the agreement by using Locked-Deal contract.
```solidity
// try to take original tokens if time is up or create new locked pools
ActivateSynthetic(uint _amountToActivate)
//or
ActivateSynthetic() // _amountToActivate = balance of the tokens that the sender has
```
## License
The-Poolz Contracts is released under the MIT License.

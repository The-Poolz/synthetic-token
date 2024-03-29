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

Testnet tx (without a whitelist): [link](https://testnet.bscscan.com/tx/0x7a6c8e3a116525bab39eecd17f2c2992aed937fb386de5d91c1750278dce4085)
<br>
Testnet tx (with a whitelist): [link](https://testnet.bscscan.com/tx/0xc90fc3988eeac64b6cfc8d913f85dd750c329677ad056a9423c5fb90a7b96663)

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

Testnet tx: [link](https://testnet.bscscan.com/tx/0x072c7f97baf0ecbd802878ffdbfd810f4e698ed5c49c66d2d3f389bfe9c38bf1)

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

Testnet tx (without a creating new pool): [link](https://testnet.bscscan.com/tx/0x461fbb318fd0a2a39d5afa3fdecee4b1b0d97930c958c4ae96afb2476eea24e6)
<br>
Testnet tx (with a creating new pool): [link](https://testnet.bscscan.com/tx/0x302a813f8ed18ceb15afb0ab4e7487d85a3f2d1dfebddad4552fff992b3e7e71)

## License
The-Poolz Contracts is released under the MIT License.

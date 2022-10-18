const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");
const { assert } = require('chai');
const BigNumber = require("bignumber.js")
BigNumber.config({ EXPONENTIAL_AT: 1e+9 })
const constants = require('@openzeppelin/test-helpers/src/constants.js')

contract("Testing Synthetic Token", accounts => {
    let token, originalToken, firstAddress = accounts[0]
    const synthTokenName = "REAL Synthetic"
    const tokenSymbol = "~REAL Poolz"
    const decimals = '18'
    const lockedDealAddress = accounts[9]
    const cap = new BigNumber(10000)
    let timestamp
    const finishTime = parseInt(new Date().getTime() / 1000) + 60 * 60

    before(async () => {
        originalToken = await TestToken.new('OrgToken', 'ORGT');
        const now = new Date()
        timestamp = (now.setHours(now.getHours() + 1) / 1000).toFixed()
    })

    it('should deploy token', async () => {
        token = await Token.new(synthTokenName, tokenSymbol, cap.toString(), decimals, firstAddress, lockedDealAddress, constants.ZERO_ADDRESS, { from: firstAddress })
        const name = await token.name()
        const symbol = await token.symbol()
        const firstBalance = await token.balanceOf(firstAddress)
        const tokenDecimals = await token.decimals()
        assert.equal(synthTokenName, name)
        assert.equal(tokenSymbol, symbol)
        assert.equal(tokenDecimals.toString(), decimals)
        assert.equal(firstBalance.toString(), cap.multipliedBy(10 ** 18).toString())
    })

    it('should set locking details', async () => {
        await originalToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: firstAddress })
        const tx = await token.SetLockingDetails(originalToken.address, timestamp, timestamp, finishTime.toString(), { from: firstAddress })
        const originalAddress = tx.logs[3].args.TokenAddress
        const totalAmount = tx.logs[3].args.Amount
        const tokenCap = await token.cap()
        assert.equal(originalToken.address, originalAddress)
        assert.equal(totalAmount.toString(), tokenCap.toString())
    })

    it('verifying locking details', async () => {
        const orgToken = await token.OriginalTokenAddress()
        const finish = await token.EndTime()
        const details = await token.LockDetails()
        assert.equal(orgToken, originalToken.address)
        assert.equal(finishTime.toString(), finish.toString())
        assert.equal(details.startTime.toString(), timestamp.toString())
        assert.equal(details.finishTime.toString(), timestamp.toString())
    })

    it('testing activate synthetic with zero amount', async () => {
        const event = await token.ActivateSynthetic(0)
        assert.equal(event.logs[3].args.Owner, firstAddress)
        assert.equal(event.logs[3].args.Amount, 0)
    })
})
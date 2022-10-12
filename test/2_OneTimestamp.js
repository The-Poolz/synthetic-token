const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");
const { assert } = require('chai');
const BigNumber = require("bignumber.js");
const truffleAssertions = require('truffle-assertions');
BigNumber.config({ EXPONENTIAL_AT: 1e+9 })

contract("Testing Synthetic Token with one timestamp", accounts => {
    let token, originalToken, firstAddress = accounts[0]
    const synthTokenName = "REAL Synthetic"
    const tokenSymbol = "~REAL Poolz"
    const decimals = '18'
    const lockedDealAddress = accounts[9]
    const zeroAddress = '0x0000000000000000000000000000000000000000'
    const finishTime = parseInt(new Date().getTime() / 1000) + 60 * 60
    const cap = new BigNumber(10000)
    const timestamp = []
    const ratio = [1]

    before(async () => {
        originalToken = await TestToken.new('OrgToken', 'ORGT');
        token = await Token.new(synthTokenName, tokenSymbol, cap.toString(), decimals, firstAddress, lockedDealAddress, zeroAddress, { from: firstAddress })
        const now = new Date()
        timestamp.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        await originalToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: firstAddress })
        await token.SetLockingDetails(originalToken.address, timestamp, timestamp, ratio, finishTime.toString(), { from: firstAddress })
    })

    it('get activation result with one timestamp', async () => {
        const balance = await token.balanceOf(firstAddress)
        const result = await token.getActivationResult(balance)
        assert.equal(result[0].toString(), balance, 'check total tokens')
        assert.equal(result[1].toString(), 0, 'check creditable amount')
        assert.equal(result[2][0].toString(), timestamp.toString(), 'check start times')
        assert.equal(result[3][0].toString(), timestamp.toString(), 'check finish times')
        assert.equal(result[4].toString(), balance, 'check balance result')
    })

    it('testing get activation in the past time', async () => {
        const secondAddress = accounts[1]
        const testToken = await TestToken.new('TEST', 'TEST', { from: secondAddress });
        const token = await Token.new(synthTokenName, tokenSymbol, cap.toString(), decimals, secondAddress, lockedDealAddress, zeroAddress, { from: secondAddress })
        await testToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: secondAddress })
        const now = new Date()
        const pastTimestamp = []
        pastTimestamp.push((now.setHours(now.getHours() - 1) / 1000).toFixed())
        await token.SetLockingDetails(testToken.address, pastTimestamp, pastTimestamp, [1], finishTime.toString(), { from: secondAddress })
        const balance = await token.balanceOf(secondAddress)
        const result = await token.getActivationResult(balance)
        assert.equal(result[0].toString(), balance, 'check total tokens')
        assert.equal(result[1].toString(), balance, 'check creditable amount')
        assert.equal(result[2].toString(), 0, 'check unlock time')
        assert.equal(result[3][0].toString(), 0, 'check unlock amount')
    })

    it('testing get activation with zero amount', async () => {
        const result = await token.getActivationResult(0)
        assert.equal(result[0].toString(), 0, 'check total tokens')
        assert.equal(result[1].toString(), 0, 'check creditable amount')
        assert.equal(result[2][0].toString(), timestamp.toString(), 'check unlock times')
        assert.equal(result[3][0].toString(), timestamp.toString(), 'check unlock times')
        assert.equal(result[4].toString(), 0, 'check unlock amount')
    })

    it('testing activate synthetic with zero amount', async () => {
        const event = await token.ActivateSynthetic(0)
        assert.equal(event.logs[3].args.Owner, firstAddress)
        assert.equal(event.logs[3].args.Amount, 0)
    })
})
const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");
const { assert } = require('chai');
const BigNumber = require("bignumber.js")
BigNumber.config({ EXPONENTIAL_AT: 1e+9 })

contract("Testing Synthetic Token with one timestamp", accounts => {
    let token, originalToken, firstAddress = accounts[0]
    const cap = new BigNumber(10000)
    const timestamp = []
    const ratio = [1]

    before(async () => {
        originalToken = await TestToken.new('OrgToken', 'ORGT');
        token = await Token.new("REAL Synthetic", "~REAL Poolz", cap.toString(), '18', firstAddress, { from: firstAddress })
        const now = new Date()
        timestamp.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
    })

    it('get activation result with one timestamp', async () => {
        await originalToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: firstAddress })
        await originalToken.allowance(firstAddress, token.address)
        await token.SetLockingDetails(originalToken.address, timestamp, ratio, { from: firstAddress })
        const balance = await token.balanceOf(firstAddress)
        const result = await token.getActivationResult(balance)
        assert.equal(result[0].toString(), balance, 'check total tokens')
        assert.equal(result[1].toString(), 0, 'check creditable amount')
        assert.equal(result[2][0].toString(), timestamp.toString(), 'check unlock times')
        assert.equal(result[3][0].toString(), balance, 'check unlock amount')
    })

    it('using get activation in the future', async () => {
        const secondAddress = accounts[1]
        const testToken = await TestToken.new('TEST', 'TEST', { from: secondAddress });
        const token = await Token.new('Token', 'SYMB', cap.toString(), '18', secondAddress, { from: secondAddress })
        await testToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: secondAddress })
        await testToken.allowance(secondAddress, token.address, {from: secondAddress})
        const now = new Date()
        const pastTimestamp = []
        pastTimestamp.push((now.setHours(now.getHours() - 12) / 1000).toFixed())
        await token.SetLockingDetails(testToken.address, pastTimestamp, [1], { from: secondAddress })
        const balance = await token.balanceOf(secondAddress)
        const result = await token.getActivationResult(balance)
        assert.equal(result[0].toString(), balance, 'check total tokens')
        assert.equal(result[1].toString(), balance, 'check creditable amount')
        assert.equal(result[2].toString(), 0, 'check unlock time')
        assert.equal(result[3][0].toString(), 0, 'check unlock amount')
    })

    it('using get activation with zero amount', async () => {
        const result = await token.getActivationResult(0)
        assert.equal(result[0].toString(), 0, 'check total tokens')
        assert.equal(result[1].toString(), 0, 'check creditable amount')
        assert.equal(result[2][0].toString(), timestamp.toString(), 'check unlock times')
        assert.equal(result[3].toString(), 0, 'check unlock amount')
    })

    // it('activate synthetic', async () => {
    //     //console.log((await token.OriginalTokenAddress()))
    //     await token.SetLockedDealAddress(accounts[1])
    //     const balance = await token.balanceOf(firstAddress)
    //     await token.ActivateSynthetic(balance)
    // })
})
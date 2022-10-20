const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");
const { assert } = require('chai');
const BigNumber = require("bignumber.js");
BigNumber.config({ EXPONENTIAL_AT: 1e+9 })
const constants = require('@openzeppelin/test-helpers/src/constants.js')

contract("Testing getActivationResult", accounts => {
    let token, originalToken, firstAddress = accounts[0]
    const synthTokenName = "REAL Synthetic"
    const tokenSymbol = "~REAL Poolz"
    const decimals = '18'
    const lockedDealAddress = accounts[9]
    const finishTime = parseInt(new Date().getTime() / 1000) + 60 * 60
    const cap = new BigNumber(10000)
    let timestamps = []
    const ratios = [1, 1, 1]

    before(async () => {
        originalToken = await TestToken.new('OrgToken', 'ORGT');
        token = await Token.new(synthTokenName, tokenSymbol, cap.toString(), decimals, firstAddress, lockedDealAddress, constants.ZERO_ADDRESS, { from: firstAddress })
        const now = new Date()
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        await originalToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: firstAddress })
        await token.SetLockingDetails(originalToken.address, timestamps, timestamps, ratios, finishTime.toString(), { from: firstAddress })
    })

    it('get activation result', async () => {
        const balance = await token.balanceOf(firstAddress)
        const result = await token.getActivationResult(balance)
        assert.equal(result[0].toString(), 0, 'check creditable amount')
        assert.equal(result[1][0].toString(), timestamps[0].toString(), 'check unlock times')
        assert.equal(result[2][0].toString(), balance / timestamps.length, 'check unlock amount')
    })

    it('testing get activation when the blocking amount exceeds the activation amount', async ()=> {
        const balance = BigNumber.sum((new BigNumber(1000).multipliedBy(10 ** 18)).toString(), -1)
        const result = await token.getActivationResult(balance)
        assert.equal(result[0].toString(), 0, 'check creditable amount')
        assert.equal(result[1][0].toString(), timestamps[0].toString(), 'check unlock times')
        assert.equal(result[2][0].toString(), balance / timestamps.length, 'check unlock amount')
    })

    it('testing get activation in the past time', async () => {
        const secondAddress = accounts[1]
        const testToken = await TestToken.new('TEST', 'TEST', { from: secondAddress });
        const token = await Token.new(synthTokenName, tokenSymbol, cap.toString(), decimals, secondAddress, lockedDealAddress, constants.ZERO_ADDRESS, { from: secondAddress })
        await testToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: secondAddress })
        const now = new Date()
        const pastTime = []
        pastTime.push((now.setHours(now.getHours() - 1) / 1000).toFixed())
        const ratios = [1]
        await token.SetLockingDetails(testToken.address, pastTime, pastTime, ratios, finishTime.toString(), { from: secondAddress })
        const balance = await token.balanceOf(secondAddress)
        const result = await token.getActivationResult(balance)
        assert.equal(result[0].toString(), balance, 'check creditable amount')
        assert.equal(result[1][0].toString(), 0, 'check unlock time')
        assert.equal(result[2][0].toString(), 0, 'check unlock amount')
    })

    it('testing get activation with zero amount', async () => {
        const result = await token.getActivationResult(0)
        assert.equal(result[0].toString(), 0, 'check creditable amount')
        assert.equal(result[1][0].toString(), timestamps[0].toString(), 'check unlock times')
        assert.equal(result[2][0].toString(), 0, 'check unlock amount')
    })
})
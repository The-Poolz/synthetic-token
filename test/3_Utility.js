const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");
const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const BigNumber = require("bignumber.js")
BigNumber.config({ EXPONENTIAL_AT: 1e+9 })

contract("Testing secondary functions", accounts => {
    let token, originalToken, firstAddress = accounts[0]
    const cap = new BigNumber(10000)
    const timestamps = []
    const ratios = [1, 1, 1]

    before(async () => {
        originalToken = await TestToken.new('OrgToken', 'ORGT');
        const now = new Date()
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        token = await Token.new('REAL Synthetic', '~REAL Poolz', cap.toString(), '18', firstAddress, { from: firstAddress })
        await originalToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: firstAddress })
    })

    it('Unlock Data Already Present', async () => {
        await token.SetLockingDetails(originalToken.address, timestamps, ratios, { from: firstAddress })
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, timestamps, ratios, { from: firstAddress }))
    })

    it('Both arrays should have same length', async ()=> {
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, [1], [1, 1], { from: firstAddress }))
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, [1, 1], [1], { from: firstAddress }))
    })

    it('Array length should be greater than 0', async () => {
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, [], [], { from: firstAddress }))
    })

    it('should set locked deal address', async () => {
        const lockedDealAddress = accounts[1]
        const previousAddress = await token.LockedDealAddress()
        await token.SetLockedDealAddress(lockedDealAddress)
        const newLockedDealAddress = await token.LockedDealAddress()
        assert.equal(newLockedDealAddress, lockedDealAddress, 'check locked deal adress')
        assert.notEqual(previousAddress, newLockedDealAddress)
    })

    it('token minting', async () => {
        const previousTotalSupply = await originalToken.totalSupply()
        await originalToken.FreeTest()
        const currentTotalSupply = await originalToken.totalSupply()
        assert.notEqual(previousTotalSupply, currentTotalSupply)
        assert.equal(currentTotalSupply, previousTotalSupply * 2)  
    })

    it('Decimal more than 18', async () => {
        await truffleAssert.reverts(Token.new('REAL Synthetic', '~REAL Poolz', cap.toString(), '19', firstAddress, { from: firstAddress }))
    })
})
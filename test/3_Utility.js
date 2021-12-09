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
        await originalToken.allowance(firstAddress, token.address)
        await token.SetLockingDetails(originalToken.address, timestamps, ratios, { from: firstAddress })
    })

    it('should revert transactions', async () => {
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, [], [1], { from: firstAddress }),
            'Both arrays should have same length')
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, [], [], { from: firstAddress }),
            'Array length should be greater than 0')
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, timestamps, ratios, { from: firstAddress }),
            'Unlock Data Already Present')
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
})
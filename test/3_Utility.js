const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");
const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const BigNumber = require("bignumber.js")
BigNumber.config({ EXPONENTIAL_AT: 1e+9 })

contract("Testing secondary functions", accounts => {
    let token, originalToken, firstAddress = accounts[0]
    const synthTokenName = "REAL Synthetic", tokenSymbol = "~REAL Poolz", decimals = '18'
    const lockedDealAddress = accounts[9]
    const zeroAddress = '0x0000000000000000000000000000000000000000'
    const cap = new BigNumber(10000)
    const timestamps = []
    const ratios = [1, 1, 1]
    const finishTime = parseInt(new Date().getTime() / 1000) + 60 * 60

    before(async () => {
        originalToken = await TestToken.new('OrgToken', 'ORGT');
        const now = new Date()
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        token = await Token.new(synthTokenName, tokenSymbol, cap.toString(), decimals, firstAddress, lockedDealAddress, zeroAddress, { from: firstAddress })
        await originalToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: firstAddress })
    })
    it('should revert arrays not the same length', async () => {
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, [1], [1, 1], finishTime.toString(), { from: firstAddress }), 'Both arrays should have same length')
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, [1, 1], [1], finishTime.toString(), { from: firstAddress }), 'Both arrays should have same length')
    })

    it('should revert empty array', async () => {
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, [], [], finishTime.toString(), { from: firstAddress }), 'Array length should be greater than 0')
    })

    it('should revert second call set locking details', async () => {
        await token.SetLockingDetails(originalToken.address, timestamps, ratios, finishTime.toString(), { from: firstAddress })
        await truffleAssert.reverts(token.SetLockingDetails(originalToken.address, timestamps, ratios, finishTime.toString(), { from: firstAddress }), 'Unlock Data status error')
    })

    // it('should set locked deal address', async () => {
    //     const lockedDealAddress = accounts[1]
    //     const previousAddress = await token.LockedDealAddress()
    //     await token.SetLockedDealAddress(lockedDealAddress)
    //     const newLockedDealAddress = await token.LockedDealAddress()
    //     assert.equal(newLockedDealAddress, lockedDealAddress, 'check locked deal address')
    //     assert.notEqual(previousAddress, newLockedDealAddress)
    // })

    it('token minting', async () => {
        const previousTotalSupply = await originalToken.totalSupply()
        await originalToken.FreeTest()
        const currentTotalSupply = await originalToken.totalSupply()
        assert.notEqual(previousTotalSupply, currentTotalSupply)
        assert.equal(currentTotalSupply, previousTotalSupply * 2)
    })

    it('Decimal more than 18', async () => {
        const decimals = '19'
        await truffleAssert.reverts(Token.new(synthTokenName, tokenSymbol, cap.toString(), decimals, firstAddress, lockedDealAddress, zeroAddress, { from: firstAddress }), 'Decimal more than 18')
    })

    it('Unlock Data Already Present', async () => {
        const forthAddress = accounts[3]
        const token = await Token.new('Token', 'SYMB', cap.toString(), decimals, forthAddress, lockedDealAddress, zeroAddress, { from: forthAddress })
        const balance = await token.balanceOf(forthAddress)
        await truffleAssert.reverts(token.getActivationResult(balance), 'Unlock Data status error')
    })

    it('Original Token not Ready', async () => {
        const thirdAddress = accounts[2]
        const token = await Token.new('Token', 'SYMB', cap.toString(), decimals, thirdAddress, lockedDealAddress, zeroAddress, { from: thirdAddress })
        await truffleAssert.reverts(token.ActivateSynthetic({ from: thirdAddress }), 'Unlock Data status error')
    })
})
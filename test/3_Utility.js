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
    let timestamp
    const ratios = [1, 1, 1]
    const finishTime = parseInt(new Date().getTime() / 1000) + 60 * 60

    before(async () => {
        originalToken = await TestToken.new('OrgToken', 'ORGT');
        const now = new Date()
        timestamp = (now.setHours(now.getHours() + 1) / 1000).toFixed()
        token = await Token.new(synthTokenName, tokenSymbol, cap.toString(), decimals, firstAddress, lockedDealAddress, zeroAddress, { from: firstAddress })
        await originalToken.approve(token.address, cap.multipliedBy(10 ** 18).toString(), { from: firstAddress })
    })

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

    it('should transfer with zero whitelist address', async () => {
        const secondAddress = accounts[2]
        const amount = '1000'
        await token.transfer(secondAddress, amount, {from: firstAddress})
        let balance = await token.balanceOf(secondAddress)
        assert.equal(balance.toString(), amount, 'check second address balance')
        await token.transfer(firstAddress, amount, {from: secondAddress})
        balance = await token.balanceOf(secondAddress)
        assert.equal(balance.toString(), '0', 'check second address balance')
    })
})
const Token = artifacts.require("POOLZSYNT")
const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const BigNumber = require("big-number")

contract("Testing Synthetic Token", accounts => {
    let token, firstAddress = accounts[0]

    it('should deploy token', async () => {
        const tokenName = "REAL Synthetic"
        const tokenSymbol = "~REAL Poolz"
        const cap = new BigNumber(20000)
        const decimals = 18;
        token = await Token.new(tokenName, tokenSymbol, cap.toString(), decimals ,firstAddress, {from: firstAddress})
        const name = await token.name()
        const symbol = await token.symbol()
        const firstBalance = await token.balanceOf(firstAddress)
        assert.equal(tokenName, name)
        assert.equal(tokenSymbol, symbol)
        assert.equal(firstBalance.toString(), cap.multiply(10 ** 18).toString())
    })
})

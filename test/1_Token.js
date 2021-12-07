const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");
const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const BigNumber = require("big-number")

contract("Testing Synthetic Token", accounts => {
    let token, originalToken, firstAddress = accounts[0]
    const cap = new BigNumber(10000)
    const timestamps = []
    const ratios = [1,1,1]
    
    before(async () => {
        originalToken = await TestToken.new('OrgToken', 'ORGT');
        const now = new Date()
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
        timestamps.push((now.setHours(now.getHours() + 1) / 1000).toFixed())
    })

    it('should deploy token', async () => {
        const tokenName = "REAL Synthetic"
        const tokenSymbol = "~REAL Poolz"
        const _decimals = '18';
        token = await Token.new(tokenName, tokenSymbol, cap.toString(), _decimals ,firstAddress, {from: firstAddress})
        const name = await token.name()
        const symbol = await token.symbol()
        const firstBalance = await token.balanceOf(firstAddress)
        const decimals = await token.decimals()
        const capp = await token.cap()
        assert.equal(tokenName, name)
        assert.equal(tokenSymbol, symbol)
        assert.equal(decimals.toString(), _decimals)
        assert.equal(firstBalance.toString(), cap.multiply(10 ** 18).toString())
    })

    it('should set locking details', async () => {
        await originalToken.approve(token.address, cap.toString(), {from: firstAddress})
        const approval = await originalToken.allowance(firstAddress, token.address)
        const balance = await originalToken.balanceOf(firstAddress)
        const tx = await token.SetLockingDetails(originalToken.address, timestamps, ratios, {from: firstAddress})
        const originalAddress = tx.logs[3].args.TokenAddress
        const totalAmount = tx.logs[3].args.Amount
        const totalUnlocks = tx.logs[3].args.TotalUnlocks
        const tokenCap = await token.cap()
        assert.equal(originalToken.address, originalAddress)
        assert.equal(totalAmount.toString(), tokenCap.toString())
        assert.equal(totalUnlocks, timestamps.length)
    })

    it('verifying locking details', async () => {
        const totalRatios = ratios.reduce((a, b) => a + b, 0)
        const orgToken = await token.OriginalTokenAddress()
        const totalUnlocks = await token.totalUnlocks()
        const ratioTotal = await token.totalOfRatios()
        assert.equal(orgToken, originalToken.address)
        assert.equal(totalUnlocks, timestamps.length)
        assert.equal(ratioTotal, totalRatios)
        for(let i=0 ; i<totalUnlocks ; i++){
            const details = await token.LockDetails(i)
            assert.equal(details.unlockTime.toString(), timestamps[i].toString())
            assert.equal(details.ratio.toString(), ratios[i].toString())
        }
    })

    it('get activation result', async () => {
        const balance = await token.balanceOf(firstAddress)
        const result = await token.getActivationResult(balance)
        const totalOfRatios = parseInt(await token.totalOfRatios())
        
        assert.equal(result[0].toString(), balance)
        assert.equal(result[1], 0)
        assert.equal(result[2].toString(), timestamps.toString())
        assert.equal(result[3][0], balance/totalOfRatios)
        assert.equal(result[3][1], balance/totalOfRatios)
        assert.equal(result[3][2], balance/totalOfRatios + 1)
    })
})
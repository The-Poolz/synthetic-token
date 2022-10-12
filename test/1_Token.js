const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");
const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const BigNumber = require("bignumber.js")
BigNumber.config({ EXPONENTIAL_AT: 1e+9 })

contract("Testing Synthetic Token", accounts => {
    let token, originalToken, firstAddress = accounts[0]
    const synthTokenName = "REAL Synthetic"
    const tokenSymbol = "~REAL Poolz"
    const decimals = '18'
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
    })

    it('should deploy token', async () => {
        token = await Token.new(synthTokenName, tokenSymbol, cap.toString(), decimals, firstAddress, lockedDealAddress, zeroAddress, { from: firstAddress })
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
        const tx = await token.SetLockingDetails(originalToken.address, timestamps, timestamps, ratios, finishTime.toString(), { from: firstAddress })
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
        const finish = await token.FinishTime()
        assert.equal(orgToken, originalToken.address)
        assert.equal(totalUnlocks, timestamps.length)
        assert.equal(ratioTotal, totalRatios)
        assert.equal(finishTime.toString(), finish.toString())
        for (let i = 0; i < totalUnlocks; i++) {
            const details = await token.LockDetails(i)
            assert.equal(details.startTime.toString(), timestamps[i].toString())
            assert.equal(details.finishTime.toString(), timestamps[i].toString())
            assert.equal(details.ratio.toString(), ratios[i].toString())
        }
    })

    it('get activation result', async () => {
        const balance = await token.balanceOf(firstAddress)
        const result = await token.getActivationResult(balance)
        const totalOfRatios = parseInt(await token.totalOfRatios())
        assert.equal(result[0].toString(), balance, 'check total tokens')
        assert.equal(result[1], 0, 'check creditable amount')
        assert.equal(result[2].toString(), timestamps.toString(), 'check unlock times')
        assert.equal(result[3].toString(), timestamps.toString(), 'check unlock times')
        assert.equal(result[4][0], balance / totalOfRatios, 'check first unlock amount')
        assert.equal(result[4][1], balance / totalOfRatios, 'check second unlock amount')
        assert.equal(result[4][2], balance / totalOfRatios + 1, 'check third unlock amount')
    })

    it('testing get activation when tokens less than time stamps', async () => {
        const result = await token.getActivationResult(2)
        assert.equal(result[0].toString(), 2, 'check total tokens')
        assert.equal(result[1], 2, 'check creditable amount')
        assert.equal(result[2].toString(), timestamps, 'check unlock times')
        assert.equal(result[3].toString(), timestamps, 'check unlock times')
        assert.equal(result[4][0], 0, 'check first unlock amount')
        assert.equal(result[4][1], 0, 'check second unlock amount')
        assert.equal(result[4][2], 0, 'check third unlock amount')
    })

    it('testing get activation when the blocking amount exceeds the activation amount', async ()=> {
        const balance = BigNumber.sum((new BigNumber(1000).multipliedBy(10 ** 18)).toString(), -1)
        const result = await token.getActivationResult(balance)
        assert.equal(result[0].toString(), balance, 'check total tokens')
        assert.equal(result[1].toString(), 0, 'check creditable amount')
        assert.equal(result[2].toString(), timestamps.toString(), 'check unlock times')
        assert.equal(result[3].toString(), timestamps.toString(), 'check unlock times')
        assert.equal(result[4][0].toString(), balance.dividedBy(3).toString(), 'check first unlock amount')
        assert.equal(result[4][1].toString(), balance.dividedBy(3).toString(), 'check second unlock amount')
        assert.equal(result[4][2].toString(), balance.dividedBy(3).toString(), 'check third unlock amount')
    })
})
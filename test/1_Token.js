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

    it('should activate becon for solana address', async () => {
        const solanaAddress = 'GPkK1KFzjKhcbwyVdvZfX5taTiBAV2CF6ofCqXNLqUd'
        const enodedAddress = web3.eth.abi.encodeParameter('string', solanaAddress)
        const tx = await token.ActivateBeacon(enodedAddress)
        const eventAddress = tx.logs[1].args.Address
        const decoded = web3.eth.abi.decodeParameter('string', eventAddress)
        assert.equal(decoded, solanaAddress)
    })

    it('should activate becon for bitcoin address', async () => {
        const bitcoinAddress = 'bc1qkajs547st3xup85uqm675ywckf2wcks76x6zzc'
        const enodedAddress = web3.eth.abi.encodeParameter('string', bitcoinAddress)
        const tx = await token.ActivateBeacon(enodedAddress)
        const eventAddress = tx.logs[1].args.Address
        const decoded = web3.eth.abi.decodeParameter('string', eventAddress)
        assert.equal(decoded, bitcoinAddress)
    })

})

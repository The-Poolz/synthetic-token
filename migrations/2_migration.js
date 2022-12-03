const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");
const constants = require('@openzeppelin/test-helpers/src/constants.js')

module.exports = function(deployer) {
    deployer.deploy(Token, "TestEnvelop", "TENV", "18", '18', "0x6063fBa0fBd645d648C129854Cce45A70dd89691", "0x7AA11C85fE1c5089595519CA50a15B25d228DA4b", constants.ZERO_ADDRESS)
    // deployer.deploy(TestToken, 'OrgToken', 'ORGT')
}
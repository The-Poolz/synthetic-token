const Token = artifacts.require("POOLZSYNT")
const TestToken = artifacts.require("OriginalToken");

module.exports = function(deployer) {
    deployer.deploy(Token, "TestEnvelop", "TENV", "10000", '18', "0x5f14560149dA11b499C1569f03a1d6C34a0a6c3C")
    deployer.deploy(TestToken, 'OrgToken', 'ORGT')
}
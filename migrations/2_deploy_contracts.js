const TestInvestment = artifacts.require('TestInvestment.sol')
module.exports = async deployer => {
  deployer.deploy(TestInvestment);
}

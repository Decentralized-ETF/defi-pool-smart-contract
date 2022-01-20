const Investment = artifacts.require('Investment.sol')
module.exports = async deployer => {
  deployer.deploy(Investment);
}

const TestInvestment = artifacts.require('TestInvestment.sol')
module.exports = async deployer => {
  const poolTokens = [
    '0x326C977E6efc84E512bB9C30f76E30c160eD06FB', //LINK
    '0x326C977E6efc84E512bB9C30f76E30c160eD06FB', //TST
    '0x326C977E6efc84E512bB9C30f76E30c160eD06FB' //DERC20
  ];
  const poolTokenPercentages = [10, 25, 65];
  const swapRouterContractAddress = '0xE592427A0AEce92De3Edee1F18E0157C05861564';
  const wMaticTokenAddress = '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889';
  deployer.deploy(TestInvestment, swapRouterContractAddress,wMaticTokenAddress,
    poolTokens, poolTokenPercentages);
}

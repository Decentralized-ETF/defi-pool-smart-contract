const TestInvestment = artifacts.require('TestInvestment.sol')
module.exports = async deployer => {
  const poolTokens = [
    '0x326C977E6efc84E512bB9C30f76E30c160eD06FB', //LINK
    '0x2d7882beDcbfDDce29Ba99965dd3cdF7fcB10A1e', //TST
    '0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1' //DERC20
  ];
  const poolTokenPercentages = [10,25,65];

  deployer.deploy(TestInvestment,poolTokens,poolTokenPercentages);
}

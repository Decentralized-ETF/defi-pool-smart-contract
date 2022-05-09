// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  const signers = await ethers.getSigners();
  // const signer = signers[0];
  const quoterAddress = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6";
  // mumbai
  // const wMaticAddress = '0x9c3c9283d3e44854697cd22d3faa240cfb032889';
  // mainnet
  const entryAssetAddress = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"; //USDT
  // const entryAssetAddress = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270"; //WMATIC
  // const entryAssetAddress = "0xae740d42e4ff0c5086b2b5b5d149eb2f9e1a754f"; //WETH
  // mumbai
  // const swapRouterAddress = '0xe592427a0aece92de3edee1f18e0157c05861564' (YES, ITS CORRECT for mumbai as well)
  // mainnet
  const swapRouterAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
  // wETH, LINK, DAI
  // const poolTokens = ['0xa6fa4fb5f76172d178d61b04b0ecd319c5d1c0aa', '0x326C977E6efc84E512bB9C30f76E30c160eD06FB', '0x001b3b4d0f3714ca98ba10f6042daebf0b1b7b6f'];
  // AAVE, CRV, wBTC, UNI, DAI
  const poolTokens = [
    // "0xd6df932a45c0f255f85145f286ea0b292b21c90b", // AAVE
    // "0x172370d5cd63279efa6d502dab29171933a610af", // CRV
    // "0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6", // WBTC
    "0xb33eaad8d922b1083446dc23f610c2567fb5180f", // UNI
    "0xbD7A5Cf51d22930B8B3Df6d834F9BCEf90EE7c4f", // ENS
    "0xd72357dAcA2cF11A5F155b9FF7880E595A3F5792", // STORJ
    "0xda537104d6a5edd53c6fbba9a898708e465260b6", // YFI
    "0x5559Edb74751A0edE9DeA4DC23aeE72cCA6bE3D5", // ZRX
    // "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063", // DAI
    // "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619", // WETH
  ];
  const poolTokenPercentage = [30, 25, 25, 10, 10];
  // We get the contract to deploy
  const Pool = await ethers.getContractFactory("Pool");
  const pool = await Pool.deploy(
    swapRouterAddress,
    quoterAddress,
    entryAssetAddress,
    poolTokens,
    poolTokenPercentage,
    { gasLimit: 6000000 }
  );
  await pool.deployed();
  console.log("Deployed at: ", pool.address);
  // console.log("Init balances");
  // const data = await pool.getPoolData();
  // console.log("Pool data: ", data);
  /*
  const result = await signer.sendTransaction({
    to: pool.address,
    value: ethers.utils.parseEther("0.01"),
    gasLimit: 6000000,
  });
  console.log("res:", (await result.wait()).transactionHash);
 */
  // console.log('NEW data: ', await pool.getPoolData())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

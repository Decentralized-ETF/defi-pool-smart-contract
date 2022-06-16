import { ethers } from "hardhat";

async function main() {
  const swapRouterAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
  const UniSwapV3Exchange = await ethers.getContractFactory(
    "UniSwapV3Exchange"
  );
  const uniSwapV3Exchange = await UniSwapV3Exchange.deploy(
    swapRouterAddress,
    3000,
    { gasLimit: 6000000 }
  );
  await uniSwapV3Exchange.deployed();
  console.log("Deployed at: ", uniSwapV3Exchange.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
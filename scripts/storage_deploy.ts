import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const UniSwapV3Exchange = await ethers.getContractFactory(
    "UniSwapV3Exchange"
  );
  const uniSwapV3Exchange = await UniSwapV3Exchange.deploy(
    "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    3000
  );
  console.log("UniSwapV2Exchange contract address:", uniSwapV3Exchange.address);
  const UniSwapV2Exchange = await ethers.getContractFactory(
    "UniSwapV2Exchange"
  );
  const uniSwapV2Exchange = await UniSwapV2Exchange.deploy(
    "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
  );

  await uniSwapV2Exchange.deployed();
  console.log("UniSwapV2Exchange contract address:", uniSwapV2Exchange.address);

  const poolTokens = [
    "0xd6df932a45c0f255f85145f286ea0b292b21c90b",
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
  ];
  const poolTokenDistributionsInBP = [50, 50];
  const feeRecipient = deployer.address;

  console.log("Deploying contracts with the account:", deployer.address);

  const Storage = await ethers.getContractFactory("Storage");
  const storage = await Storage.deploy(
    feeRecipient,
    poolTokens,
    poolTokenDistributionsInBP
  );

  await storage.deployed();
  console.log("Storage contract address:", storage.address);

  const storageContractAddress = storage.address;

  const KedrPoolV01 = await ethers.getContractFactory("KedrPoolV01");

  const kedrPoolV01 = await upgrades.deployProxy(
    KedrPoolV01,
    [storageContractAddress, "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270"],
    {
      initializer: "initialize",
    }
  );

  await kedrPoolV01.deployed();
  console.log("Pool contract address:", kedrPoolV01.address);

  await storage.upgradeOwner(kedrPoolV01.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

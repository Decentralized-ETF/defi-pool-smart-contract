import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
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

  const KedrPool = await ethers.getContractFactory("KedrPool");

  const kedrPool = await upgrades.deployProxy(KedrPool, [
    storageContractAddress,
    "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
  ]);

  await kedrPool.deployed();
  console.log("Pool contract address:", kedrPool.address);

  await storage.upgradeOwner(kedrPool.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

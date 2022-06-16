import { expect } from "chai";
import { ethers } from "hardhat";

describe("UniSwapV3Exchange", function () {
  it("Should return amountOut", async function () {
    const contractAddress = "0x1c1E3141532B27B7CD2BAF93091eeB917eF6C69d";
    const myContract = await ethers.getContractAt(
      "UniSwapV3Exchange",
      contractAddress
    );

    const latestBlock = await ethers.provider.getBlock("latest");

    const amoutnOut = await myContract.swap(
      "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
      "0xb33eaad8d922b1083446dc23f610c2567fb5180f",
      latestBlock.timestamp,
      100000000000000,
      "0x3B26E340713E0923E4d7d6260D6F59b1265ACdbB"
    );
    console.log(amoutnOut);
    /*
const Greeter = await ethers.getContractFactory("Greeter");
const greeter = await Greeter.deploy("Hello, world!");
await greeter.deployed();

expect(await greeter.greet()).to.equal("Hello, world!");

const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

// wait until the transaction is mined
await setGreetingTx.wait();

expect(await greeter.greet()).to.equal("Hola, mundo!");
*/
  });
});

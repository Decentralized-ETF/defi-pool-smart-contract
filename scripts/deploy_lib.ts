import {Deployer} from "./classes/Deployer";


async function main() {
    const deployer = new Deployer()
    const lib = await deployer.deployKedrLib();
    console.log(`KedrLib deployed at: ${lib.address}`);
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

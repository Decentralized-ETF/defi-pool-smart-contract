import {Deployer} from "./classes/Deployer";


async function main() {
    const deployer = new Deployer()
    await deployer.deployFactory(true);
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

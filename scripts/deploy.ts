import {Deployer} from "./classes/Deployer";


async function main() {
    const deployer = new Deployer()
    await deployer.deployOnChain(true)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
